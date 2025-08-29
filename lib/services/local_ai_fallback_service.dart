import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:uuid/uuid.dart';

class LocalAIFallbackService {
  static final LocalAIFallbackService _instance =
      LocalAIFallbackService._internal();
  static LocalAIFallbackService get instance => _instance;
  LocalAIFallbackService._internal();

  final _uuid = Uuid();

  // Placeholder methods for content generation
  Future<List<Map<String, dynamic>>> _generateFlashcardsFromContent(
      String content, int count, String difficulty) async {
    // Simulate generating flashcards
    return List.generate(
        count,
        (index) => {
              'question': 'Sample Question ${index + 1}',
              'answer': 'Sample Answer ${index + 1}',
              'difficulty': difficulty,
              'questionType': 'multipleChoice'
            });
  }

  Future<List<Map<String, dynamic>>> _generateQuizQuestionsFromContent(
      String content, int count, String difficulty) async {
    // Simulate generating quiz questions
    return List.generate(
        count,
        (index) => {
              'question': 'Sample Quiz Question ${index + 1}',
              'options': ['Option A', 'Option B', 'Option C', 'Option D'],
              'correctAnswer': 'Option B',
              'difficulty': difficulty,
              'questionType': 'multipleChoice'
            });
  }

  // Map string to DifficultyLevel
  DifficultyLevel _mapStringToDifficultyLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  // Map string to QuestionType
  QuestionType _mapStringToQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'truefalse':
        return QuestionType.trueFalse;
      case 'shortanswer':
        return QuestionType.shortAnswer;
      case 'conceptualchallenge':
        return QuestionType.conceptualChallenge;
      default:
        return QuestionType.multipleChoice;
    }
  }

  // Generate flashcards
  Future<List<Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
    DifficultyLevel targetDifficulty = DifficultyLevel.intermediate,
  }) async {
    final parsedCards = await _generateFlashcardsFromContent(
        content, count, targetDifficulty.name.toLowerCase());

    return parsedCards.map((card) {
      final difficulty = _mapStringToDifficultyLevel(card['difficulty']);
      final questionType = _mapStringToQuestionType(card['questionType']);

      return Flashcard(
        id: _uuid.v4(),
        question: card['question'],
        answer: card['answer'],
        difficulty: difficulty,
        questionType: questionType,
      );
    }).toList();
  }

  // Generate quiz questions
  Future<List<QuizQuestion>> generateQuizQuestions(
    String content,
    int count,
    String difficulty, {
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    final parsedQuestions =
        await _generateQuizQuestionsFromContent(content, count, difficulty);

    return parsedQuestions.map((q) {
      final difficultyLevel = _mapStringToDifficultyLevel(q['difficulty']);
      final questionType = _mapStringToQuestionType(q['questionType']);

      return QuizQuestion(
        id: _uuid.v4(),
        question: q['question'],
        options: List<String>.from(q['options']),
        correctAnswer: q['correctAnswer'],
        difficulty: difficultyLevel,
        type: questionType,
      );
    }).toList();
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
        type: QuestionType.multipleChoice,
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
        type: QuestionType.multipleChoice,
      ));
    }

    return questions;
  }

  /// Parse difficulty string to enum
  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }
}
