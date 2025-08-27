import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'document_processor.dart';
import 'mindload_economy_service.dart';

/// Test service to diagnose PDF processing issues
class PdfTestService {
  static final PdfTestService _instance = PdfTestService._internal();
  factory PdfTestService() => _instance;
  PdfTestService._internal();

  /// Test PDF processing functionality
  Future<Map<String, dynamic>> testPdfProcessing() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Check if DocumentProcessor is accessible
      results['document_processor_accessible'] = true;
      results['supported_extensions'] = DocumentProcessor.getSupportedExtensions();
      
      // Test 2: Check if MindloadEconomyService is accessible
      final economyService = MindloadEconomyService.instance;
      results['economy_service_accessible'] = true;
      results['economy_initialized'] = economyService.isInitialized;
      
      // Test 3: Check PDF validation method
      try {
        // Create a minimal test PDF (1 page)
        final testPdfBytes = await _createTestPdf();
        results['test_pdf_created'] = true;
        results['test_pdf_size'] = testPdfBytes.length;
        
        // Test PDF validation
        await DocumentProcessor.validatePdfPageLimit(testPdfBytes);
        results['pdf_validation_passed'] = true;
        
        // Test text extraction
        final extractedText = await DocumentProcessor.extractTextFromFile(
          testPdfBytes, 
          'pdf', 
          'test.pdf'
        );
        results['text_extraction_passed'] = true;
        results['extracted_text_length'] = extractedText.length;
        
      } catch (e) {
        results['pdf_processing_error'] = e.toString();
        results['pdf_processing_stack_trace'] = StackTrace.current.toString();
      }
      
      // Test 4: Check file format support
      results['format_display_names'] = {};
      for (final ext in DocumentProcessor.getSupportedExtensions()) {
        results['format_display_names'][ext] = DocumentProcessor.getFormatDisplayName(ext);
      }
      
    } catch (e) {
      results['service_error'] = e.toString();
      results['service_stack_trace'] = StackTrace.current.toString();
    }
    
    return results;
  }

  /// Create a minimal test PDF for testing
  Future<Uint8List> _createTestPdf() async {
    try {
      // Use DocumentProcessor's image to PDF conversion
      final testImageBytes = _createTestImage();
      return await DocumentProcessor.convertImageToPdfBytes(testImageBytes);
    } catch (e) {
      throw Exception('Failed to create test PDF: $e');
    }
  }

  /// Create a minimal test image
  Uint8List _createTestImage() {
    // Create a simple 1x1 pixel PNG image
    // This is a minimal valid PNG file
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, // Width: 1
      0x00, 0x00, 0x00, 0x01, // Height: 1
      0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
      0x90, 0x77, 0x53, 0xDE, // CRC
      0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
      0x49, 0x44, 0x41, 0x54, // IDAT
      0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // Image data
      0xE2, 0x21, 0xBC, 0x33, // CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk length
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82, // CRC
    ]);
  }

  /// Get comprehensive PDF processing status
  Map<String, dynamic> getPdfProcessingStatus() {
    return {
      'service_available': true,
      'supported_formats': DocumentProcessor.getSupportedExtensions(),
      'max_text_length': DocumentProcessor.maxTextLength,
      'test_available': true,
    };
  }
}
