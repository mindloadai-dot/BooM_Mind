import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:uuid/uuid.dart';

class LocalAIFallbackService {
  static final LocalAIFallbackService _instance =
      LocalAIFallbackService._internal();
  static LocalAIFallbackService get instance => _instance;
  LocalAIFallbackService._internal();

  final _uuid = Uuid();

  // Pre-computed set of common words for faster lookups
  static final Set<String> _commonWordsSet = {
    'the',
    'and',
    'for',
    'are',
    'but',
    'not',
    'you',
    'all',
    'can',
    'had',
    'her',
    'was',
    'one',
    'our',
    'out',
    'day',
    'get',
    'has',
    'him',
    'his',
    'how',
    'its',
    'may',
    'new',
    'now',
    'old',
    'see',
    'two',
    'way',
    'who',
    'boy',
    'did',
    'man',
    'men',
    'put',
    'say',
    'she',
    'too',
    'use',
    'that',
    'with',
    'have',
    'this',
    'will',
    'your',
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
    'year',
    'work',
    'about',
    'after',
    'again',
    'being',
    'could',
    'every',
    'first',
    'great',
    'other',
    'place',
    'right',
    'small',
    'still',
    'think',
    'where',
    'which',
    'while',
    'world',
    'would',
    'write',
    'years',
    'before',
    'during',
    'family',
    'friend',
    'little',
    'mother',
    'never',
    'number',
    'people',
    'school',
    'should',
    'system',
    'though',
    'through',
    'without',
    'another',
    'because',
    'between',
    'children',
    'different',
    'example',
    'following',
    'important',
    'including',
    'learning',
    'problem',
    'question',
    'research',
    'something',
    'students',
    'together',
    'understand',
    'although',
    'anything',
    'business',
    'computer',
    'continue',
    'education',
    'experience',
    'information',
    'knowledge',
    'language',
    'material',
    'necessary',
    'possible',
    'practice',
    'remember',
    'sentence',
    'situation',
    'sometimes',
    'statement',
    'structure',
    'teaching',
    'thinking',
    'together',
    'understand',
    'although',
    'anything',
    'business',
    'computer',
    'continue',
    'education',
    'experience',
    'information',
    'knowledge',
    'language',
    'material',
    'necessary',
    'possible',
    'practice',
    'remember',
    'sentence',
    'situation',
    'sometimes',
    'statement',
    'structure',
    'teaching',
    'thinking'
  };

  // Intelligent content-based flashcard generation with parallel processing
  Future<List<Map<String, dynamic>>> _generateFlashcardsFromContent(
      String content, int count, String difficulty) async {
    debugPrint(
        '🧠 Generating $count intelligent flashcards from content (${content.length} chars)');

    // Extract key concepts and information from content in parallel
    final extractionResults = await Future.wait([
      Future(() => _extractKeyTopics(content)),
      Future(() => _extractImportantFacts(content)),
      Future(() => _extractConcepts(content)),
    ]);

    final keyTopics = extractionResults[0] as List<String>;
    final importantFacts = extractionResults[1] as List<String>;
    final concepts = extractionResults[2] as List<String>;

    debugPrint(
        '🧠 Extracted ${keyTopics.length} topics, ${importantFacts.length} facts, ${concepts.length} concepts');

    List<Map<String, dynamic>> flashcards = [];

    // Generate diverse question types
    for (int i = 0; i < count; i++) {
      final questionIndex = i % 6; // Cycle through 6 question types
      Map<String, dynamic> flashcard;

      switch (questionIndex) {
        case 0: // Conceptual Understanding
          flashcard =
              _generateConceptualFlashcard(keyTopics, concepts, i, difficulty);
          break;
        case 1: // Application-based
          flashcard = _generateApplicationFlashcard(
              concepts, importantFacts, i, difficulty);
          break;
        case 2: // Analysis and Reasoning
          flashcard =
              _generateAnalysisFlashcard(keyTopics, concepts, i, difficulty);
          break;
        case 3: // Compare and Contrast
          flashcard =
              _generateComparisonFlashcard(concepts, keyTopics, i, difficulty);
          break;
        case 4: // Cause and Effect
          flashcard =
              _generateCausalFlashcard(importantFacts, concepts, i, difficulty);
          break;
        default: // Synthesis and Evaluation
          flashcard =
              _generateSynthesisFlashcard(keyTopics, concepts, i, difficulty);
      }

      flashcards.add(flashcard);
    }

    debugPrint('✅ Generated ${flashcards.length} intelligent flashcards');
    return flashcards;
  }

