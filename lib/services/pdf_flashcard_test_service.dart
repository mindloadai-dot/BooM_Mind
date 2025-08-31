import 'package:flutter/foundation.dart';
import 'package:mindload/services/enhanced_ai_service.dart';

/// Service to test and debug PDF to flashcards conversion
class PDFFlashcardTestService {
  static Future<void> testPDFToFlashcardsConversion() async {
    if (kDebugMode) {
      print('🧪 Starting PDF to Flashcards Conversion Test...');
    }

    // Simulate PDF content (common PDF text extraction result)
    const String pdfContent = '''
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

    if (kDebugMode) {
      print('📄 Test PDF Content Length: ${pdfContent.length} characters');
      print('📄 Content Preview: ${pdfContent.substring(0, 200)}...');
    }

    try {
      // Test the Enhanced AI Service with PDF content
      if (kDebugMode) {
        print('🚀 Testing EnhancedAIService with PDF content...');
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
        promptEnhancement: 'Focus on key concepts, definitions, and practical applications',
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

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ PDF to Flashcards Test Failed: $e');
        print('📍 Stack Trace: $stackTrace');
      }
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
      final minimalResult = await EnhancedAIService.instance.generateStudyMaterials(
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
      
      final mediumResult = await EnhancedAIService.instance.generateStudyMaterials(
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
      
      final fullResult = await EnhancedAIService.instance.generateStudyMaterials(
        content: content,
        flashcardCount: 2,
        quizCount: 1,
        difficulty: 'advanced',
        questionTypes: 'comprehensive',
        cognitiveLevel: 'advanced',
        realWorldContext: 'high',
        challengeLevel: 'advanced',
        learningStyle: 'adaptive',
        promptEnhancement: 'Focus on practical applications and real-world examples',
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
