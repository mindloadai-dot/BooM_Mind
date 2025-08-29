import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mindload/models/pdf_export_models.dart';
import 'package:mindload/models/pdf_audit_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';

class PdfExportService extends ChangeNotifier {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  static PdfExportService get instance => _instance;
  PdfExportService._internal();

  // Services
  final PdfAuditService _auditService = InMemoryPdfAuditService();

  // State
  bool _isExporting = false;
  String? _currentExportId;
  PdfExportProgress? _currentProgress;
  Timer? _rateLimitTimer;
  final Map<String, DateTime> _userExportTimes = {};

  // Getters
  bool get isExporting => _isExporting;
  String? get currentExportId => _currentExportId;
  PdfExportProgress? get currentProgress => _currentProgress;

  // Initialize service
  Future<void> initialize() async {
    debugPrint('✅ PDF Export service initialized');
  }

  // Export study set to PDF
  Future<PdfExportResult> exportToPdf({
    required String uid,
    required String setId,
    required String appVersion,
    required Map<String, int> itemCounts,
    required PdfExportOptions options,
    required Function(PdfExportProgress) onProgress,
    required Function() onCancelled,
    List<dynamic>? studyItems,
  }) async {
    try {
      // Check rate limits
      if (!_checkRateLimit(uid)) {
        return PdfExportResult.failure(
          errorCode: 'RATE_LIMIT_EXCEEDED',
          errorMessage: 'Too many exports. Try again later.',
          duration: Duration.zero,
        );
      }

      // Check if already exporting
      if (_isExporting) {
        return PdfExportResult.failure(
          errorCode: 'ALREADY_EXPORTING',
          errorMessage: 'Another export is already in progress.',
          duration: Duration.zero,
        );
      }

      // Create audit record
      final auditRecord = await _auditService.createAuditRecord(
        uid: uid,
        setId: setId,
        appVersion: appVersion,
        itemCounts: itemCounts,
        style: options.style,
        pageSize: options.pageSize,
      );

      _currentExportId = auditRecord.auditId;
      _isExporting = true;
      _currentProgress = PdfExportProgress(
        currentPage: 0,
        totalPages: 0,
        currentItem: 0,
        totalItems: _calculateTotalItems(itemCounts),
        currentOperation: 'starting',
        percentage: 0.0,
        startedAt: DateTime.now(),
      );

      notifyListeners();

      final startTime = DateTime.now();

      try {
        // Start export in background
        final result = await _performExport(
          options: options,
          auditRecord: auditRecord,
          onProgress: onProgress,
          onCancelled: onCancelled,
          itemCounts: itemCounts,
          studyItems: studyItems,
        );

        final duration = DateTime.now().difference(startTime);

        // Update audit record based on result
        if (result.success) {
          final updatedRecord = auditRecord.markSuccess(
            pages: result.pages!,
            bytes: result.bytes!,
            checksum: result.checksum!,
          );
          await _auditService.updateAuditRecord(updatedRecord);
        } else {
          final updatedRecord = auditRecord.markFailed(
            errorCode: result.errorCode!,
            errorMessage: result.errorMessage!,
          );
          await _auditService.updateAuditRecord(updatedRecord);
        }

        // Update rate limit
        _updateRateLimit(uid);

        return result.copyWith(duration: duration);
      } finally {
        _isExporting = false;
        _currentExportId = null;
        _currentProgress = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ PDF export failed: $e');
      return PdfExportResult.failure(
        errorCode: 'EXPORT_ERROR',
        errorMessage: 'Export failed: ${e.toString()}',
        duration: Duration.zero,
      );
    }
  }

  // Perform the actual export
  Future<PdfExportResult> _performExport({
    required PdfExportOptions options,
    required PdfAuditRecord auditRecord,
    required Function(PdfExportProgress) onProgress,
    required Function() onCancelled,
    required Map<String, int> itemCounts,
    List<dynamic>? studyItems,
  }) async {
    try {
      // Check device storage
      final freeSpaceGB = await _getFreeSpaceGB();
      if (freeSpaceGB < 1) {
        return PdfExportResult.failure(
          errorCode: 'ENOSPC',
          errorMessage: 'Insufficient device storage space.',
          duration: Duration.zero,
        );
      }

      // Create temporary file
      final tempFile = await _createTempFile();
      final tempPath = tempFile.path;

      try {
        // Generate PDF with MindLoad branding using real study data
        final result = await _generatePdfWithBranding(
          options: options,
          tempPath: tempPath,
          onProgress: onProgress,
          onCancelled: onCancelled,
          studyItems: studyItems,
          itemCounts: itemCounts,
        );

        if (result == null) {
          // Export was cancelled
          await _auditService.updateAuditRecord(auditRecord.markCancelled());
          onCancelled();
          return PdfExportResult.failure(
            errorCode: 'CANCELLED',
            errorMessage: 'Export was cancelled by user.',
            duration: Duration.zero,
          );
        }

        // Validate file size and pages
        final fileSize = await tempFile.length();
        if (fileSize > options.effectiveMaxFileSizeBytes) {
          return PdfExportResult.failure(
            errorCode: 'FILE_TOO_LARGE',
            errorMessage: 'Generated PDF exceeds size limit.',
            duration: Duration.zero,
          );
        }

        // Move to final location
        final finalPath = await _moveToFinalLocation(tempPath, options.setId);

        // Calculate checksum
        final checksum = await _calculateChecksum(finalPath);

        return PdfExportResult.success(
          filePath: finalPath,
          pages: result['pages'] as int? ??
              0, // Provide default value for nullable pages
          bytes: fileSize,
          checksum: checksum,
          duration: Duration.zero, // Will be set by caller
        );
      } finally {
        // Clean up temp file if it still exists
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('❌ PDF generation failed: $e');
      return PdfExportResult.failure(
        errorCode: 'GENERATION_ERROR',
        errorMessage: 'PDF generation failed: ${e.toString()}',
        duration: Duration.zero,
      );
    }
  }

  // Generate PDF content (simulated)
  Future<Map<String, dynamic>?> _generatePdf({
    required PdfExportOptions options,
    required String tempPath,
    required Function(PdfExportProgress) onProgress,
    required Function() onCancelled,
  }) async {
    try {
      // Simulate processing time
      const totalItems = 100; // Mock total items
      const totalPages = 50; // Mock total pages

      for (int i = 0; i < totalItems; i++) {
        // Check if cancelled
        if (_currentExportId == null) {
          return null; // Cancelled
        }

        // Update progress
        final progress = PdfExportProgress(
          currentPage: (i * totalPages / totalItems).round(),
          totalPages: totalPages,
          currentItem: i,
          totalItems: totalItems,
          currentOperation: 'processing',
          percentage: i / totalItems,
          startedAt: _currentProgress?.startedAt ?? DateTime.now(),
        );

        _currentProgress = progress;
        onProgress(progress);
        notifyListeners();

        // Simulate processing time
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Write mock PDF content
      final mockPdfContent = _generateMockPdfContent(options);
      final file = File(tempPath);
      await file.writeAsBytes(utf8.encode(mockPdfContent));

      return {
        'pages': totalPages,
      };
    } catch (e) {
      debugPrint('❌ PDF generation error: $e');
      rethrow;
    }
  }

  // Generate mock PDF content for testing
  String _generateMockPdfContent(PdfExportOptions options) {
    final buffer = StringBuffer();
    buffer.writeln('%PDF-1.4');
    buffer.writeln('1 0 obj');
    buffer.writeln('<<');
    buffer.writeln('/Type /Catalog');
    buffer.writeln('/Pages 2 0 R');
    buffer.writeln('>>');
    buffer.writeln('endobj');

    // Add mock content based on options
    if (options.includeFlashcards) {
      buffer.writeln('2 0 obj');
      buffer.writeln('<<');
      buffer.writeln('/Type /Pages');
      buffer.writeln('/Kids [3 0 R]');
      buffer.writeln('/Count 1');
      buffer.writeln('>>');
      buffer.writeln('endobj');
    }

    if (options.includeQuiz) {
      buffer.writeln('3 0 obj');
      buffer.writeln('<<');
      buffer.writeln('/Type /Page');
      buffer.writeln('/Parent 2 0 R');
      buffer.writeln('/MediaBox [0 0 595 842]');
      buffer.writeln('/Contents 4 0 R');
      buffer.writeln('>>');
      buffer.writeln('endobj');
    }

    buffer.writeln('4 0 obj');
    buffer.writeln('<<');
    buffer.writeln('/Length 100');
    buffer.writeln('>>');
    buffer.writeln('stream');
    buffer.writeln('BT');
    buffer.writeln('/F1 12 Tf');
    buffer.writeln('72 720 Td');
    buffer.writeln('(Study Set Export) Tj');
    buffer.writeln('ET');
    buffer.writeln('endstream');
    buffer.writeln('endobj');

    buffer.writeln('xref');
    buffer.writeln('0 5');
    buffer.writeln('0000000000 65535 f');
    buffer.writeln('0000000009 00000 n');
    buffer.writeln('0000000058 00000 n');
    buffer.writeln('0000000117 00000 n');
    buffer.writeln('0000000176 00000 n');
    buffer.writeln('trailer');
    buffer.writeln('<<');
    buffer.writeln('/Size 5');
    buffer.writeln('/Root 1 0 R');
    buffer.writeln('>>');
    buffer.writeln('startxref');
    buffer.writeln('1000');
    buffer.writeln('%%EOF');

    return buffer.toString();
  }

  // Create temporary file
  Future<File> _createTempFile() async {
    final directory = await getTemporaryDirectory();
    final tempPath =
        '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.part.pdf';
    return File(tempPath);
  }

  // Move file to final location
  Future<String> _moveToFinalLocation(String tempPath, String setId) async {
    final directory = await getApplicationDocumentsDirectory();
    final finalPath =
        '${directory.path}/exports/${setId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Ensure exports directory exists
    final exportsDir = Directory('${directory.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }

    // Move file
    final tempFile = File(tempPath);
    await tempFile.rename(finalPath);

    return finalPath;
  }

  // Calculate file checksum
  Future<String> _calculateChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check rate limit
  bool _checkRateLimit(String uid) {
    final now = DateTime.now();
    final lastExport = _userExportTimes[uid];

    if (lastExport == null) return true;

    final timeSinceLastExport = now.difference(lastExport);
    return timeSinceLastExport.inHours >= 1; // Allow 1 export per hour
  }

  // Update rate limit
  void _updateRateLimit(String uid) {
    _userExportTimes[uid] = DateTime.now();
  }

  // Get free space on device
  Future<int> _getFreeSpaceGB() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();

      // For now, return a reasonable default since stat.size might not give free space
      return 10; // Assume 10GB available
    } catch (e) {
      debugPrint('⚠️ Could not determine free space: $e');
      return 10; // Assume 10GB if we can't determine
    }
  }

  // Cancel current export
  void cancelExport() {
    if (_isExporting) {
      _currentExportId = null;
      _isExporting = false;
      _currentProgress = null;
      notifyListeners();
    }
  }

  Future<void> sharePdf(String filePath) async {
    try {
      final result = await Share.shareXFiles([XFile(filePath)],
          text: 'Here is your exported study set.');

      if (result.status == ShareResultStatus.success) {
        debugPrint('✅ PDF shared successfully');
      } else {
        debugPrint('⚠️ PDF share dismissed or failed: ${result.status}');
      }
    } catch (e) {
      debugPrint('❌ Failed to share PDF: $e');
    }
  }

  // Get export history for user
  Future<List<PdfAuditRecord>> getExportHistory(String uid) async {
    return await _auditService.getAuditRecords(uid);
  }

  // Get export statistics for user
  Future<Map<String, dynamic>> getExportStats(String uid) async {
    return await _auditService.getAuditStats(uid);
  }

  // Check if user can export (rate limit check)
  bool canExport(String uid) {
    return _checkRateLimit(uid);
  }

  // Get time until next export allowed
  Duration? getTimeUntilNextExport(String uid) {
    final lastExport = _userExportTimes[uid];
    if (lastExport == null) return null;

    final now = DateTime.now();
    final timeSinceLastExport = now.difference(lastExport);
    final oneHour = const Duration(hours: 1);

    if (timeSinceLastExport >= oneHour) return null;

    return oneHour - timeSinceLastExport;
  }

  // Get current user ID
  String getCurrentUserId() {
    return AuthService.instance.currentUserId ?? 'anonymous';
  }

  // Get app version
  String getAppVersion() {
    // TODO: Get actual app version from package info
    return '1.0.0';
  }

  // Clean up old export files
  Future<int> cleanupOldExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');

      if (!await exportsDir.exists()) return 0;

      final files = await exportsDir.list().toList();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);

          // Delete files older than 30 days
          if (age.inDays > 30) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      debugPrint('🗑️ Cleaned up $deletedCount old export files');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Failed to cleanup old exports: $e');
      return 0;
    }
  }

  // Simplified export method for app-wide use
  Future<PdfExportResult> exportStudySet({
    required String uid,
    required String setId,
    required String setTitle,
    required int flashcardCount,
    required int quizCount,
    required String appVersion,
    PdfExportOptions? customOptions,
  }) async {
    final options = customOptions ??
        PdfExportOptions(
          setId: setId,
          includeFlashcards: flashcardCount > 0,
          includeQuiz: quizCount > 0,
          style: 'standard',
          pageSize: 'Letter',
        );

    final itemCounts = <String, int>{};
    if (options.includeFlashcards) itemCounts['flashcards'] = flashcardCount;
    if (options.includeQuiz) itemCounts['quizzes'] = quizCount;

    return await exportToPdf(
      uid: uid,
      setId: setId,
      appVersion: appVersion,
      itemCounts: itemCounts,
      options: options,
      onProgress: (progress) {
        debugPrint('Export progress: ${progress.percentage}%');
      },
      onCancelled: () {
        debugPrint('Export cancelled');
      },
    );
  }

  // New method to handle the full export and share flow
  Future<void> exportAndShareStudySet({
    required String uid,
    required String setId,
    required String setTitle,
    required int flashcardCount,
    required int quizCount,
    required String appVersion,
    PdfExportOptions? customOptions,
  }) async {
    final result = await exportStudySet(
      uid: uid,
      setId: setId,
      setTitle: setTitle,
      flashcardCount: flashcardCount,
      quizCount: quizCount,
      appVersion: appVersion,
      customOptions: customOptions,
    );

    if (result.success && result.filePath != null) {
      await sharePdf(result.filePath!);
    } else {
      // Optionally, show an error message to the user
      debugPrint(
          'Export failed, so not sharing. Error: ${result.errorMessage}');
    }
  }

  // Legacy export methods for backward compatibility
  static Future<void> exportFlashcardsAsPdf(StudySet studySet) async {
    final service = PdfExportService();
    final options = PdfExportOptions(
      setId: studySet.id,
      includeFlashcards: true,
      includeQuiz: false,
      style: 'standard',
      pageSize: 'Letter',
    );

    final result = await service.exportToPdf(
      uid: AuthService.instance.currentUserId ?? 'anonymous',
      setId: studySet.id,
      appVersion: '1.0.0',
      itemCounts: {'flashcards': studySet.flashcards.length},
      options: options,
      onProgress: (progress) {
        debugPrint('Export progress: ${progress.percentage}%');
      },
      onCancelled: () {
        debugPrint('Export cancelled');
      },
    );

    if (!result.success) {
      throw Exception('Export failed: ${result.errorMessage}');
    }
  }

  static Future<void> exportQuizzesAsPdf(StudySet studySet) async {
    final service = PdfExportService();
    final options = PdfExportOptions(
      setId: studySet.id,
      includeFlashcards: false,
      includeQuiz: true,
      style: 'standard',
      pageSize: 'Letter',
    );

    final result = await service.exportToPdf(
      uid: AuthService.instance.currentUserId ?? 'anonymous',
      setId: studySet.id,
      appVersion: '1.0.0',
      itemCounts: {'quizzes': studySet.quizzes.length},
      options: options,
      onProgress: (progress) {
        debugPrint('Export progress: ${progress.percentage}%');
      },
      onCancelled: () {
        debugPrint('Export cancelled');
      },
    );

    if (!result.success) {
      throw Exception('Export failed: ${result.errorMessage}');
    }
  }

  // MindLoad branding configuration
  static const Map<String, String> _brandingConfig = {
    'logo': 'MindLoad',
    'tagline': 'Transform your learning',
    'website': 'mindload.app',
    'version': '1.0.0',
    'footer': 'Generated by MindLoad - Your AI Learning Companion',
  };

  // Add MindLoad branding to PDF content
  String _addMindLoadBranding(String content, String pageType) {
    final branding = _brandingConfig;
    final timestamp = DateTime.now().toIso8601String();

    return '''
$content

---
${branding['footer']} | ${branding['website']} | Generated on $timestamp
Page: $pageType | MindLoad v${branding['version']}
''';
  }

  // Enhanced PDF generation with MindLoad branding
  Future<Map<String, dynamic>?> _generatePdfWithBranding({
    required PdfExportOptions options,
    required String tempPath,
    required Function(PdfExportProgress) onProgress,
    required Function() onCancelled,
    List<dynamic>? studyItems,
    required Map<String, int> itemCounts,
  }) async {
    try {
      // Create PDF document
      final PdfDocument document = PdfDocument();

      int currentPage = 1;
      int totalItems = 0;

      // Calculate total items from actual data
      if (options.includeFlashcards) {
        totalItems += (itemCounts['flashcards'] ?? 0);
      }
      if (options.includeQuiz) {
        totalItems += (itemCounts['quizzes'] ?? 0);
      }

      // Add MindLoad header page only if branding is enabled
      if (options.includeMindloadBranding) {
        final PdfPage headerPage = document.pages.add();
        final PdfGraphics graphics = headerPage.graphics;

        // Add MindLoad branding header
        _addMindLoadHeader(graphics, options);
        onProgress(
            _createProgress(1, 1, 0, 0, 'Adding MindLoad header...', 10.0));
        currentPage++;
      }

      // Calculate total pages
      final int totalPages =
          (totalItems / 20).ceil() + (options.includeMindloadBranding ? 1 : 0);

      // Process study items
      for (int i = 0; i < totalItems; i++) {
        // Add new page when needed (first page or every 20 items)
        if (i % 20 == 0) {
          final PdfPage page = document.pages.add();
          _addStudyContent(page, i, options, studyItems: studyItems);
          currentPage++;
        }

        // Update progress every 5 items
        if (i % 5 == 0) {
          final progress = _createProgress(currentPage, totalPages, i,
              totalItems, 'Processing study items...', (i / totalItems) * 100);
          onProgress(progress);

          // Check for cancellation
          if (!_isExporting) {
            document.dispose();
            return null;
          }

          // Small delay to prevent UI blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Final progress update
      onProgress(_createProgress(totalPages, totalPages, totalItems, totalItems,
          'Finalizing PDF...', 100.0));

      // Save PDF to file
      final File file = File(tempPath);
      final List<int> bytes = await document.save();
      await file.writeAsBytes(bytes);

      // Clean up
      document.dispose();

      return {
        'pages': totalPages,
        'items': totalItems,
        'bytes': bytes.length,
      };
    } catch (e) {
      debugPrint('❌ PDF generation failed: $e');
      return null;
    }
  }

  // Helper method to calculate total items
  int _calculateTotalItems(Map<String, int> itemCounts) {
    return itemCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Helper methods for PDF generation
  void _addMindLoadHeader(PdfGraphics graphics, PdfExportOptions options) {
    // Add MindLoad title
    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    graphics.drawString('MindLoad Study Set Export', titleFont,
        brush: PdfSolidBrush(PdfColor(33, 33, 33)),
        bounds: Rect.fromLTWH(50, 100, 500, 50));

    // Add export details
    final PdfFont detailFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    graphics.drawString('Set ID: ${options.setId}', detailFont,
        brush: PdfSolidBrush(PdfColor(66, 66, 66)),
        bounds: Rect.fromLTWH(50, 160, 500, 20));

    graphics.drawString(
        'Export Date: ${DateTime.now().toIso8601String()}', detailFont,
        brush: PdfSolidBrush(PdfColor(66, 66, 66)),
        bounds: Rect.fromLTWH(50, 180, 500, 20));

    graphics.drawString(
        'Style: ${options.style} | Page Size: ${options.pageSize}', detailFont,
        brush: PdfSolidBrush(PdfColor(66, 66, 66)),
        bounds: Rect.fromLTWH(50, 200, 500, 20));

    // Add MindLoad branding footer
    graphics.drawString(
        'Generated by MindLoad - Your AI Learning Companion', detailFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(50, 750, 500, 20));
  }

  void _addStudyContent(PdfPage page, int itemIndex, PdfExportOptions options,
      {List<dynamic>? studyItems}) {
    final PdfGraphics graphics = page.graphics;
    final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont headerFont =
        PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final PdfFont questionFont =
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

    // Add page header
    graphics.drawString(
        'Study Set Content - Page ${itemIndex ~/ 20 + 1}', headerFont,
        brush: PdfSolidBrush(PdfColor(33, 33, 33)),
        bounds: Rect.fromLTWH(50, 50, 500, 20));

    double yPosition = 100;
    const double lineHeight = 25;
    const double maxWidth = 500;

    // Add actual study content if available
    if (studyItems != null && studyItems.isNotEmpty) {
      final startIndex = itemIndex;
      final endIndex = (startIndex + 20).clamp(0, studyItems.length);

      for (int i = startIndex; i < endIndex && yPosition < 700; i++) {
        final item = studyItems[i];

        if (item is Map<String, dynamic>) {
          // Handle flashcard format
          if (item.containsKey('question') && item.containsKey('answer')) {
            // Question
            graphics.drawString('Q${i + 1}: ${item['question']}', questionFont,
                brush: PdfSolidBrush(PdfColor(33, 33, 33)),
                bounds: Rect.fromLTWH(50, yPosition, maxWidth, lineHeight));
            yPosition += lineHeight;

            // Answer
            graphics.drawString('A: ${item['answer']}', contentFont,
                brush: PdfSolidBrush(PdfColor(66, 66, 66)),
                bounds:
                    Rect.fromLTWH(70, yPosition, maxWidth - 20, lineHeight));
            yPosition += lineHeight * 1.5;
          }
          // Handle quiz format
          else if (item.containsKey('question') &&
              item.containsKey('options')) {
            // Question
            graphics.drawString('Q${i + 1}: ${item['question']}', questionFont,
                brush: PdfSolidBrush(PdfColor(33, 33, 33)),
                bounds: Rect.fromLTWH(50, yPosition, maxWidth, lineHeight));
            yPosition += lineHeight;

            // Options
            final options = item['options'] as List<dynamic>? ?? [];
            for (int j = 0; j < options.length && yPosition < 700; j++) {
              final isCorrect = item['correctAnswer'] == options[j];
              graphics.drawString(
                  '${String.fromCharCode(65 + j)}) ${options[j]}${isCorrect ? ' ✓' : ''}',
                  contentFont,
                  brush: PdfSolidBrush(
                      isCorrect ? PdfColor(0, 128, 0) : PdfColor(66, 66, 66)),
                  bounds:
                      Rect.fromLTWH(70, yPosition, maxWidth - 20, lineHeight));
              yPosition += lineHeight;
            }
            yPosition += lineHeight * 0.5;
          }
        } else {
          // Handle string content
          graphics.drawString('Item ${i + 1}: ${item.toString()}', contentFont,
              brush: PdfSolidBrush(PdfColor(66, 66, 66)),
              bounds: Rect.fromLTWH(50, yPosition, maxWidth, lineHeight));
          yPosition += lineHeight;
        }
      }
    } else {
      // Fallback message when no content is available
      graphics.drawString('No study content available for export.', contentFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)),
          bounds: Rect.fromLTWH(50, yPosition, maxWidth, lineHeight));
    }

    // Add page footer
    graphics.drawString('Page ${itemIndex ~/ 20 + 1}', contentFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(50, 750, 500, 20));
  }

  PdfExportProgress _createProgress(int currentPage, int totalPages,
      int currentItem, int totalItems, String operation, double percentage) {
    return PdfExportProgress(
      currentPage: currentPage,
      totalPages: totalPages,
      currentItem: currentItem,
      totalItems: totalItems,
      currentOperation: operation,
      percentage: percentage,
      startedAt: _currentProgress?.startedAt ?? DateTime.now(),
    );
  }
}
