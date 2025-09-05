import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/enhanced_ai_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';
import 'package:mindload/models/study_data.dart';

void main() async {
  print('🔍 Starting comprehensive AI services debug...');

  try {
    // Initialize Firebase if not already initialized
    if (Firebase.apps.isEmpty) {
      print('🔥 Initializing Firebase...');
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');
    } else {
      print('✅ Firebase already initialized');
    }
  } catch (e) {
    print('⚠️ Firebase initialization failed (continuing anyway): $e');
  }

  await testAllAIServices();

  print('🏁 Comprehensive AI debug completed');
  exit(0);
}

Future<void> testAllAIServices() async {
  print('\n' + '=' * 60);
  print('🧪 COMPREHENSIVE AI SERVICES TEST');
  print('=' * 60);

  final testContent = '''
    Artificial Intelligence (AI) is a branch of computer science that aims to create intelligent machines that work and react like humans. 
    Some of the activities computers with artificial intelligence are designed for include speech recognition, learning, planning, and problem solving.
    AI can be categorized as either weak AI or strong AI. Weak AI, also known as narrow AI, is designed to perform a narrow task. 
    Strong AI, also known as artificial general intelligence, is an AI system with generalized human cognitive abilities.
    Machine learning is a subset of AI that provides systems the ability to automatically learn and improve from experience without being explicitly programmed.
    Deep learning is a subset of machine learning that uses neural networks with multiple layers to analyze various factors of data.
  ''';

  print('📝 Test content length: ${testContent.length} characters');
  print('');

  // Test 1: Enhanced AI Service
  await testEnhancedAIService(testContent);

  // Test 2: Local AI Fallback Service
  await testLocalAIFallbackService(testContent);

  // Test 3: Individual method tests
  await testIndividualMethods(testContent);

  // Test 4: Error handling
  await testErrorHandling();

  // Test 5: Integration test
  await testIntegrationFlow(testContent);
}

