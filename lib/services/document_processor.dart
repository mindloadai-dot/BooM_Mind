import 'dart:convert';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:mindload/services/mindload_economy_service.dart';

import 'package:mindload/models/mindload_economy_models.dart';

class DocumentProcessor {
  static const int maxTextLength = 10000; // Limit text extraction for performance

  static Future<String> extractTextFromFile(
    Uint8List bytes, 
    String extension, 
    String fileName
  ) async {
    try {
      switch (extension.toLowerCase()) {
        case 'txt':
          return _extractFromTxt(bytes);
        case 'rtf':
          return _extractFromRtf(bytes);
        case 'pdf':
          return await _extractFromPdf(bytes, fileName);
        case 'doc':
        case 'docx':
          return await _extractFromDocx(bytes, fileName);
        case 'epub':
          return await _extractFromEpub(bytes, fileName);
        case 'odt':
          return await _extractFromOdt(bytes, fileName);
        default:
          throw UnsupportedError('File format .$extension is not supported');
      }
    } catch (e) {
      throw Exception('Failed to extract text from $fileName: ${e.toString()}');
    }
  }

  static Future<void> validatePdfPageLimit(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();

      // Use MindloadEconomyService for validation
      final economyService = MindloadEconomyService.instance;
      
      // Check if user can afford this PDF processing
      final request = GenerationRequest(
        sourceContent: 'PDF upload',
        sourceCharCount: pageCount * 500, // Estimate 500 chars per page
        pdfPageCount: pageCount,
      );
      
      final enforcementResult = economyService.canGenerateContent(request);
      if (!enforcementResult.canProceed) {
        throw Exception(enforcementResult.blockReason ?? 'Cannot process this PDF');
      }

      // Check page limits based on user's tier
      final userEconomy = economyService.userEconomy;
      if (userEconomy != null) {
        final maxPages = userEconomy.pdfPageLimit;
        if (pageCount > maxPages) {
          throw Exception('PDF has $pageCount pages, but your plan allows max $maxPages pages');
        }
      }
    } catch (e) {
      if (e.toString().contains('pages')) rethrow;
      throw Exception('Failed to validate PDF: ${e.toString()}');
    }
  }

  // Convert a single image to a 1-page PDF for upload
  static Future<Uint8List> convertImageToPdfBytes(Uint8List imageBytes) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final image = PdfBitmap(imageBytes);
    page.graphics.drawImage(
      image,
      Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
    );
    final output = document.saveSync();
    document.dispose();
    return Uint8List.fromList(output);
  }

  static String _extractFromTxt(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes);
      return text.length > maxTextLength 
          ? '${text.substring(0, maxTextLength)}\n\n[Text truncated for performance]'
          : text;
    } catch (e) {
      throw Exception('Failed to decode text file: ${e.toString()}');
    }
  }

  static String _extractFromRtf(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes);
      // Basic RTF processing - remove RTF control codes
      final cleanText = text
          .replaceAll(RegExp(r'\\[a-zA-Z]+\d*'), '') // Remove RTF commands
          .replaceAll(RegExp(r'\{|\}'), '') // Remove braces
          .replaceAll(RegExp(r'\\'), '') // Remove backslashes
          .trim();
      
      return cleanText.length > maxTextLength 
          ? '${cleanText.substring(0, maxTextLength)}\n\n[Text truncated for performance]'
          : cleanText;
    } catch (e) {
      throw Exception('Failed to process RTF file: ${e.toString()}');
    }
  }

  static Future<String> _extractFromPdf(Uint8List bytes, String fileName) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final textExtractor = PdfTextExtractor(document);
      
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
        extractedText += pageText;
        
        // Limit extraction for performance
        if (extractedText.length > maxTextLength) {
          extractedText = '${extractedText.substring(0, maxTextLength)}\n\n[PDF content truncated for performance]';
          break;
        }
      }
      
      document.dispose();
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No text content found in PDF');
      }
      
      return extractedText;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: ${e.toString()}');
    }
  }

  static Future<String> _extractFromDocx(Uint8List bytes, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find document.xml in the DOCX archive
      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }
      
      if (documentXml == null) {
        throw Exception('Invalid DOCX file: document.xml not found');
      }
      
      final xmlContent = utf8.decode(documentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      
      // Extract text from all text nodes
      String extractedText = '';
      final textNodes = document.findAllElements('w:t');
      
      for (final node in textNodes) {
        final text = node.innerText;
        extractedText += '$text ';
        
        // Limit extraction for performance
        if (extractedText.length > maxTextLength) {
          extractedText = '${extractedText.substring(0, maxTextLength)}\n\n[DOCX content truncated for performance]';
          break;
        }
      }
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No text content found in DOCX file');
      }
      
      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: ${e.toString()}');
    }
  }

  static Future<String> _extractFromEpub(Uint8List bytes, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      String extractedText = '';
      
      // Extract text from XHTML/HTML files in the EPUB
      for (final file in archive) {
        if (file.name.endsWith('.xhtml') || 
            file.name.endsWith('.html') || 
            file.name.contains('chapter') ||
            file.name.contains('content')) {
          
          try {
            final htmlContent = utf8.decode(file.content as List<int>);
            
            // Parse XML/HTML and extract text
            final document = XmlDocument.parse(htmlContent);
            final bodyElements = document.findAllElements('body');
            
            if (bodyElements.isNotEmpty) {
              final bodyText = bodyElements.first.innerText;
              final cleanText = bodyText
                  .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
                  .trim();
              
              if (cleanText.isNotEmpty) {
                extractedText += '$cleanText\n\n';
              }
            }
            
            // Limit extraction for performance
            if (extractedText.length > maxTextLength) {
              extractedText = '${extractedText.substring(0, maxTextLength)}\n\n[EPUB content truncated for performance]';
              break;
            }
          } catch (e) {
            // Skip files that can't be parsed as XML/HTML
            continue;
          }
        }
      }
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No readable text content found in EPUB file');
      }
      
      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from EPUB: ${e.toString()}');
    }
  }

  static Future<String> _extractFromOdt(Uint8List bytes, String fileName) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find content.xml in the ODT archive
      ArchiveFile? contentXml;
      for (final file in archive) {
        if (file.name == 'content.xml') {
          contentXml = file;
          break;
        }
      }
      
      if (contentXml == null) {
        throw Exception('Invalid ODT file: content.xml not found');
      }
      
      final xmlContent = utf8.decode(contentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);
      
      // Extract text from paragraph elements
      String extractedText = '';
      final paragraphs = document.findAllElements('text:p');
      
      for (final paragraph in paragraphs) {
        final text = paragraph.innerText;
        if (text.trim().isNotEmpty) {
          extractedText += '$text\n\n';
        }
        
        // Limit extraction for performance
        if (extractedText.length > maxTextLength) {
          extractedText = '${extractedText.substring(0, maxTextLength)}\n\n[ODT content truncated for performance]';
          break;
        }
      }
      
      if (extractedText.trim().isEmpty) {
        throw Exception('No text content found in ODT file');
      }
      
      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from ODT: ${e.toString()}');
    }
  }

  static List<String> getSupportedExtensions() {
    return ['txt', 'rtf', 'pdf', 'doc', 'docx', 'epub', 'odt'];
  }

  static String getFormatDisplayName(String extension) {
    switch (extension.toLowerCase()) {
      case 'txt': return 'Text Document';
      case 'rtf': return 'Rich Text Format';
      case 'pdf': return 'PDF Document';
      case 'doc': return 'Word Document (Legacy)';
      case 'docx': return 'Word Document';
      case 'epub': return 'EPUB Ebook';
      case 'odt': return 'OpenDocument Text';
      default: return 'Unknown Format';
    }
  }
}