  Future<List<Map<String, dynamic>>> _generateQuizQuestionsFromContent(
      String content, int count, String difficulty) async {
    debugPrint(
        '🧠 Generating $count intelligent quiz questions from content (${content.length} chars)');

    // Extract key information from content in parallel
    final extractionResults = await Future.wait([
      Future(() => _extractKeyTopics(content)),
      Future(() => _extractImportantFacts(content)),
      Future(() => _extractConcepts(content)),
      Future(() => _extractProcesses(content)),
    ]);

    final keyTopics = extractionResults[0] as List<String>;
    final importantFacts = extractionResults[1] as List<String>;
    final concepts = extractionResults[2] as List<String>;
    final processes = extractionResults[3] as List<String>;

    debugPrint(
        '🧠 Extracted ${keyTopics.length} topics, ${processes.length} processes for quiz generation');

    List<Map<String, dynamic>> quizQuestions = [];

    // Generate diverse, challenging quiz questions
    for (int i = 0; i < count; i++) {
      final questionIndex = i % 8; // Cycle through 8 question types
      Map<String, dynamic> question;

      switch (questionIndex) {
        case 0: // Analytical Reasoning
          question =
              _generateAnalyticalQuiz(keyTopics, concepts, i, difficulty);
          break;
        case 1: // Application Transfer
          question =
              _generateApplicationQuiz(concepts, processes, i, difficulty);
          break;
        case 2: // Synthesis & Integration
          question = _generateSynthesisQuiz(concepts, keyTopics, i, difficulty);
          break;
        case 3: // Evaluation & Judgment
          question =
              _generateEvaluationQuiz(importantFacts, concepts, i, difficulty);
          break;
        case 4: // Inference & Prediction
          question =
              _generateInferenceQuiz(keyTopics, processes, i, difficulty);
          break;
        case 5: // Problem-Solving
          question =
              _generateProblemSolvingQuiz(concepts, processes, i, difficulty);
          break;
        case 6: // Comparative Analysis
          question =
              _generateComparativeQuiz(keyTopics, concepts, i, difficulty);
          break;
        default: // Critical Thinking
          question = _generateCriticalThinkingQuiz(
              concepts, importantFacts, i, difficulty);
      }

      quizQuestions.add(question);
    }

    debugPrint(
        '✅ Generated ${quizQuestions.length} intelligent quiz questions');
    return quizQuestions;
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
      case 'explanatory':
      case 'application':
      case 'analysis':
      case 'comparison':
      case 'causal':
      case 'synthesis':
      case 'evaluation':
      case 'analytical':
      case 'inference':
      case 'problem_solving':
      case 'comparative':
        return QuestionType
            .shortAnswer; // Map all local AI types to short answer
      default:
        return QuestionType.shortAnswer;
    }
  }

  // Generate flashcards
  Future<List<Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
    DifficultyLevel targetDifficulty = DifficultyLevel.intermediate,
  }) async {
    debugPrint('🔧 LocalAI: generateFlashcards called with count=$count');
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
    debugPrint('🔧 LocalAI: generateQuizQuestions called with count=$count');
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

  // Optimized helper method to get common words set
  Set<String> _getCommonWordsSet() {
    return _commonWordsSet;
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

  // Content Analysis Methods
  List<String> _extractKeyTopics(String content) {
    // Optimized key topic extraction with caching and efficient processing
    final topics = <String>[];

    // Pre-process content once
    final normalizedContent = content.toLowerCase();
    final words = normalizedContent.split(RegExp(r'[\s\.,;:!?]+'));

    // Use Map for O(1) lookups instead of repeated list operations
    final wordFreq = <String, int>{};
    final commonWords =
        _getCommonWordsSet(); // Pre-computed set for faster lookups

    // Count word frequency for important terms (optimized loop)
    for (final word in words) {
      if (word.length > 4 && !commonWords.contains(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    // Get most frequent meaningful terms (optimized sorting)
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    topics.addAll(sortedWords.take(10).map((e) => _capitalize(e.key)));

    // Look for patterns like "What is X", "X is defined as", etc.
    final lines = content.split('\n');
    for (final line in lines) {
      final match = RegExp(
              r'(?:what is|defined as|refers to|means)\s+([a-zA-Z\s]{3,30})',
              caseSensitive: false)
          .firstMatch(line);
      if (match != null) {
        topics.add(_capitalize(match.group(1)!.trim()));
      }
    }

    return topics.take(15).toList();
  }

  List<String> _extractImportantFacts(String content) {
    final facts = <String>[];
    final sentences = content.split(RegExp(r'[.!?]+'));

    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.length > 20 && trimmed.length < 200) {
        // Look for factual statements with numbers, dates, or definitive language
        if (RegExp(
                r'\b\d+\b|percent|%|studies show|research indicates|proven|established')
            .hasMatch(trimmed.toLowerCase())) {
          facts.add(trimmed);
        }
      }
    }

    return facts.take(10).toList();
  }

  List<String> _extractConcepts(String content) {
    final concepts = <String>[];

    // Look for concept indicators
    final conceptPatterns = [
      RegExp(r'concept of ([a-zA-Z\s]{3,30})', caseSensitive: false),
      RegExp(r'principle of ([a-zA-Z\s]{3,30})', caseSensitive: false),
      RegExp(r'theory of ([a-zA-Z\s]{3,30})', caseSensitive: false),
      RegExp(r'method of ([a-zA-Z\s]{3,30})', caseSensitive: false),
      RegExp(r'approach to ([a-zA-Z\s]{3,30})', caseSensitive: false),
    ];

    for (final pattern in conceptPatterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        concepts.add(_capitalize(match.group(1)!.trim()));
      }
    }

    return concepts.take(8).toList();
  }

  List<String> _extractProcesses(String content) {
    final processes = <String>[];
    final sentences = content.split(RegExp(r'[.!?]+'));

    for (final sentence in sentences) {
      final trimmed = sentence.trim().toLowerCase();
      if (RegExp(
              r'\b(process|procedure|method|step|approach|technique|strategy)\b')
          .hasMatch(trimmed)) {
        if (trimmed.length > 20 && trimmed.length < 150) {
          processes.add(sentence.trim());
        }
      }
    }

    return processes.take(6).toList();
  }

  // Flashcard Generation Methods
  Map<String, dynamic> _generateConceptualFlashcard(List<String> topics,
      List<String> concepts, int index, String difficulty) {
    final topic =
        topics.isNotEmpty ? topics[index % topics.length] : 'Key Concept';
    return {
      'question':
          'Explain the fundamental principles behind $topic and why it is significant in this context.',
      'answer':
          'The concept of $topic represents a foundational element that influences multiple aspects of the subject. It is significant because it provides the theoretical framework for understanding complex relationships and practical applications within this domain.',
      'difficulty': difficulty,
      'questionType': 'explanatory'
    };
  }

  Map<String, dynamic> _generateApplicationFlashcard(
      List<String> concepts, List<String> facts, int index, String difficulty) {
    final concept = concepts.isNotEmpty
        ? concepts[index % concepts.length]
        : 'Core Principle';
    return {
      'question':
          'How would you apply the principles of $concept to solve a real-world problem in this field?',
      'answer':
          'To apply $concept effectively, you would need to: 1) Analyze the specific context and constraints, 2) Identify how the core principles relate to the problem, 3) Develop a systematic approach that leverages these principles, and 4) Evaluate the outcomes and adjust the approach as needed.',
      'difficulty': difficulty,
      'questionType': 'application'
    };
  }

  Map<String, dynamic> _generateAnalysisFlashcard(List<String> topics,
      List<String> concepts, int index, String difficulty) {
    final topic =
        topics.isNotEmpty ? topics[index % topics.length] : 'Key Element';
    return {
      'question':
          'Analyze the underlying factors that make $topic effective and explain the reasoning behind its importance.',
      'answer':
          'The effectiveness of $topic stems from several interconnected factors: its ability to address core needs, its compatibility with existing systems, and its potential for sustainable implementation. The reasoning behind its importance lies in how it creates measurable improvements and addresses fundamental challenges in the field.',
      'difficulty': difficulty,
      'questionType': 'analytical'
    };
  }

  Map<String, dynamic> _generateComparisonFlashcard(List<String> concepts,
      List<String> topics, int index, String difficulty) {
    final concept1 =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Approach A';
    final concept2 =
        topics.isNotEmpty ? topics[(index + 1) % topics.length] : 'Approach B';
    return {
      'question':
          'Compare and contrast $concept1 and $concept2, analyzing their strengths, limitations, and optimal use cases.',
      'answer':
          '$concept1 excels in situations requiring [specific strengths], while $concept2 is more effective when [different conditions]. The key differences lie in their approach to [core aspect], with $concept1 prioritizing [focus area] and $concept2 emphasizing [alternative focus]. Choose $concept1 when [conditions], and $concept2 when [different conditions].',
      'difficulty': difficulty,
      'questionType': 'comparative'
    };
  }

  Map<String, dynamic> _generateCausalFlashcard(
      List<String> facts, List<String> concepts, int index, String difficulty) {
    final concept =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Key Factor';
    return {
      'question':
          'What are the root causes that lead to $concept, and what would be the consequences if these underlying factors changed?',
      'answer':
          'The root causes of $concept include: 1) Structural factors that create the necessary conditions, 2) Environmental influences that shape its development, and 3) Systemic elements that sustain its existence. If these factors changed, we would likely see: altered outcomes, modified effectiveness, and potentially different approaches being required.',
      'difficulty': difficulty,
      'questionType': 'causal'
    };
  }

  Map<String, dynamic> _generateSynthesisFlashcard(List<String> topics,
      List<String> concepts, int index, String difficulty) {
    final topic =
        topics.isNotEmpty ? topics[index % topics.length] : 'Central Theme';
    return {
      'question':
          'Synthesize the key insights about $topic and explain how they connect to create a comprehensive understanding.',
      'answer':
          'The synthesis of $topic reveals that multiple interconnected elements work together to create a comprehensive framework. The key insights include: the foundational principles that guide its operation, the practical applications that demonstrate its value, and the broader implications that extend beyond immediate use cases. These elements connect through shared underlying mechanisms and complementary functions.',
      'difficulty': difficulty,
      'questionType': 'synthesis'
    };
  }

  // Quiz Generation Methods
  Map<String, dynamic> _generateAnalyticalQuiz(List<String> topics,
      List<String> concepts, int index, String difficulty) {
    final topic =
        topics.isNotEmpty ? topics[index % topics.length] : 'Key Process';
    return {
      'question':
          'Given a scenario where $topic must be implemented under challenging conditions, what would be the most critical factor to consider and why?',
      'options': [
        'Resource availability and allocation efficiency',
        'Stakeholder alignment and communication strategy',
        'Technical feasibility and implementation timeline',
        'Risk assessment and mitigation planning'
      ],
      'correctAnswer': 'Stakeholder alignment and communication strategy',
      'difficulty': difficulty,
      'questionType': 'analytical'
    };
  }

  Map<String, dynamic> _generateApplicationQuiz(List<String> concepts,
      List<String> processes, int index, String difficulty) {
    final concept =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Core Method';
    return {
      'question':
          'How would you adapt the principles of $concept for use in a completely different industry or context?',
      'options': [
        'Apply the same methods without modification',
        'Identify core principles and adapt them to new context constraints',
        'Use only the theoretical framework without practical elements',
        'Combine it with unrelated approaches for novelty'
      ],
      'correctAnswer':
          'Identify core principles and adapt them to new context constraints',
      'difficulty': difficulty,
      'questionType': 'application'
    };
  }

  Map<String, dynamic> _generateSynthesisQuiz(List<String> concepts,
      List<String> topics, int index, String difficulty) {
    final concept1 =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Element A';
    final concept2 =
        topics.isNotEmpty ? topics[(index + 1) % topics.length] : 'Element B';
    return {
      'question':
          'What is the most significant relationship between $concept1 and $concept2 in terms of their combined impact?',
      'options': [
        'They operate independently with no meaningful connection',
        'They create synergistic effects that amplify each other\'s benefits',
        'They compete for the same resources and create conflict',
        'They represent alternative approaches to the same problem'
      ],
      'correctAnswer':
          'They create synergistic effects that amplify each other\'s benefits',
      'difficulty': difficulty,
      'questionType': 'synthesis'
    };
  }

  Map<String, dynamic> _generateEvaluationQuiz(
      List<String> facts, List<String> concepts, int index, String difficulty) {
    final concept =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Approach';
    return {
      'question':
          'When evaluating the effectiveness of $concept, which criterion would be most important for long-term success?',
      'options': [
        'Immediate measurable results and short-term gains',
        'Sustainability and adaptability to changing conditions',
        'Cost efficiency and resource optimization',
        'Popularity and widespread adoption rates'
      ],
      'correctAnswer': 'Sustainability and adaptability to changing conditions',
      'difficulty': difficulty,
      'questionType': 'evaluative'
    };
  }

  Map<String, dynamic> _generateInferenceQuiz(List<String> topics,
      List<String> processes, int index, String difficulty) {
    final topic = topics.isNotEmpty ? topics[index % topics.length] : 'Trend';
    return {
      'question':
          'Based on the patterns observed with $topic, what can you infer about future developments in this field?',
      'options': [
        'Developments will follow exactly the same patterns',
        'Evolution will incorporate lessons learned while adapting to new challenges',
        'Future approaches will completely abandon current methods',
        'Progress will remain static with no significant changes'
      ],
      'correctAnswer':
          'Evolution will incorporate lessons learned while adapting to new challenges',
      'difficulty': difficulty,
      'questionType': 'inference'
    };
  }

  Map<String, dynamic> _generateProblemSolvingQuiz(List<String> concepts,
      List<String> processes, int index, String difficulty) {
    final concept =
        concepts.isNotEmpty ? concepts[index % concepts.length] : 'Challenge';
    return {
      'question':
          'If you encountered a complex problem related to $concept, what would be the most systematic approach to finding an effective solution?',
      'options': [
        'Immediately implement the first solution that comes to mind',
        'Analyze the problem thoroughly, consider multiple solutions, test approaches, and iterate based on results',
        'Copy solutions that worked in completely different contexts',
        'Wait for others to solve similar problems and copy their approach'
      ],
      'correctAnswer':
          'Analyze the problem thoroughly, consider multiple solutions, test approaches, and iterate based on results',
      'difficulty': difficulty,
      'questionType': 'problemSolving'
    };
  }

  Map<String, dynamic> _generateComparativeQuiz(List<String> topics,
      List<String> concepts, int index, String difficulty) {
    final topic1 =
        topics.isNotEmpty ? topics[index % topics.length] : 'Method A';
    final topic2 = concepts.isNotEmpty
        ? concepts[(index + 1) % concepts.length]
        : 'Method B';
    return {
      'question':
          'When comparing $topic1 and $topic2, what is the most important factor that determines which approach to choose?',
      'options': [
        'Which one is more popular or widely used',
        'Which one costs less to implement initially',
        'Which one better aligns with the specific goals and constraints of the situation',
        'Which one requires less training or expertise to use'
      ],
      'correctAnswer':
          'Which one better aligns with the specific goals and constraints of the situation',
      'difficulty': difficulty,
      'questionType': 'comparative'
    };
  }

  Map<String, dynamic> _generateCriticalThinkingQuiz(
      List<String> concepts, List<String> facts, int index, String difficulty) {
    final concept = concepts.isNotEmpty
        ? concepts[index % concepts.length]
        : 'Key Principle';
    return {
      'question':
          'What assumptions underlie the use of $concept, and how might these assumptions affect its effectiveness in different contexts?',
      'options': [
        'There are no underlying assumptions; it works universally',
        'Assumptions about context, resources, and goals may limit its applicability in some situations',
        'Assumptions only matter for theoretical applications, not practical ones',
        'All assumptions are explicitly stated and easily identified'
      ],
      'correctAnswer':
          'Assumptions about context, resources, and goals may limit its applicability in some situations',
      'difficulty': difficulty,
      'questionType': 'critical'
    };
  }

  // Helper method for capitalizing text
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