Future<void> testEnhancedAIService(String content) async {
  print('\n🚀 TESTING ENHANCED AI SERVICE');
  print('-' * 40);

  try {
    final enhancedAI = EnhancedAIService.instance;
    print('✅ EnhancedAIService instance created');

    // Test main generation method
    print('🔍 Testing generateStudyMaterials...');
    final result = await enhancedAI.generateStudyMaterials(
      content: content,
      flashcardCount: 3,
      quizCount: 2,
      difficulty: 'medium',
    );

    print('📊 Generation Result:');
    print('   - Success: ${result.isSuccess}');
    print('   - Method: ${result.method.name}');
    print('   - Flashcards: ${result.flashcards.length}');
    print('   - Quiz Questions: ${result.quizQuestions.length}');
    print('   - Is Fallback: ${result.isFallback}');
    print('   - Processing Time: ${result.processingTimeMs}ms');

    if (!result.isSuccess) {
      print('❌ Error: ${result.errorMessage}');
    }

    // Print sample flashcards
    if (result.flashcards.isNotEmpty) {
      print('📚 Sample Flashcard:');
      final card = result.flashcards.first;
      print('   Q: ${card.question}');
      print('   A: ${card.answer}');
      print('   Difficulty: ${card.difficulty.name}');
    }

    // Print sample quiz questions
    if (result.quizQuestions.isNotEmpty) {
      print('❓ Sample Quiz Question:');
      final question = result.quizQuestions.first;
      print('   Q: ${question.question}');
      print('   Options: ${question.options.join(', ')}');
      print('   Correct: ${question.correctAnswer}');
      print('   Difficulty: ${question.difficulty.name}');
    }
  } catch (e, stackTrace) {
    print('❌ EnhancedAIService test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testLocalAIFallbackService(String content) async {
  print('\n🔄 TESTING LOCAL AI FALLBACK SERVICE');
  print('-' * 40);

  try {
    final localAI = LocalAIFallbackService.instance;
    print('✅ LocalAIFallbackService instance created');

    // Test flashcard generation
    print('🔍 Testing generateFlashcards...');
    final flashcards = await localAI.generateFlashcards(
      content,
      count: 3,
      targetDifficulty: DifficultyLevel.intermediate,
    );

    print('📊 Flashcard Generation Result:');
    print('   - Generated: ${flashcards.length} flashcards');

    if (flashcards.isNotEmpty) {
      print('📚 Sample Flashcard:');
      final card = flashcards.first;
      print('   Q: ${card.question}');
      print('   A: ${card.answer}');
      print('   Difficulty: ${card.difficulty.name}');
      print('   Type: ${card.questionType?.name ?? 'N/A'}');
    }

    // Test quiz generation
    print('🔍 Testing generateQuizQuestions...');
    final quizQuestions = await localAI.generateQuizQuestions(
      content,
      2,
      'medium',
    );

    print('📊 Quiz Generation Result:');
    print('   - Generated: ${quizQuestions.length} quiz questions');

    if (quizQuestions.isNotEmpty) {
      print('❓ Sample Quiz Question:');
      final question = quizQuestions.first;
      print('   Q: ${question.question}');
      print('   Options: ${question.options.join(', ')}');
      print('   Correct: ${question.correctAnswer}');
      print('   Difficulty: ${question.difficulty.name}');
      print('   Type: ${question.type.name}');
    }
  } catch (e, stackTrace) {
    print('❌ LocalAIFallbackService test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testIndividualMethods(String content) async {
  print('\n🔬 TESTING INDIVIDUAL METHODS');
  print('-' * 40);

  try {
    final enhancedAI = EnhancedAIService.instance;

    // Test content processing
    print('🔍 Testing content processing...');
    final contentResult = await enhancedAI.processContentAndGenerate(
      input: content,
      sourceType: ContentSourceType.text,
      flashcardCount: 2,
      quizCount: 1,
      difficulty: 'medium',
    );

    print('📊 Content Processing Result:');
    print('   - Success: ${contentResult.isSuccess}');
    print('   - Method: ${contentResult.method.name}');
    print('   - Flashcards: ${contentResult.flashcards.length}');
    print('   - Quiz Questions: ${contentResult.quizQuestions.length}');

    if (!contentResult.isSuccess) {
      print('❌ Content Processing Error: ${contentResult.errorMessage}');
    }
  } catch (e, stackTrace) {
    print('❌ Individual methods test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testErrorHandling() async {
  print('\n⚠️ TESTING ERROR HANDLING');
  print('-' * 40);

  try {
    final enhancedAI = EnhancedAIService.instance;

    // Test with empty content
    print('🔍 Testing with empty content...');
    final emptyResult = await enhancedAI.generateStudyMaterials(
      content: '',
      flashcardCount: 1,
      quizCount: 1,
      difficulty: 'medium',
    );

    print('📊 Empty Content Result:');
    print('   - Success: ${emptyResult.isSuccess}');
    print('   - Error: ${emptyResult.errorMessage}');

    // Test with invalid parameters
    print('🔍 Testing with invalid parameters...');
    final invalidResult = await enhancedAI.generateStudyMaterials(
      content: 'Test content',
      flashcardCount: -1,
      quizCount: 0,
      difficulty: 'invalid',
    );

    print('📊 Invalid Parameters Result:');
    print('   - Success: ${invalidResult.isSuccess}');
    print('   - Error: ${invalidResult.errorMessage}');

    // Test with very long content
    print('🔍 Testing with very long content...');
    final longContent = 'A' * 100000; // 100k characters
    final longResult = await enhancedAI.generateStudyMaterials(
      content: longContent,
      flashcardCount: 1,
      quizCount: 1,
      difficulty: 'medium',
    );

    print('📊 Long Content Result:');
    print('   - Success: ${longResult.isSuccess}');
    print('   - Method: ${longResult.method.name}');
    print('   - Flashcards: ${longResult.flashcards.length}');
    print('   - Quiz Questions: ${longResult.quizQuestions.length}');
  } catch (e, stackTrace) {
    print('❌ Error handling test failed: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testIntegrationFlow(String content) async {
  print('\n🔗 TESTING INTEGRATION FLOW');
  print('-' * 40);

  try {
    print('🔍 Testing complete flow with different content types...');

    // Test with different source types
    final enhancedAI = EnhancedAIService.instance;

    // Test document processing
    final docResult = await enhancedAI.processContentAndGenerate(
      input: content,
      sourceType: ContentSourceType.document,
      flashcardCount: 2,
      quizCount: 1,
      difficulty: 'medium',
      additionalOptions: {
        'fileBytes': content.codeUnits,
        'extension': 'txt',
        'fileName': 'test.txt',
      },
    );

    print('📊 Document Processing Result:');
    print('   - Success: ${docResult.isSuccess}');
    print('   - Method: ${docResult.method.name}');
    print(
        '   - Content Result: ${docResult.contentResult?.isSuccess ?? false}');

    // Test with different difficulties
    final difficulties = ['easy', 'medium', 'hard', 'advanced'];
    for (final difficulty in difficulties) {
      print('🔍 Testing difficulty: $difficulty');
      final diffResult = await enhancedAI.generateStudyMaterials(
        content: content,
        flashcardCount: 1,
        quizCount: 1,
        difficulty: difficulty,
      );

      print(
          '   - $difficulty: ${diffResult.isSuccess ? "✅" : "❌"} (${diffResult.method.name})');
    }
  } catch (e, stackTrace) {
    print('❌ Integration flow test failed: $e');
    print('Stack trace: $stackTrace');
  }
}
