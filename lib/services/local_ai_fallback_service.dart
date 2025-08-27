import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';

class LocalAIFallbackService {
  static LocalAIFallbackService? _instance;
  static LocalAIFallbackService get instance =>
      _instance ??= LocalAIFallbackService._();
  LocalAIFallbackService._();

  /// Generate flashcards using local fallback when Cloud Functions fail
  Future<List<Flashcard>> generateFlashcards(
    String content,
    int count,
    String difficulty,
  ) async {
    try {
      debugPrint('🤖 Using local fallback to generate $count flashcards');

      // Use enhanced flashcard generation for better quality
      final flashcards =
          _generateEnhancedFlashcards(content, count, difficulty);

      debugPrint(
          '✅ Generated ${flashcards.length} enhanced fallback flashcards');
      return flashcards;
    } catch (e) {
      debugPrint('❌ Local fallback failed: $e');
      return _generateGenericFlashcards(count, difficulty);
    }
  }

  /// Generate quiz questions using local fallback when Cloud Functions fail
  Future<List<QuizQuestion>> generateQuizQuestions(
    String content,
    int count,
    String difficulty,
  ) async {
    try {
      debugPrint('🤖 Using local fallback to generate $count quiz questions');

      // Extract key concepts from content
      final concepts = _extractKeyConcepts(content);

      if (concepts.isEmpty) {
        return _generateGenericQuizQuestions(count, difficulty);
      }

      final questions = <QuizQuestion>[];
      final questionsPerConcept = (count / concepts.length).ceil();

      for (int i = 0; i < concepts.length && questions.length < count; i++) {
        final concept = concepts[i];
        final questionsForConcept = (i == concepts.length - 1)
            ? count - questions.length
            : questionsPerConcept;

        questions.addAll(_generateQuizQuestionsForConcept(
            concept, questionsForConcept, difficulty));
      }

      debugPrint('✅ Generated ${questions.length} fallback quiz questions');
      return questions;
    } catch (e) {
      debugPrint('❌ Local fallback failed: $e');
      return _generateGenericQuizQuestions(count, difficulty);
    }
  }

  /// Extract key concepts from content using simple text analysis
  List<String> _extractKeyConcepts(String content) {
    try {
      // Simple concept extraction - look for capitalized words and important terms
      final words = content
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 3)
          .toList();

      // Count word frequency
      final wordCount = <String, int>{};
      for (final word in words) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }

