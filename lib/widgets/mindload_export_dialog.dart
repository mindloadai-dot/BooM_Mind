import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/pdf_export_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/models/pdf_export_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/widgets/mindload_enforcement_dialog.dart';
import 'package:mindload/screens/paywall_screen.dart';
import 'package:mindload/theme.dart';
import 'package:flutter/foundation.dart';

/// Mindload Export Dialog
/// Demonstrates export limits enforcement
class MindloadExportDialog extends StatefulWidget {
  final StudySet studySet;
  final List<StudySet>? additionalSets; // For batch export (Cortex tier)

  const MindloadExportDialog({
    super.key,
    required this.studySet,
    this.additionalSets,
  });

  @override
  State<MindloadExportDialog> createState() => _MindloadExportDialogState();
}

class _MindloadExportDialogState extends State<MindloadExportDialog> {
  String _selectedExportType = 'flashcards_pdf';
  bool _includeAnswers = true;
  bool _includeMindloadHeader = true;
  bool _isExporting = false;
  final List<StudySet> _selectedSets = [];

  @override
  void initState() {
    super.initState();
    _selectedSets.add(widget.studySet);
    if (widget.additionalSets != null) {
      _selectedSets
          .addAll(widget.additionalSets!.take(2)); // Max 3 total for batch
    }
  }

