import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

/// Service for extracting text from PDF files
class PDFTextExtractionService {
  static PDFTextExtractionService? _instance;
  static PDFTextExtractionService get instance =>
      _instance ??= PDFTextExtractionService._();
  PDFTextExtractionService._();

  /// Extract text from a PDF file
  Future<String> extractTextFromPDF(File pdfFile) async {
    try {
      debugPrint('📄 Starting PDF text extraction from: ${pdfFile.path}');

      // Validate file exists
      if (!await pdfFile.exists()) {
        throw Exception('PDF file does not exist: ${pdfFile.path}');
      }

      // Validate file size
      final fileSize = await pdfFile.length();
      if (fileSize == 0) {
        throw Exception('PDF file is empty: ${pdfFile.path}');
      }

      debugPrint('📄 PDF file size: $fileSize bytes');

      // Read PDF file
      final bytes = await pdfFile.readAsBytes();
      debugPrint('📄 PDF bytes loaded: ${bytes.length} bytes');

      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      debugPrint('📄 PDF document loaded successfully');

      try {
        // Extract text from all pages
        final extractedText = await _extractTextFromDocument(document);
        debugPrint(
            '📄 Text extraction completed: ${extractedText.length} characters');

        return extractedText;
      } finally {
        // Dispose document to free memory
        document.dispose();
        debugPrint('📄 PDF document disposed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PDF text extraction failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Extract text from PDF document
  Future<String> _extractTextFromDocument(PdfDocument document) async {
    final StringBuffer textBuffer = StringBuffer();

    // Extract text from each page
    for (int i = 0; i < document.pages.count; i++) {
      final PdfPage page = document.pages[i];
      debugPrint('📄 Processing page ${i + 1}/${document.pages.count}');

      try {
        // Extract text from page
        final String pageText =
            PdfTextExtractor(document).extractText(startPageIndex: i);

        if (pageText.isNotEmpty) {
          textBuffer.writeln(pageText);
          debugPrint(
              '📄 Page ${i + 1} text length: ${pageText.length} characters');
        } else {
          debugPrint('⚠️ Page ${i + 1} has no extractable text');
        }
      } catch (pageError) {
        debugPrint('⚠️ Error extracting text from page ${i + 1}: $pageError');
        // Continue with next page
      }
    }

    final extractedText = textBuffer.toString().trim();

    if (extractedText.isEmpty) {
      debugPrint('⚠️ No text could be extracted from PDF');
      return 'No text could be extracted from this PDF. The document may be image-based or password-protected.';
    }

    return extractedText;
  }

  /// Extract text from PDF bytes (for testing with sample data)
  Future<String> extractTextFromBytes(Uint8List pdfBytes) async {
    try {
      debugPrint(
          '📄 Starting PDF text extraction from bytes: ${pdfBytes.length} bytes');

      // Load PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      debugPrint('📄 PDF document loaded from bytes successfully');

      try {
        // Extract text from all pages
        final extractedText = await _extractTextFromDocument(document);
        debugPrint(
            '📄 Text extraction from bytes completed: ${extractedText.length} characters');

        return extractedText;
      } finally {
        // Dispose document to free memory
        document.dispose();
        debugPrint('📄 PDF document disposed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PDF text extraction from bytes failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a sample PDF for testing
  Future<File> createSamplePDF() async {
    try {
      debugPrint('📄 Creating sample PDF for testing...');

      // Create a new PDF document
      final PdfDocument document = PdfDocument();

      try {
        // Add a page
        final PdfPage page = document.pages.add();
        final PdfGraphics graphics = page.graphics;

        // Add text content
        final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
        final PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0));

        // Sample content for testing
        final String sampleContent = '''
Introduction to Machine Learning

Machine learning is a subset of artificial intelligence (AI) that provides systems the ability to automatically learn and improve from experience without being explicitly programmed. Machine learning focuses on the development of computer programs that can access data and use it to learn for themselves.

The process of learning begins with observations or data, such as examples, direct experience, or instruction, in order to look for patterns in data and make better decisions in the future based on the examples that we provide. The primary aim is to allow the computers to learn automatically without human intervention or assistance and adjust actions accordingly.

Types of Machine Learning:

1. Supervised Learning
Supervised learning is the machine learning task of learning a function that maps an input to an output based on example input-output pairs. It infers a function from labeled training data consisting of a set of training examples.

2. Unsupervised Learning  
Unsupervised learning is a type of machine learning algorithm used to draw inferences from datasets consisting of input data without labeled responses. The most common unsupervised learning method is cluster analysis.

3. Reinforcement Learning
Reinforcement learning is an area of machine learning concerned with how software agents ought to take actions in an environment in order to maximize the notion of cumulative reward.

Applications of Machine Learning:
- Image Recognition
- Speech Recognition
- Medical Diagnosis
- Financial Services
- Autonomous Vehicles
- Recommendation Systems
        ''';

        // Draw text on page
        final PdfStringFormat format = PdfStringFormat(
          lineSpacing: 1.2,
          wordSpacing: 0.5,
        );

        graphics.drawString(
          sampleContent,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(50, 50, 500, 700),
          format: format,
        );

        // Save PDF to temporary file
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName =
            'sample_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final File pdfFile = File('${tempDir.path}/$fileName');

        final List<int> bytes = await document.save();
        await pdfFile.writeAsBytes(bytes);

        debugPrint('📄 Sample PDF created: ${pdfFile.path}');
        return pdfFile;
      } finally {
        // Dispose document
        document.dispose();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to create sample PDF: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Validate PDF file
  Future<bool> isValidPDF(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 4) {
        return false;
      }

      // Check PDF header (%PDF)
      final header = String.fromCharCodes(bytes.take(4));
      return header == '%PDF';
    } catch (e) {
      debugPrint('❌ PDF validation failed: $e');
      return false;
    }
  }

  /// Get PDF metadata
  Future<Map<String, dynamic>> getPDFMetadata(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      try {
        final Map<String, dynamic> metadata = {
          'pageCount': document.pages.count,
          'fileSize': bytes.length,
          'fileName': pdfFile.path.split('/').last,
          'filePath': pdfFile.path,
        };

        debugPrint('📄 PDF metadata: $metadata');
        return metadata;
      } finally {
        document.dispose();
      }
    } catch (e) {
      debugPrint('❌ Failed to get PDF metadata: $e');
      return {
        'error': e.toString(),
        'fileName': pdfFile.path.split('/').last,
      };
    }
  }
}
