import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:mindload/services/advanced_flashcard_validator.dart';
import 'package:uuid/uuid.dart';

/// Advanced Flashcard & Quiz Generator for the Mindload app
///
/// Converts provided CONTENT into inquisitive flashcards and quizzes that emphasize
/// why/how/what-if, real-world application, and cross-concept connections.
///
/// Features:
/// - Bloom's Taxonomy integration with difficulty scaling
/// - Schema validation and error handling
/// - Anchoring system for spaced repetition
/// - Advanced question type distribution
/// - Real-world scenario emphasis
class AdvancedFlashcardGenerator {
  static final AdvancedFlashcardGenerator _instance =
      AdvancedFlashcardGenerator._internal();
  static AdvancedFlashcardGenerator get instance => _instance;
  AdvancedFlashcardGenerator._internal();

  final _uuid = const Uuid();
  final _random = math.Random();

  // Difficulty to Bloom's mix mapping
  static const Map<int, Map<String, double>> _difficultyBloomMix = {
    1: {
      'Understand': 0.50,
      'Apply': 0.35,
      'Analyze': 0.10,
      'Evaluate': 0.05,
      'Create': 0.00
    },
    2: {
      'Understand': 0.35,
      'Apply': 0.40,
      'Analyze': 0.20,
      'Evaluate': 0.05,
      'Create': 0.00
    },
    3: {
      'Understand': 0.25,
      'Apply': 0.40,
      'Analyze': 0.25,
      'Evaluate': 0.10,
      'Create': 0.00
    },
    4: {
      'Understand': 0.15,
      'Apply': 0.35,
      'Analyze': 0.35,
      'Evaluate': 0.15,
      'Create': 0.00
    },
    5: {
      'Understand': 0.10,
      'Apply': 0.30,
      'Analyze': 0.35,
      'Evaluate': 0.20,
      'Create': 0.05
    },
    6: {
      'Understand': 0.05,
      'Apply': 0.25,
      'Analyze': 0.35,
      'Evaluate': 0.25,
      'Create': 0.10
    },
    7: {
      'Understand': 0.00,
      'Apply': 0.15,
      'Analyze': 0.35,
      'Evaluate': 0.30,
      'Create': 0.20
    },
  };