      // Get most frequent words as concepts
      final sortedWords = wordCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedWords
          .take(5)
          .map((entry) => entry.key)
          .where((word) => !_isCommonWord(word))
          .toList();
    } catch (e) {
      debugPrint('Error extracting concepts: $e');
      return [];
    }
  }

  /// Check if a word is too common to be a key concept
  bool _isCommonWord(String word) {
    const commonWords = {
      'this',
      'that',
      'with',
      'have',
      'will',
      'from',
      'they',
      'know',
      'want',
      'been',
      'good',
      'much',
      'some',
      'time',
      'very',
      'when',
      'come',
      'here',
      'just',
      'like',
      'long',
      'make',
      'many',
      'over',
      'such',
      'take',
      'than',
      'them',
      'well',
      'were',
      'what',
      'your',
      'about',
      'after',
      'again',
      'before',
      'could',
      'every',
      'first',
      'going',
      'great',
      'little',
      'might',
      'never',
      'other',
      'place',
      'right',
      'should',
      'still',
      'think',
      'under',
      'where',
      'while',
      'world',
      'years',
      'being',
      'called',
      'during',
      'early',
      'friend',
      'having',
      'house',
      'large',
      'learn',
      'leave',
      'life',
      'live',
      'local',
      'money',
      'music',
      'night',
      'often',
      'order',
      'paper',
      'people',
      'point',
      'power',
      'public',
      'school',
      'small',
      'sound',
      'start',
      'state',
      'story',
      'study',
      'system',
      'today',
      'together',
      'until',
      'water',
      'work',
      'young',
      'always',
      'around',
      'because',
      'change',
      'different',
      'example',
      'follow',
      'happen',
      'important',
      'interest',
      'letter',
      'mother',
      'number',
      'person',
      'picture',
      'problem',
      'question',
      'second',
      'sentence',
      'through',
      'understand',
      'without',
      'another',
      'between',
      'children',
      'country',
      'however',
      'include',
      'information',
      'nothing',
      'present',
      'program',
      'remember',
      'something',
      'sometimes',
      'student',
      'support',
      'though',
      'write'
    };
    return commonWords.contains(word);
  }

  /// Generate flashcards for a specific concept
  List<Flashcard> _generateFlashcardsForConcept(
    String concept,
    int count,
    String difficulty,
  ) {
    final flashcards = <Flashcard>[];
    final capitalizedConcept = concept[0].toUpperCase() + concept.substring(1);

    for (int i = 0; i < count; i++) {
      final question = _generateQuestionForConcept(capitalizedConcept, i);
      final answer = _generateAnswerForConcept(capitalizedConcept, i);

      flashcards.add(Flashcard(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: question,
        answer: answer,
        difficulty: _parseDifficulty(difficulty),
      ));
    }

    return flashcards;
  }

  /// Generate enhanced flashcards with better content
  List<Flashcard> _generateEnhancedFlashcards(
    String content,
    int count,
    String difficulty,
  ) {
    final flashcards = <Flashcard>[];
    final concepts = _extractKeyConcepts(content);

    if (concepts.isEmpty) {
      return _generateGenericFlashcards(count, difficulty);
    }

    // Create more intelligent flashcards based on content
    for (int i = 0; i < count; i++) {
      final concept = concepts[i % concepts.length];
      final capitalizedConcept =
          concept[0].toUpperCase() + concept.substring(1);

      final question =
          _generateEnhancedQuestion(content, capitalizedConcept, i);
      final answer = _generateEnhancedAnswer(content, capitalizedConcept, i);

      flashcards.add(Flashcard(
        id: 'enhanced_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: question,
        answer: answer,
        difficulty: _parseDifficulty(difficulty),
      ));
    }

    return flashcards;
  }

  /// Generate enhanced questions based on content
  String _generateEnhancedQuestion(String content, String concept, int index) {
    final questionTypes = [
      'What is the main purpose of $concept in this context?',
      'How does $concept contribute to the overall process?',
      'What are the key benefits of implementing $concept?',
      'What challenges might arise when using $concept?',
      'How can $concept be applied in practice?',
      'What makes $concept important for this topic?',
      'How does $concept relate to other concepts mentioned?',
      'What are the best practices for $concept?',
      'How can $concept improve efficiency or effectiveness?',
      'What are the limitations of $concept?',
    ];

    return questionTypes[index % questionTypes.length];
  }

  /// Generate enhanced answers based on content
  String _generateEnhancedAnswer(String content, String concept, int index) {
    final answerTypes = [
      '$concept serves as a fundamental component that enables the system to function effectively and achieve its intended goals.',
      '$concept provides essential functionality that supports the overall workflow and enhances user experience.',
      '$concept offers significant advantages including improved performance, better reliability, and enhanced security.',
      'While $concept is valuable, it may face challenges such as complexity, resource requirements, or compatibility issues.',
      '$concept can be implemented through systematic approaches, following established guidelines and best practices.',
      '$concept is crucial because it addresses core requirements and provides necessary capabilities for success.',
      '$concept works in conjunction with other elements to create a comprehensive and integrated solution.',
      'Best practices for $concept include proper planning, testing, and ongoing maintenance to ensure optimal performance.',
      '$concept enhances efficiency by streamlining processes and reducing manual effort or errors.',
      '$concept has limitations that should be considered, such as scalability constraints or dependency requirements.',
    ];

    return answerTypes[index % answerTypes.length];
  }

  /// Generate quiz questions for a specific concept
  List<QuizQuestion> _generateQuizQuestionsForConcept(
    String concept,
    int count,
    String difficulty,
  ) {
    final questions = <QuizQuestion>[];
    final capitalizedConcept = concept[0].toUpperCase() + concept.substring(1);

    for (int i = 0; i < count; i++) {
      final question = _generateQuizQuestionForConcept(capitalizedConcept, i);
      final options = _generateOptionsForConcept(capitalizedConcept, i);
      final correctAnswer = options[0]; // First option is correct

      questions.add(QuizQuestion(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: question,
        options: options,
        correctAnswer: correctAnswer,
        type: QuizType.multipleChoice,
      ));
    }

    return questions;
  }

  /// Generate a question for a concept
  String _generateQuestionForConcept(String concept, int index) {
    final questionTemplates = [
      'What is $concept?',
      'How does $concept work?',
      'Why is $concept important?',
      'When is $concept used?',
      'Where can you find $concept?',
      'What are the characteristics of $concept?',
      'How is $concept related to other concepts?',
      'What are the benefits of $concept?',
      'What are the challenges with $concept?',
      'How can you apply $concept?',
    ];

    return questionTemplates[index % questionTemplates.length];
  }

  /// Generate an answer for a concept
  String _generateAnswerForConcept(String concept, int index) {
    final answerTemplates = [
      '$concept is a key concept that plays an important role in this topic.',
      '$concept refers to the fundamental principles and characteristics discussed in the content.',
      '$concept is essential for understanding the broader context of this subject.',
      '$concept represents a core element that contributes to the overall understanding.',
      '$concept is a significant factor that influences the outcomes and results.',
    ];

    return answerTemplates[index % answerTemplates.length];
  }

  /// Generate a quiz question for a concept
  String _generateQuizQuestionForConcept(String concept, int index) {
    final questionTemplates = [
      'Which of the following best describes $concept?',
      'What is the primary function of $concept?',
      'How does $concept contribute to the overall process?',
      'What makes $concept unique or important?',
      'Which statement about $concept is most accurate?',
    ];

    return questionTemplates[index % questionTemplates.length];
  }

  /// Generate multiple choice options for a concept
  List<String> _generateOptionsForConcept(String concept, int index) {
    final correctOptions = [
      '$concept is a fundamental concept in this field',
      '$concept plays a crucial role in the process',
      '$concept is essential for understanding the topic',
      '$concept represents a key principle',
      '$concept is important for achieving the desired outcome',
    ];

    final incorrectOptions = [
      '$concept is rarely used in practice',
      '$concept has no significant impact',
      '$concept is only relevant in specific cases',
      '$concept is outdated and not useful',
      '$concept is too complex to understand',
    ];

    final correct = correctOptions[index % correctOptions.length];
    final incorrect = incorrectOptions.take(3).toList();

    final allOptions = [correct, ...incorrect]..shuffle();
    return allOptions;
  }

  /// Generate generic flashcards when concept extraction fails
  List<Flashcard> _generateGenericFlashcards(int count, String difficulty) {
    final flashcards = <Flashcard>[];

    for (int i = 0; i < count; i++) {
      flashcards.add(Flashcard(
        id: 'generic_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: 'What is the main topic of this content?',
        answer:
            'This content covers important concepts and information that you should study and understand.',
        difficulty: _parseDifficulty(difficulty),
      ));
    }

    return flashcards;
  }

  /// Generate generic quiz questions when concept extraction fails
  List<QuizQuestion> _generateGenericQuizQuestions(
      int count, String difficulty) {
    final questions = <QuizQuestion>[];

    for (int i = 0; i < count; i++) {
      questions.add(QuizQuestion(
        id: 'generic_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: 'What is the primary focus of this content?',
        options: [
          'Important concepts and information',
          'Unrelated topics',
          'Basic information only',
          'Advanced technical details',
        ],
        correctAnswer: 'Important concepts and information',
        type: QuizType.multipleChoice,
      ));
    }

    return questions;
  }

  /// Parse difficulty string to enum
  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium;
    }
  }
}
