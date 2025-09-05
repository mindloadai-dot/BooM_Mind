import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';
import 'package:mindload/models/study_data.dart';

void main() async {
  print('🔍 Starting simple AI services test...');

  await testLocalAIService();

  print('🏁 Simple AI test completed');
  exit(0);
}

Future<void> testLocalAIService() async {
  print('\n🔄 TESTING LOCAL AI FALLBACK SERVICE');
  print('-' * 50);

  final testContent = '''
    Artificial Intelligence (AI) is a branch of computer science that aims to create intelligent machines that work and react like humans. 
    Some of the activities computers with artificial intelligence are designed for include speech recognition, learning, planning, and problem solving.
    AI can be categorized as either weak AI or strong AI. Weak AI, also known as narrow AI, is designed to perform a narrow task. 
    Strong AI, also known as artificial general intelligence, is an AI system with generalized human cognitive abilities.
    Machine learning is a subset of AI that provides systems the ability to automatically learn and improve from experience without being explicitly programmed.
    Deep learning is a subset of machine learning that uses neural networks with multiple layers to analyze various factors of data.
  ''';

  print('📝 Test content length: ${testContent.length} characters');

  try {
    final localAI = LocalAIFallbackService.instance;
    print('✅ LocalAIFallbackService instance created');

    // Test flashcard generation
    print('\n🔍 Testing generateFlashcards...');
    final flashcards = await localAI.generateFlashcards(
      testContent,
      count: 3,
      targetDifficulty: DifficultyLevel.intermediate,
    );

    print('📊 Flashcard Generation Result:');
    print('   - Generated: ${flashcards.length} flashcards');

    if (flashcards.isNotEmpty) {
      for (int i = 0; i < flashcards.length; i++) {
        final card = flashcards[i];
        print('\n📚 Flashcard ${i + 1}:');
        print('   Q: ${card.question}');
        print('   A: ${card.answer}');
        print('   Difficulty: ${card.difficulty.name}');
        print('   Type: ${card.questionType?.name ?? 'N/A'}');
      }
    } else {
      print('❌ No flashcards generated!');
    }

    // Test quiz generation
    print('\n🔍 Testing generateQuizQuestions...');
    final quizQuestions = await localAI.generateQuizQuestions(
      testContent,
      2,
      'medium',
    );

    print('📊 Quiz Generation Result:');
    print('   - Generated: ${quizQuestions.length} quiz questions');

    if (quizQuestions.isNotEmpty) {
      for (int i = 0; i < quizQuestions.length; i++) {
        final question = quizQuestions[i];
        print('\n❓ Quiz Question ${i + 1}:');
        print('   Q: ${question.question}');
        print('   Options: ${question.options.join(', ')}');
        print('   Correct: ${question.correctAnswer}');
        print('   Difficulty: ${question.difficulty.name}');
        print('   Type: ${question.type.name}');
      }
    } else {
      print('❌ No quiz questions generated!');
    }

    // Test error conditions
    print('\n🔍 Testing error conditions...');

    // Test with empty content
    final emptyFlashcards = await localAI.generateFlashcards(
      '',
      count: 1,
      targetDifficulty: DifficultyLevel.beginner,
    );
    print('   - Empty content flashcards: ${emptyFlashcards.length}');

    // Test with very short content
    final shortFlashcards = await localAI.generateFlashcards(
      'AI',
      count: 1,
      targetDifficulty: DifficultyLevel.beginner,
    );
    print('   - Short content flashcards: ${shortFlashcards.length}');
  } catch (e, stackTrace) {
    print('❌ LocalAIFallbackService test failed: $e');
    print('Stack trace: $stackTrace');
  }
}