  /// Generate advanced flashcard set with comprehensive schema
  Future<Map<String, dynamic>> generateAdvancedFlashcardSet({
    required String content,
    required String setTitle,
    required int cardCount,
    required String audience, // beginner, intermediate, advanced, PhD
    required String priorKnowledge, // low, medium, high
    required int difficulty, // 1-7
    List<String> focusAnchors = const [],
    List<String> excludeTopics = const [],
    Map<String, double>? customBloomMix,
    double scenarioPercentage = 0.3,
    double maxRecallPercentage = 0.15,
  }) async {
    try {
      debugPrint('🧠 Starting advanced flashcard generation...');
      debugPrint('📚 Content length: ${content.length} chars');
      debugPrint('🎯 Target cards: $cardCount');
      debugPrint('👥 Audience: $audience');
      debugPrint('🔢 Difficulty: $difficulty');

      // Validate input
      if (content.trim().isEmpty) {
        throw ArgumentError('Content cannot be empty');
      }
      if (cardCount <= 0) {
        throw ArgumentError('Card count must be positive');
      }
      if (difficulty < 1 || difficulty > 7) {
        throw ArgumentError('Difficulty must be between 1 and 7');
      }

      // Get Bloom's mix
      final bloomMix = customBloomMix ?? _difficultyBloomMix[difficulty]!;

      // Extract content analysis
      final contentAnalysis =
          await _analyzeContent(content, focusAnchors, excludeTopics);

      // Generate cards based on difficulty and Bloom's taxonomy
      final cards = await _generateCards(
        content: content,
        analysis: contentAnalysis,
        cardCount: cardCount,
        difficulty: difficulty,
        bloomMix: bloomMix,
        audience: audience,
        scenarioPercentage: scenarioPercentage,
        maxRecallPercentage: maxRecallPercentage,
      );

      // Create quiz configuration
      final quiz = _createQuizConfig(cardCount, difficulty);

      // Build final schema
      final result = {
        'set_title': setTitle,
        'source_summary': _generateSourceSummary(contentAnalysis),
        'tags': contentAnalysis['tags'],
        'difficulty': difficulty,
        'bloom_mix': bloomMix,
        'cards': cards,
        'quiz': quiz,
      };

      // Validate and sanitize schema before returning
      final sanitizedResult =
          AdvancedFlashcardValidator.instance.sanitizeSchema(result);
      final validation = AdvancedFlashcardValidator.instance
          .validateGenerationSchema(sanitizedResult);

      if (!validation.isValid) {
        debugPrint(
            '❌ Schema validation failed: ${validation.errors.join(', ')}');
        throw ArgumentError(
            'Generated schema is invalid: ${validation.errors.first}');
      }

      if (validation.warnings.isNotEmpty) {
        debugPrint(
            '⚠️ Schema validation warnings: ${validation.warnings.join(', ')}');
      }

      debugPrint('✅ Generated ${cards.length} cards successfully');
      debugPrint('📊 Validation: ${validation.summary}');
      return sanitizedResult;
    } catch (e, stackTrace) {
      debugPrint('❌ Advanced flashcard generation failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Analyze content to extract key concepts, topics, and structure
  Future<Map<String, dynamic>> _analyzeContent(String content,
      List<String> focusAnchors, List<String> excludeTopics) async {
    final words = content.toLowerCase().split(RegExp(r'\W+'));
    final sentences = content.split(RegExp(r'[.!?]+'));

    // Extract key topics using frequency analysis and focus anchors
    final keyTopics = <String>[];
    final concepts = <String>[];
    final facts = <String>[];
    final tags = <String>[];

    // Process focus anchors first
    for (final anchor in focusAnchors) {
      if (content.toLowerCase().contains(anchor.toLowerCase())) {
        keyTopics.add(anchor);
        tags.add(anchor.toLowerCase().replaceAll(' ', '_'));
      }
    }

    // Extract additional concepts from content
    final wordFreq = <String, int>{};
    for (final word in words) {
      if (word.length > 3 && !_isStopWord(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    // Get top concepts by frequency
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    concepts.addAll(sortedWords.take(10).map((e) => e.key));

    // Extract facts (sentences with specific patterns)
    for (final sentence in sentences) {
      if (sentence.trim().length > 20 &&
          (sentence.contains('is') ||
              sentence.contains('are') ||
              sentence.contains('because') ||
              sentence.contains('when'))) {
        facts.add(sentence.trim());
      }
    }

    // Generate tags from content
    tags.addAll(['study_material', 'generated_content']);
    if (content.length > 1000) tags.add('comprehensive');
    if (content.contains(RegExp(r'\d+'))) tags.add('data_driven');

    return {
      'keyTopics': keyTopics.take(8).toList(),
      'concepts': concepts.take(15).toList(),
      'facts': facts.take(10).toList(),
      'tags': tags.take(5).toList(),
      'wordCount': words.length,
      'sentenceCount': sentences.length,
    };
  }

  /// Generate cards based on Bloom's taxonomy and difficulty
  Future<List<Map<String, dynamic>>> _generateCards({
    required String content,
    required Map<String, dynamic> analysis,
    required int cardCount,
    required int difficulty,
    required Map<String, double> bloomMix,
    required String audience,
    required double scenarioPercentage,
    required double maxRecallPercentage,
  }) async {
    final cards = <Map<String, dynamic>>[];
    final keyTopics = List<String>.from(analysis['keyTopics']);
    final concepts = List<String>.from(analysis['concepts']);
    final facts = List<String>.from(analysis['facts']);

    // Calculate card distribution by Bloom level
    final distribution = _calculateCardDistribution(cardCount, bloomMix);

    int cardIndex = 0;
    int scenarioCount = 0;
    int recallCount = 0;
    final maxScenarios = (cardCount * scenarioPercentage).ceil();
    final maxRecall = (cardCount * maxRecallPercentage).ceil();

    // Generate cards for each Bloom level
    for (final entry in distribution.entries) {
      final bloomLevel = entry.key;
      final count = entry.value;

      for (int i = 0; i < count && cardIndex < cardCount; i++) {
        final isScenario =
            scenarioCount < maxScenarios && _random.nextDouble() < 0.6;
        final isRecall = recallCount < maxRecall &&
            bloomLevel == 'Understand' &&
            _random.nextDouble() < 0.3;

        if (isRecall) recallCount++;
        if (isScenario) scenarioCount++;

        final card = await _generateSingleCard(
          content: content,
          keyTopics: keyTopics,
          concepts: concepts,
          facts: facts,
          bloomLevel: bloomLevel,
          difficulty: difficulty,
          audience: audience,
          isScenario: isScenario,
          isRecall: isRecall,
          cardId: 'card_${_uuid.v4()}',
        );

        if (card != null) {
          cards.add(card);
          cardIndex++;
        }
      }
    }

    // Fill remaining slots if needed
    while (cards.length < cardCount) {
      final bloomLevel = _getRandomBloomLevel(bloomMix);
      final card = await _generateSingleCard(
        content: content,
        keyTopics: keyTopics,
        concepts: concepts,
        facts: facts,
        bloomLevel: bloomLevel,
        difficulty: difficulty,
        audience: audience,
        isScenario: scenarioCount < maxScenarios,
        isRecall: false,
        cardId: 'card_${_uuid.v4()}',
      );

      if (card != null) {
        cards.add(card);
        if (card['type'] == 'scenario') scenarioCount++;
      }
    }

    return cards.take(cardCount).toList();
  }

  /// Generate a single card based on parameters
  Future<Map<String, dynamic>?> _generateSingleCard({
    required String content,
    required List<String> keyTopics,
    required List<String> concepts,
    required List<String> facts,
    required String bloomLevel,
    required int difficulty,
    required String audience,
    required bool isScenario,
    required bool isRecall,
    required String cardId,
  }) async {
    try {
      // Select question type based on Bloom level and constraints
      final questionType = _selectQuestionType(bloomLevel, isScenario);
      final cardDifficulty = _mapDifficultyToString(difficulty);

      // Generate content based on type and level
      final questionData = _generateQuestionContent(
        bloomLevel: bloomLevel,
        questionType: questionType,
        keyTopics: keyTopics,
        concepts: concepts,
        facts: facts,
        isScenario: isScenario,
        isRecall: isRecall,
        difficulty: difficulty,
        audience: audience,
      );

      if (questionData == null) return null;

      // Create anchors from relevant concepts
      final anchors =
          _generateAnchors(keyTopics, concepts, questionData['question']);

      return {
        'id': cardId,
        'type': questionType,
        'bloom': bloomLevel,
        'difficulty': cardDifficulty,
        'question': questionData['question'],
        'choices': questionType == 'qa' ? [] : questionData['choices'],
        'correct_index':
            questionType == 'qa' ? 0 : questionData['correct_index'],
        'answer_explanation': questionData['explanation'],
        'hint': questionData['hint'],
        'anchors': anchors,
        'source_span': 'Generated from content analysis',
      };
    } catch (e) {
      debugPrint('❌ Failed to generate card: $e');
      return null;
    }
  }

  /// Generate question content based on Bloom level and parameters
  Map<String, dynamic>? _generateQuestionContent({
    required String bloomLevel,
    required String questionType,
    required List<String> keyTopics,
    required List<String> concepts,
    required List<String> facts,
    required bool isScenario,
    required bool isRecall,
    required int difficulty,
    required String audience,
  }) {
    if (keyTopics.isEmpty && concepts.isEmpty) return null;

    final topic = keyTopics.isNotEmpty
        ? keyTopics[_random.nextInt(keyTopics.length)]
        : concepts[_random.nextInt(concepts.length)];
    final concept = concepts.isNotEmpty
        ? concepts[_random.nextInt(concepts.length)]
        : topic;

    switch (bloomLevel) {
      case 'Understand':
        return _generateUnderstandQuestion(
            topic, concept, questionType, isRecall, difficulty);
      case 'Apply':
        return _generateApplyQuestion(
            topic, concept, questionType, isScenario, difficulty);
      case 'Analyze':
        return _generateAnalyzeQuestion(
            topic, concept, questionType, isScenario, difficulty);
      case 'Evaluate':
        return _generateEvaluateQuestion(
            topic, concept, questionType, isScenario, difficulty);
      case 'Create':
        return _generateCreateQuestion(
            topic, concept, questionType, isScenario, difficulty);
      default:
        return _generateUnderstandQuestion(
            topic, concept, questionType, isRecall, difficulty);
    }
  }

  /// Generate Understand-level questions
  Map<String, dynamic> _generateUnderstandQuestion(String topic, String concept,
      String questionType, bool isRecall, int difficulty) {
    if (isRecall) {
      return {
        'question': 'What is the key characteristic of $topic?',
        'choices': [
          'Primary defining feature',
          'Secondary attribute',
          'Related concept',
          'Unrelated factor'
        ],
        'correct_index': 0,
        'explanation':
            'The primary defining feature best captures the essential nature of $topic.',
        'hint': 'Focus on the most fundamental aspect.',
      };
    }

    final scenarios = [
      {
        'question':
            'In what situation would understanding $topic be most critical?',
        'choices': [
          'When making strategic decisions',
          'During routine operations',
          'In emergency situations',
          'For documentation purposes'
        ],
        'correct_index': 0,
        'explanation':
            'Understanding $topic is most critical when making strategic decisions as it affects long-term outcomes.',
        'hint': 'Think about when deep comprehension matters most.',
      },
      {
        'question':
            'How does $topic relate to $concept in practical applications?',
        'choices': [
          'They work together synergistically',
          'They operate independently',
          'They often conflict',
          'They are mutually exclusive'
        ],
        'correct_index': 0,
        'explanation':
            '$topic and $concept typically work together synergistically in real-world applications.',
        'hint': 'Consider how these elements complement each other.',
      },
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Generate Apply-level questions
  Map<String, dynamic> _generateApplyQuestion(String topic, String concept,
      String questionType, bool isScenario, int difficulty) {
    final scenarios = [
      {
        'question':
            'If you needed to implement $topic in a new context, what would be your first step?',
        'choices': [
          'Analyze the specific requirements',
          'Copy existing implementations',
          'Start with basic features',
          'Consult with experts'
        ],
        'correct_index': 0,
        'explanation':
            'Analyzing specific requirements ensures the implementation of $topic fits the new context properly.',
        'hint': 'Think about what information you need first.',
      },
      {
        'question':
            'When applying $topic to solve problems involving $concept, which approach works best?',
        'choices': [
          'Systematic methodology',
          'Trial and error',
          'Intuitive approach',
          'Standard procedures'
        ],
        'correct_index': 0,
        'explanation':
            'A systematic methodology ensures consistent and effective application of $topic principles.',
        'hint': 'Consider which approach provides the most reliable results.',
      },
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Generate Analyze-level questions
  Map<String, dynamic> _generateAnalyzeQuestion(String topic, String concept,
      String questionType, bool isScenario, int difficulty) {
    final scenarios = [
      {
        'question':
            'What would be the most likely cause if $topic fails to work effectively with $concept?',
        'choices': [
          'Incompatible underlying assumptions',
          'Insufficient resources',
          'Poor timing',
          'External interference'
        ],
        'correct_index': 0,
        'explanation':
            'Incompatible underlying assumptions are often the root cause when $topic and $concept don\'t work well together.',
        'hint': 'Look for fundamental misalignments.',
      },
      {
        'question':
            'Which factor most significantly influences the relationship between $topic and $concept?',
        'choices': [
          'Contextual variables',
          'Historical precedent',
          'Resource availability',
          'Individual preferences'
        ],
        'correct_index': 0,
        'explanation':
            'Contextual variables most significantly influence how $topic and $concept interact in different situations.',
        'hint': 'Think about what changes the dynamics between these elements.',
      },
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Generate Evaluate-level questions
  Map<String, dynamic> _generateEvaluateQuestion(String topic, String concept,
      String questionType, bool isScenario, int difficulty) {
    final scenarios = [
      {
        'question':
            'What criteria would best determine the effectiveness of $topic in addressing $concept?',
        'choices': [
          'Measurable outcomes and long-term impact',
          'Immediate visible results',
          'Stakeholder satisfaction',
          'Cost-effectiveness alone'
        ],
        'correct_index': 0,
        'explanation':
            'Measurable outcomes and long-term impact provide the most comprehensive evaluation of effectiveness.',
        'hint': 'Consider both quantifiable results and sustained benefits.',
      },
      {
        'question':
            'Which approach would you recommend for evaluating the trade-offs between $topic and $concept?',
        'choices': [
          'Multi-criteria decision analysis',
          'Simple cost-benefit comparison',
          'Stakeholder voting',
          'Historical precedent review'
        ],
        'correct_index': 0,
        'explanation':
            'Multi-criteria decision analysis provides a structured way to evaluate complex trade-offs objectively.',
        'hint': 'Think about systematic evaluation methods.',
      },
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Generate Create-level questions
  Map<String, dynamic> _generateCreateQuestion(String topic, String concept,
      String questionType, bool isScenario, int difficulty) {
    final scenarios = [
      {
        'question':
            'If you were to design a new approach that combines $topic with $concept, what would be the key innovation?',
        'choices': [
          'Synergistic integration framework',
          'Sequential implementation',
          'Parallel processing',
          'Hierarchical structure'
        ],
        'correct_index': 0,
        'explanation':
            'A synergistic integration framework would create the most value by leveraging the strengths of both elements.',
        'hint': 'Think about how to maximize the combined potential.',
      },
      {
        'question':
            'What novel solution could address the limitations of current $topic approaches?',
        'choices': [
          'Adaptive methodology',
          'Standardized process',
          'Technology upgrade',
          'Resource increase'
        ],
        'correct_index': 0,
        'explanation':
            'An adaptive methodology can dynamically adjust to overcome various limitations in different contexts.',
        'hint': 'Consider flexibility and responsiveness.',
      },
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Helper methods for card generation
  Map<String, int> _calculateCardDistribution(
      int cardCount, Map<String, double> bloomMix) {
    final distribution = <String, int>{};
    int remaining = cardCount;

    for (final entry in bloomMix.entries) {
      final count = (cardCount * entry.value).round();
      distribution[entry.key] = count;
      remaining -= count;
    }

    // Distribute remaining cards
    if (remaining > 0) {
      final levels = distribution.keys.toList();
      for (int i = 0; i < remaining; i++) {
        final level = levels[i % levels.length];
        distribution[level] = distribution[level]! + 1;
      }
    }

    return distribution;
  }

  String _selectQuestionType(String bloomLevel, bool isScenario) {
    final types = ['mcq', 'truefalse'];
    if (bloomLevel == 'Create' || bloomLevel == 'Evaluate') {
      types.add('qa');
    }
    return types[_random.nextInt(types.length)];
  }

  String _mapDifficultyToString(int difficulty) {
    if (difficulty <= 2) return 'easy';
    if (difficulty <= 5) return 'medium';
    return 'hard';
  }

  List<String> _generateAnchors(
      List<String> keyTopics, List<String> concepts, String question) {
    final anchors = <String>[];
    final questionLower = question.toLowerCase();

    // Add relevant topics and concepts
    for (final topic in keyTopics.take(2)) {
      if (questionLower.contains(topic.toLowerCase())) {
        anchors.add(topic);
      }
    }

    for (final concept in concepts.take(2)) {
      if (questionLower.contains(concept.toLowerCase()) &&
          !anchors.contains(concept)) {
        anchors.add(concept);
      }
    }

    // Ensure we have at least one anchor
    if (anchors.isEmpty && keyTopics.isNotEmpty) {
      anchors.add(keyTopics.first);
    }

    return anchors.take(3).toList();
  }

  String _getRandomBloomLevel(Map<String, double> bloomMix) {
    final random = _random.nextDouble();
    double cumulative = 0.0;

    for (final entry in bloomMix.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    return bloomMix.keys.first;
  }

  Map<String, dynamic> _createQuizConfig(int cardCount, int difficulty) {
    final numQuestions = math.min(10, cardCount);
    final timeLimit = _calculateTimeLimit(difficulty, numQuestions);
    final passThreshold = _calculatePassThreshold(difficulty);

    return {
      'num_questions': numQuestions,
      'mix': {'mcq': 0.7, 'qa': 0.2, 'truefalse': 0.1},
      'time_limit_seconds': timeLimit,
      'pass_threshold': passThreshold,
    };
  }

  int _calculateTimeLimit(int difficulty, int questions) {
    final baseTime = 60; // 60 seconds per question
    final difficultyMultiplier = 1.0 + (difficulty - 1) * 0.2;
    return (questions * baseTime * difficultyMultiplier).round();
  }

  double _calculatePassThreshold(int difficulty) {
    return math.max(0.5, math.min(0.9, 0.6 + (difficulty - 1) * 0.05));
  }

  String _generateSourceSummary(Map<String, dynamic> analysis) {
    final wordCount = analysis['wordCount'] as int;
    final topicCount = (analysis['keyTopics'] as List).length;
    final conceptCount = (analysis['concepts'] as List).length;

    return 'Content analysis: $wordCount words, $topicCount key topics, $conceptCount concepts identified. '
        'Generated using advanced Bloom\'s taxonomy-based methodology.';
  }

  bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'can',
      'this',
      'that',
      'these',
      'those'
    };
    return stopWords.contains(word.toLowerCase());
  }
}
