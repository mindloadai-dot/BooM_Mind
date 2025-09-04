import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/enhanced_ai_service.dart';
import 'package:mindload/services/pdf_text_extraction_service.dart';

/// Service to test and debug PDF to flashcards conversion with real PDF parsing
class PDFFlashcardTestService {
  static Future<void> testPDFToFlashcardsConversion() async {
    if (kDebugMode) {
      print(
          '🧪 Starting PDF to Flashcards Conversion Test with Real PDF Parsing...');
    }

    try {
      // Create a sample PDF for testing
      if (kDebugMode) {
        print('📄 Creating sample PDF for testing...');
      }

      final samplePDF =
          await PDFTextExtractionService.instance.createSamplePDF();

      // Validate the PDF
      final isValid =
          await PDFTextExtractionService.instance.isValidPDF(samplePDF);
      if (!isValid) {
        throw Exception('Generated sample PDF is not valid');
      }

      // Get PDF metadata
      final metadata =
          await PDFTextExtractionService.instance.getPDFMetadata(samplePDF);
      if (kDebugMode) {
        print('📄 PDF Metadata: $metadata');
      }

      // Extract text from the real PDF
      if (kDebugMode) {
        print('📄 Extracting text from real PDF...');
      }

      final pdfContent =
          await PDFTextExtractionService.instance.extractTextFromPDF(samplePDF);

      if (kDebugMode) {
        print('📄 Real PDF Content Length: ${pdfContent.length} characters');
        print('📄 Content Preview: ${pdfContent.substring(0, 200)}...');
      }

      // Test the Enhanced AI Service with real PDF content
      if (kDebugMode) {
        print('🚀 Testing EnhancedAIService with real PDF content...');
      }

      final result = await EnhancedAIService.instance.generateStudyMaterials(
        content: pdfContent,
        flashcardCount: 5,
        quizCount: 3,
        difficulty: 'medium',
        questionTypes: 'comprehensive',
        cognitiveLevel: 'intermediate',
        realWorldContext: 'high',
        challengeLevel: 'medium',
        learningStyle: 'adaptive',
        promptEnhancement:
            'Focus on key concepts, definitions, and practical applications',
      );

      if (kDebugMode) {
        print('📊 Test Results:');
        print('   - Success: ${result.isSuccess}');
        print('   - Method Used: ${result.method.name}');
        print('   - Is Fallback: ${result.isFallback}');
        print('   - Processing Time: ${result.processingTimeMs}ms');
        print('   - Flashcards Generated: ${result.flashcards.length}');
        print('   - Quiz Questions Generated: ${result.quizQuestions.length}');

        if (result.errorMessage != null) {
          print('   - Error: ${result.errorMessage}');
        }

        // Display generated flashcards
        if (result.flashcards.isNotEmpty) {
          print('🃏 Generated Flashcards:');
          for (int i = 0; i < result.flashcards.length; i++) {
            final card = result.flashcards[i];
            print('   ${i + 1}. Q: ${card.question}');
            print('      A: ${card.answer}');
            print('      Difficulty: ${card.difficulty.name}');
            print('');
          }
        } else {
          print('❌ No flashcards were generated');
        }

        // Display generated quiz questions
        if (result.quizQuestions.isNotEmpty) {
          print('❓ Generated Quiz Questions:');
          for (int i = 0; i < result.quizQuestions.length; i++) {
            final question = result.quizQuestions[i];
            print('   ${i + 1}. Q: ${question.question}');
            print('      Options: ${question.options.join(', ')}');
            print('      Correct: ${question.correctAnswer}');
            print('      Difficulty: ${question.difficulty.name}');
            print('');
          }
        } else {
          print('❌ No quiz questions were generated');
        }
      }

      // Test individual methods for debugging
      await _testIndividualMethods(pdfContent);

      // Clean up the sample PDF file
      try {
        await samplePDF.delete();
        if (kDebugMode) {
          print('📄 Sample PDF file cleaned up');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to clean up sample PDF: $e');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ PDF to Flashcards Test Failed: $e');
        print('📍 Stack Trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Test PDF parsing with an actual PDF file
  static Future<void> testWithActualPDF(File pdfFile) async {
    if (kDebugMode) {
      print('🧪 Testing with actual PDF file: ${pdfFile.path}');
    }

    try {
      // Validate the PDF
      final isValid =
          await PDFTextExtractionService.instance.isValidPDF(pdfFile);
      if (!isValid) {
        throw Exception('The provided file is not a valid PDF');
      }

      // Get PDF metadata
      final metadata =
          await PDFTextExtractionService.instance.getPDFMetadata(pdfFile);
      if (kDebugMode) {
        print('📄 PDF Metadata: $metadata');
      }

      // Extract text from the actual PDF
      if (kDebugMode) {
        print('📄 Extracting text from actual PDF...');
      }

      final pdfContent =
          await PDFTextExtractionService.instance.extractTextFromPDF(pdfFile);

      if (kDebugMode) {
        print('📄 Actual PDF Content Length: ${pdfContent.length} characters');
        print('📄 Content Preview: ${pdfContent.substring(0, 200)}...');
      }

      // Test the Enhanced AI Service with actual PDF content
      if (kDebugMode) {
        print('🚀 Testing EnhancedAIService with actual PDF content...');
      }

      final result = await EnhancedAIService.instance.generateStudyMaterials(
        content: pdfContent,
        flashcardCount: 3,
        quizCount: 2,
        difficulty: 'medium',
        questionTypes: 'comprehensive',
        cognitiveLevel: 'intermediate',
        realWorldContext: 'high',
        challengeLevel: 'medium',
        learningStyle: 'adaptive',
        promptEnhancement:
            'Focus on key concepts, definitions, and practical applications',
      );

      if (kDebugMode) {
        print('📊 Actual PDF Test Results:');
        print('   - Success: ${result.isSuccess}');
        print('   - Method Used: ${result.method.name}');
        print('   - Is Fallback: ${result.isFallback}');
        print('   - Processing Time: ${result.processingTimeMs}ms');
        print('   - Flashcards Generated: ${result.flashcards.length}');
        print('   - Quiz Questions Generated: ${result.quizQuestions.length}');

        if (result.errorMessage != null) {
          print('   - Error: ${result.errorMessage}');
        }

        // Display generated flashcards
        if (result.flashcards.isNotEmpty) {
          print('🃏 Generated Flashcards from Actual PDF:');
          for (int i = 0; i < result.flashcards.length; i++) {
            final card = result.flashcards[i];
            print('   ${i + 1}. Q: ${card.question}');
            print('      A: ${card.answer}');
            print('      Difficulty: ${card.difficulty.name}');
            print('');
          }
        } else {
          print('❌ No flashcards were generated from actual PDF');
        }

        // Display generated quiz questions
        if (result.quizQuestions.isNotEmpty) {
          print('❓ Generated Quiz Questions from Actual PDF:');
          for (int i = 0; i < result.quizQuestions.length; i++) {
            final question = result.quizQuestions[i];
            print('   ${i + 1}. Q: ${question.question}');
            print('      Options: ${question.options.join(', ')}');
            print('      Correct: ${question.correctAnswer}');
            print('      Difficulty: ${question.difficulty.name}');
            print('');
          }
        } else {
          print('❌ No quiz questions were generated from actual PDF');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Actual PDF Test Failed: $e');
        print('📍 Stack Trace: $stackTrace');
      }
      rethrow;
    }
  }

  static Future<void> _testIndividualMethods(String content) async {
    if (kDebugMode) {
      print('🔍 Testing Individual Generation Methods...');
    }

    // Test methods with different parameters to see which ones work
    try {
      if (kDebugMode) {
        print('🤖 Testing OpenAI with different parameters...');
      }

      // Test with minimal parameters
      final minimalResult =
          await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: 1,
        quizCount: 0,
        difficulty: 'easy',
      );

      if (kDebugMode) {
        print('   - Minimal Test Success: ${minimalResult.isSuccess}');
        print('   - Method Used: ${minimalResult.method.name}');
        print('   - Flashcards: ${minimalResult.flashcards.length}');
        if (minimalResult.errorMessage != null) {
          print('   - Error: ${minimalResult.errorMessage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   - Minimal Test Failed: $e');
      }
    }

    // Test with medium complexity
    try {
      if (kDebugMode) {
        print('🏠 Testing with medium complexity...');
      }

      final mediumResult =
          await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: 3,
        quizCount: 2,
        difficulty: 'medium',
        questionTypes: 'comprehensive',
      );

      if (kDebugMode) {
        print('   - Medium Test Success: ${mediumResult.isSuccess}');
        print('   - Method Used: ${mediumResult.method.name}');
        print('   - Flashcards: ${mediumResult.flashcards.length}');
        print('   - Quiz Questions: ${mediumResult.quizQuestions.length}');
        if (mediumResult.errorMessage != null) {
          print('   - Error: ${mediumResult.errorMessage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   - Medium Test Failed: $e');
      }
    }

    // Test with full parameters
    try {
      if (kDebugMode) {
        print('📋 Testing with full parameters...');
      }

      final fullResult =
          await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: 2,
        quizCount: 1,
        difficulty: 'advanced',
        questionTypes: 'comprehensive',
        cognitiveLevel: 'advanced',
        realWorldContext: 'high',
        challengeLevel: 'advanced',
        learningStyle: 'adaptive',
        promptEnhancement:
            'Focus on practical applications and real-world examples',
      );

      if (kDebugMode) {
        print('   - Full Test Success: ${fullResult.isSuccess}');
        print('   - Method Used: ${fullResult.method.name}');
        print('   - Is Fallback: ${fullResult.isFallback}');
        print('   - Processing Time: ${fullResult.processingTimeMs}ms');
        print('   - Flashcards: ${fullResult.flashcards.length}');
        print('   - Quiz Questions: ${fullResult.quizQuestions.length}');
        if (fullResult.errorMessage != null) {
          print('   - Error: ${fullResult.errorMessage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   - Full Test Failed: $e');
      }
    }
  }

  /// Test the Cloud Functions directly
  static Future<void> testCloudFunctions() async {
    if (kDebugMode) {
      print('☁️ Testing Cloud Functions directly...');
    }

    const String testContent = '''
Artificial Intelligence is the simulation of human intelligence in machines that are programmed to think and learn like humans.
It includes machine learning, natural language processing, and computer vision.
AI systems can perform tasks that typically require human intelligence.
    ''';

    try {
      // This would require importing cloud_functions and testing directly
      // For now, we'll simulate the test
      if (kDebugMode) {
        print('📡 Cloud Functions test would go here...');
        print('   - Test content: ${testContent.length} characters');
        print('   - Would test generateFlashcards function');
        print('   - Would test generateQuiz function');
        print('   - Would verify response format');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cloud Functions test failed: $e');
      }
    }
  }
}