  Future<void> _exportContent() async {
    final economyService = context.read<MindloadEconomyService>();

    // Check export limits for each set

    // Create export requests
    final requests = _selectedSets
        .map((set) => ExportRequest(
              setId: set.id,
              exportType: _selectedExportType,
              includeMindloadHeader: _includeMindloadHeader,
            ))
        .toList();

    // ENFORCEMENT CHECK - Check if user has enough exports
    for (final request in requests) {
      final enforcement = economyService.canExportContent(request);
      if (!enforcement.canProceed) {
        await _showEnforcementDialog(enforcement);
        return;
      }
    }

    setState(() => _isExporting = true);

    try {
      final List<String> exportPaths = [];

      // Process each export
      for (int i = 0; i < requests.length; i++) {
        final request = requests[i];
        final set = _selectedSets[i];

        // Use export quota
        final quotaUsed = await economyService.useExport(request);
        if (!quotaUsed) {
          throw Exception('Failed to use export quota');
        }

        // Generate PDF
        final pdfPath = await _generatePdf(set, request);
        exportPaths.add(pdfPath);
      }

      // Success
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(exportPaths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _exportContent,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _generatePdf(StudySet studySet, ExportRequest request) async {
    final pdfService = PdfExportService();

    // Determine export options based on request
    final options = PdfExportOptions(
      setId: studySet.id,
      includeFlashcards: request.exportType == 'flashcards_pdf',
      includeQuiz: request.exportType == 'quiz_pdf',
      style: 'standard',
      pageSize: 'Letter',
      includeMindloadBranding:
          request.includeMindloadHeader, // Use the request header option
    );

    // Calculate item counts
    final itemCounts = <String, int>{};
    if (options.includeFlashcards) {
      itemCounts['flashcards'] = studySet.flashcards.length;
    }
    if (options.includeQuiz) {
      itemCounts['quiz'] = studySet.quizQuestions.length;
    }

    // Use the new PDF export system with MindLoad branding
    final result = await pdfService.exportToPdf(
      uid: pdfService.getCurrentUserId(),
      setId: studySet.id,
      appVersion: pdfService.getAppVersion(),
      itemCounts: itemCounts,
      options: options,
      onProgress: (progress) {
        if (kDebugMode) {
          debugPrint('Export progress: ${progress.percentage}%');
        }
      },
      onCancelled: () {
        if (kDebugMode) {
          debugPrint('Export cancelled');
        }
      },
    );

    if (result.success && result.filePath != null) {
      return result.filePath!;
    } else {
      throw Exception(result.errorMessage ?? 'PDF generation failed');
    }
  }

  Future<void> _showEnforcementDialog(EnforcementResult result) async {
    await showEnforcementDialog(
      context,
      result,
      onUpgrade: () {
        Navigator.of(context).pop(); // Close enforcement dialog
        Navigator.of(context).pop(); // Close export dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(trigger: 'export_limit'),
            fullscreenDialog: true,
          ),
        );
      },
    );
  }

  void _showSuccessDialog(List<String> exportPaths) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Export Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successfully exported ${exportPaths.length} file(s):'),
            const SizedBox(height: 8),
            ...exportPaths.map((path) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    path.split('/').last,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final economy = economyService.userEconomy;

        if (economy == null) {
          return const AlertDialog(
            title: Text('Error'),
            content: Text('Economy system not initialized'),
          );
        }

        final canBatchExport = economy.tier == MindloadTier.cortex ||
            economy.tier == MindloadTier.singularity;
        final maxSets = canBatchExport ? 3 : 1;
        final hasEnoughExports =
            economy.exportsRemaining >= _selectedSets.length;

        final tokens = context.tokens;

        return AlertDialog(
          backgroundColor: tokens.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.file_download_outlined, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                'Export Study Sets',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Export Type Selection
              Text(
                'Export Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 8),

              Column(
                children: [
                  // When Flutter SDK exposes RadioGroup, wrap the below RadioListTile in a RadioGroup
                  RadioListTile<String>(
                    title: const Text('Flashcards'),
                    value: 'flashcards',
                    groupValue: _selectedExportType,
                    onChanged: (value) {
                      setState(() {
                        _selectedExportType = value!;
                      });
                    },
                  ),
                  // When Flutter SDK exposes RadioGroup, wrap the below RadioListTile in a RadioGroup
                  RadioListTile<String>(
                    title: const Text('Quiz'),
                    value: 'quiz',
                    groupValue: _selectedExportType,
                    onChanged: (value) {
                      setState(() {
                        _selectedExportType = value!;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Set Selection (if batch export available)
              if (canBatchExport && widget.additionalSets != null) ...[
                Text(
                  'Study Sets to Export',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MindloadTier.cortex.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            MindloadTier.cortex.color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.batch_prediction,
                              size: 16, color: MindloadTier.cortex.color),
                          const SizedBox(width: 8),
                          Text(
                            'Cortex Batch Export (up to 3 sets)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: MindloadTier.cortex.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Selected sets list
                      ..._selectedSets.take(maxSets).map((set) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    set.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: tokens.textPrimary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Export Options
              if (_selectedExportType == 'quiz_pdf') ...[
                CheckboxListTile(
                  title: const Text('Include Answers'),
                  value: _includeAnswers,
                  onChanged: _isExporting
                      ? null
                      : (value) {
                          setState(() => _includeAnswers = value!);
                        },
                  activeColor: tokens.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],

              CheckboxListTile(
                title: const Text('Include Mindload Header'),
                value: _includeMindloadHeader,
                onChanged: _isExporting
                    ? null
                    : (value) {
                        setState(() => _includeMindloadHeader = value!);
                      },
                activeColor: tokens.primary,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 16),

              // Export Quota Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasEnoughExports
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasEnoughExports
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 16,
                          color: hasEnoughExports ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export Quota',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: hasEnoughExports
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Will use: ${_selectedSets.length} export(s)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                        Text(
                          'Remaining: ${economy.exportsRemaining}/${economy.monthlyExports}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: hasEnoughExports
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: economy.monthlyExports > 0
                          ? (economy.monthlyExports -
                                  economy.exportsRemaining) /
                              economy.monthlyExports
                          : 0.0,
                      backgroundColor: tokens.surface.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(
                        hasEnoughExports ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  _isExporting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed:
                  _isExporting || !hasEnoughExports ? null : _exportContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: tokens.surface.withValues(alpha: 0.3),
              ),
              child: _isExporting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Exporting...'),
                      ],
                    )
                  : Text('Export (${_selectedSets.length})'),
            ),
          ],
        );
      },
    );
  }
}

/// Helper function to show export dialog
Future<void> showMindloadExportDialog(
  BuildContext context, {
  required StudySet studySet,
  List<StudySet>? additionalSets,
}) {
  return showDialog(
    context: context,
    builder: (context) => MindloadExportDialog(
      studySet: studySet,
      additionalSets: additionalSets,
    ),
  );
}
