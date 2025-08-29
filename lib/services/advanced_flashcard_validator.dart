import 'package:flutter/foundation.dart';
import 'package:mindload/models/advanced_study_models.dart';

/// Validation service for advanced flashcard generation
///
/// Provides comprehensive validation for the new schema format,
/// ensuring data integrity and proper error handling.
class AdvancedFlashcardValidator {
  static final AdvancedFlashcardValidator _instance =
      AdvancedFlashcardValidator._internal();
  static AdvancedFlashcardValidator get instance => _instance;
  AdvancedFlashcardValidator._internal();

  /// Validate a complete generation schema
  ValidationResult validateGenerationSchema(Map<String, dynamic> schema) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Validate required top-level fields
      _validateRequiredFields(
          schema,
          [
            'set_title',
            'source_summary',
            'tags',
            'difficulty',
            'bloom_mix',
            'cards',
            'quiz'
          ],
          errors);

      // Validate set title
      if (schema.containsKey('set_title')) {
        final title = schema['set_title'] as String?;
        if (title == null || title.trim().isEmpty) {
          errors.add('Set title cannot be empty');
        } else if (title.length > 200) {
          errors.add('Set title too long (${title.length} chars, max 200)');
        }
      }

      // Validate difficulty
      if (schema.containsKey('difficulty')) {
        final difficulty = schema['difficulty'];
        if (difficulty is! int || difficulty < 1 || difficulty > 7) {
          errors.add('Difficulty must be an integer between 1 and 7');
        }
      }

      // Validate Bloom's mix
      if (schema.containsKey('bloom_mix')) {
        _validateBloomMix(schema['bloom_mix'], errors, warnings);
      }

      // Validate cards array
      if (schema.containsKey('cards')) {
        _validateCards(schema['cards'], errors, warnings);
      }

      // Validate quiz configuration
      if (schema.containsKey('quiz')) {
        _validateQuizConfig(schema['quiz'], errors, warnings);
      }

      // Validate tags
      if (schema.containsKey('tags')) {
        _validateTags(schema['tags'], errors, warnings);
      }
    } catch (e) {
      errors.add('Schema validation failed: ${e.toString()}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate an individual advanced flashcard
  ValidationResult validateAdvancedFlashcard(AdvancedFlashcard card) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Validate ID
      if (card.id.trim().isEmpty) {
        errors.add('Card ID cannot be empty');
      }

      // Validate question
      if (card.question.trim().isEmpty) {
        errors.add('Question cannot be empty');
      } else if (card.question.length > 180) {
        errors
            .add('Question too long (${card.question.length} chars, max 180)');
      }

      // Validate type-specific fields
      switch (card.type) {
        case 'mcq':
          _validateMCQCard(card, errors, warnings);
          break;
        case 'truefalse':
          _validateTrueFalseCard(card, errors, warnings);
          break;
        case 'qa':
          _validateQACard(card, errors, warnings);
          break;
        default:
          errors.add('Invalid card type: ${card.type}');
      }

      // Validate Bloom level
      if (!_isValidBloomLevel(card.bloom)) {
        errors.add('Invalid Bloom level: ${card.bloom}');
      }

      // Validate difficulty
      if (!['easy', 'medium', 'hard'].contains(card.difficulty)) {
        errors.add('Invalid difficulty: ${card.difficulty}');
      }

      // Validate explanation
      if (card.answerExplanation.trim().isEmpty) {
        errors.add('Answer explanation cannot be empty');
      } else if (card.answerExplanation.length > 500) {
        warnings.add(
            'Answer explanation is very long (${card.answerExplanation.length} chars)');
      }

      // Validate hint
      if (card.hint.trim().isEmpty) {
        warnings.add('Card has no hint provided');
      } else if (card.hint.length > 100) {
        warnings.add('Hint is quite long (${card.hint.length} chars)');
      }

      // Validate anchors
      if (card.anchors.isEmpty) {
        warnings.add('Card has no anchors for spaced repetition');
      } else if (card.anchors.length > 5) {
        warnings.add(
            'Card has many anchors (${card.anchors.length}), consider reducing');
      }

      // Check for anchor quality
      for (final anchor in card.anchors) {
        if (anchor.trim().isEmpty) {
          warnings.add('Empty anchor found');
        } else if (anchor.length < 2) {
          warnings.add('Very short anchor: "$anchor"');
        }
      }
    } catch (e) {
      errors.add('Card validation failed: ${e.toString()}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate an advanced study set
  ValidationResult validateAdvancedStudySet(AdvancedStudySet studySet) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Validate basic fields
      if (studySet.id.trim().isEmpty) {
        errors.add('Study set ID cannot be empty');
      }

      if (studySet.title.trim().isEmpty) {
        errors.add('Study set title cannot be empty');
      }

      if (studySet.content.trim().isEmpty) {
        errors.add('Study set content cannot be empty');
      }

      // Validate difficulty
      if (studySet.difficulty < 1 || studySet.difficulty > 7) {
        errors.add('Invalid difficulty: ${studySet.difficulty}');
      }

      // Validate cards
      if (studySet.cards.isEmpty) {
        warnings.add('Study set has no cards');
      } else {
        var cardErrors = 0;
        for (final card in studySet.cards) {
          final cardValidation = validateAdvancedFlashcard(card);
          if (!cardValidation.isValid) {
            cardErrors++;
          }
        }

        if (cardErrors > 0) {
          errors.add('$cardErrors cards have validation errors');
        }
      }

      // Validate Bloom's mix
      if (studySet.bloomMix.isNotEmpty) {
        final bloomSum = studySet.bloomMix.values.fold(0.0, (a, b) => a + b);
        if ((bloomSum - 1.0).abs() > 0.01) {
          warnings.add(
              'Bloom\'s mix doesn\'t sum to 1.0 (sum: ${bloomSum.toStringAsFixed(2)})');
        }
      }

      // Validate quiz if present
      if (studySet.quiz != null) {
        final quizValidation = validateAdvancedQuiz(studySet.quiz!);
        if (!quizValidation.isValid) {
          errors.addAll(quizValidation.errors.map((e) => 'Quiz: $e'));
        }
        warnings.addAll(quizValidation.warnings.map((w) => 'Quiz: $w'));
      }
    } catch (e) {
      errors.add('Study set validation failed: ${e.toString()}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate an advanced quiz
  ValidationResult validateAdvancedQuiz(AdvancedQuiz quiz) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Validate basic fields
      if (quiz.id.trim().isEmpty) {
        errors.add('Quiz ID cannot be empty');
      }

      if (quiz.title.trim().isEmpty) {
        errors.add('Quiz title cannot be empty');
      }

      // Validate questions
      if (quiz.questions.isEmpty) {
        errors.add('Quiz has no questions');
      } else if (quiz.questions.length != quiz.numQuestions) {
        warnings.add(
            'Question count mismatch: expected ${quiz.numQuestions}, got ${quiz.questions.length}');
      }

      // Validate time limit
      if (quiz.timeLimitSeconds <= 0) {
        errors.add('Invalid time limit: ${quiz.timeLimitSeconds}');
      } else if (quiz.timeLimitSeconds < quiz.questions.length * 30) {
        warnings.add(
            'Time limit seems very short (${quiz.timeLimitSeconds}s for ${quiz.questions.length} questions)');
      }

      // Validate pass threshold
      if (quiz.passThreshold < 0.0 || quiz.passThreshold > 1.0) {
        errors.add('Pass threshold must be between 0.0 and 1.0');
      } else if (quiz.passThreshold < 0.5) {
        warnings.add(
            'Pass threshold is quite low (${(quiz.passThreshold * 100).toStringAsFixed(0)}%)');
      }

      // Validate type mix
      if (quiz.typeMix.isNotEmpty) {
        final typeSum = quiz.typeMix.values.fold(0.0, (a, b) => a + b);
        if ((typeSum - 1.0).abs() > 0.01) {
          warnings.add(
              'Type mix doesn\'t sum to 1.0 (sum: ${typeSum.toStringAsFixed(2)})');
        }
      }
    } catch (e) {
      errors.add('Quiz validation failed: ${e.toString()}');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // Helper validation methods

  void _validateRequiredFields(Map<String, dynamic> data,
      List<String> requiredFields, List<String> errors) {
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }
  }

  void _validateBloomMix(
      dynamic bloomMix, List<String> errors, List<String> warnings) {
    if (bloomMix is! Map) {
      errors.add('Bloom mix must be a map');
      return;
    }

    final mix = Map<String, dynamic>.from(bloomMix);
    final validLevels = {
      'Understand',
      'Apply',
      'Analyze',
      'Evaluate',
      'Create'
    };

    // Check for valid Bloom levels
    for (final level in mix.keys) {
      if (!validLevels.contains(level)) {
        errors.add('Invalid Bloom level: $level');
      }
    }

    // Check values are numbers between 0 and 1
    for (final entry in mix.entries) {
      if (entry.value is! num) {
        errors.add('Bloom level ${entry.key} must have numeric value');
      } else {
        final value = (entry.value as num).toDouble();
        if (value < 0.0 || value > 1.0) {
          errors.add('Bloom level ${entry.key} value out of range: $value');
        }
      }
    }

    // Check sum is approximately 1.0
    final sum = mix.values.fold(0.0, (a, b) => a + (b as num).toDouble());
    if ((sum - 1.0).abs() > 0.01) {
      warnings.add(
          'Bloom mix doesn\'t sum to 1.0 (sum: ${sum.toStringAsFixed(2)})');
    }
  }

  void _validateCards(
      dynamic cards, List<String> errors, List<String> warnings) {
    if (cards is! List) {
      errors.add('Cards must be a list');
      return;
    }

    final cardList = cards;
    if (cardList.isEmpty) {
      warnings.add('No cards provided');
      return;
    }

    if (cardList.length > 100) {
      warnings.add('Very large number of cards: ${cardList.length}');
    }

    // Validate individual cards
    for (int i = 0; i < cardList.length; i++) {
      final card = cardList[i];
      if (card is! Map) {
        errors.add('Card $i is not a valid object');
        continue;
      }

      final cardMap = Map<String, dynamic>.from(card);
      _validateCardSchema(cardMap, i, errors, warnings);
    }
  }

  void _validateCardSchema(Map<String, dynamic> card, int index,
      List<String> errors, List<String> warnings) {
    final requiredFields = [
      'id',
      'type',
      'bloom',
      'difficulty',
      'question',
      'choices',
      'correct_index',
      'answer_explanation',
      'hint',
      'anchors',
      'source_span'
    ];

    for (final field in requiredFields) {
      if (!card.containsKey(field)) {
        errors.add('Card $index missing field: $field');
      }
    }

    // Validate question length
    if (card.containsKey('question')) {
      final question = card['question'] as String?;
      if (question != null && question.length > 180) {
        errors.add('Card $index question too long: ${question.length} chars');
      }
    }

    // Validate choices for MCQ/TF
    if (card.containsKey('type') && card.containsKey('choices')) {
      final type = card['type'] as String?;
      final choices = card['choices'];

      if ((type == 'mcq' || type == 'truefalse') && choices is List) {
        for (final choice in choices) {
          if (choice is String && choice.length > 90) {
            warnings.add('Card $index has long choice: ${choice.length} chars');
          }
        }
      }
    }
  }

  void _validateQuizConfig(
      dynamic quiz, List<String> errors, List<String> warnings) {
    if (quiz is! Map) {
      errors.add('Quiz config must be a map');
      return;
    }

    final quizMap = Map<String, dynamic>.from(quiz);
    final requiredFields = [
      'num_questions',
      'mix',
      'time_limit_seconds',
      'pass_threshold'
    ];

    for (final field in requiredFields) {
      if (!quizMap.containsKey(field)) {
        errors.add('Quiz missing field: $field');
      }
    }

    // Validate specific fields
    if (quizMap.containsKey('num_questions')) {
      final numQuestions = quizMap['num_questions'];
      if (numQuestions is! int || numQuestions <= 0) {
        errors.add('Invalid num_questions: $numQuestions');
      }
    }

    if (quizMap.containsKey('time_limit_seconds')) {
      final timeLimit = quizMap['time_limit_seconds'];
      if (timeLimit is! int || timeLimit <= 0) {
        errors.add('Invalid time_limit_seconds: $timeLimit');
      }
    }

    if (quizMap.containsKey('pass_threshold')) {
      final threshold = quizMap['pass_threshold'];
      if (threshold is! num || threshold < 0.0 || threshold > 1.0) {
        errors.add('Invalid pass_threshold: $threshold');
      }
    }
  }

  void _validateTags(dynamic tags, List<String> errors, List<String> warnings) {
    if (tags is! List) {
      errors.add('Tags must be a list');
      return;
    }

    final tagList = tags;
    if (tagList.length > 10) {
      warnings.add('Many tags provided: ${tagList.length}');
    }

    for (final tag in tagList) {
      if (tag is! String) {
        errors.add('All tags must be strings');
      } else if (tag.trim().isEmpty) {
        warnings.add('Empty tag found');
      }
    }
  }

  void _validateMCQCard(
      AdvancedFlashcard card, List<String> errors, List<String> warnings) {
    if (card.choices.isEmpty) {
      errors.add('MCQ card must have choices');
      return;
    }

    if (card.choices.length < 2) {
      errors.add('MCQ card must have at least 2 choices');
    } else if (card.choices.length > 6) {
      warnings.add('MCQ card has many choices (${card.choices.length})');
    }

    if (card.correctIndex < 0 || card.correctIndex >= card.choices.length) {
      errors.add('Invalid correct_index: ${card.correctIndex}');
    }

    // Check choice lengths
    for (int i = 0; i < card.choices.length; i++) {
      if (card.choices[i].length > 90) {
        warnings.add('Choice $i is long (${card.choices[i].length} chars)');
      }
    }
  }

  void _validateTrueFalseCard(
      AdvancedFlashcard card, List<String> errors, List<String> warnings) {
    if (card.choices.length != 2) {
      errors.add('True/False card must have exactly 2 choices');
    }

    if (card.correctIndex < 0 || card.correctIndex > 1) {
      errors.add('True/False correct_index must be 0 or 1');
    }
  }

  void _validateQACard(
      AdvancedFlashcard card, List<String> errors, List<String> warnings) {
    if (card.choices.isNotEmpty) {
      warnings.add('QA card should not have choices');
    }

    if (card.correctIndex != 0) {
      warnings.add('QA card correct_index should be 0');
    }
  }

  bool _isValidBloomLevel(String bloom) {
    const validLevels = {
      'Understand',
      'Apply',
      'Analyze',
      'Evaluate',
      'Create'
    };
    return validLevels.contains(bloom);
  }

  /// Sanitize and fix common issues in generation schema
  Map<String, dynamic> sanitizeSchema(Map<String, dynamic> schema) {
    final sanitized = Map<String, dynamic>.from(schema);

    try {
      // Fix common title issues
      if (sanitized.containsKey('set_title')) {
        final title = sanitized['set_title'] as String?;
        if (title != null) {
          sanitized['set_title'] = title.trim().replaceAll(RegExp(r'\s+'), ' ');
        }
      }

      // Normalize difficulty
      if (sanitized.containsKey('difficulty')) {
        final difficulty = sanitized['difficulty'];
        if (difficulty is num) {
          sanitized['difficulty'] = difficulty.toInt().clamp(1, 7);
        }
      }

      // Fix Bloom's mix
      if (sanitized.containsKey('bloom_mix')) {
        sanitized['bloom_mix'] = _sanitizeBloomMix(sanitized['bloom_mix']);
      }

      // Sanitize cards
      if (sanitized.containsKey('cards') && sanitized['cards'] is List) {
        final cards = sanitized['cards'] as List;
        sanitized['cards'] = cards.map(_sanitizeCard).toList();
      }

      // Ensure tags is a list of strings
      if (sanitized.containsKey('tags')) {
        final tags = sanitized['tags'];
        if (tags is List) {
          sanitized['tags'] = tags
              .where((tag) => tag is String && tag.toString().trim().isNotEmpty)
              .map((tag) => tag.toString().trim())
              .toList();
        }
      }
    } catch (e) {
      debugPrint('❌ Schema sanitization failed: $e');
    }

    return sanitized;
  }

  Map<String, dynamic> _sanitizeBloomMix(dynamic bloomMix) {
    if (bloomMix is! Map) return {};

    final sanitized = <String, double>{};
    final validLevels = {
      'Understand',
      'Apply',
      'Analyze',
      'Evaluate',
      'Create'
    };

    for (final entry in bloomMix.entries) {
      final level = entry.key.toString();
      final value = entry.value;

      if (validLevels.contains(level) && value is num) {
        sanitized[level] = value.toDouble().clamp(0.0, 1.0);
      }
    }

    // Normalize to sum to 1.0
    final sum = sanitized.values.fold(0.0, (a, b) => a + b);
    if (sum > 0) {
      for (final key in sanitized.keys) {
        sanitized[key] = sanitized[key]! / sum;
      }
    }

    return sanitized;
  }

  Map<String, dynamic> _sanitizeCard(dynamic card) {
    if (card is! Map) return {};

    final sanitized = Map<String, dynamic>.from(card);

    // Trim strings
    final stringFields = [
      'id',
      'type',
      'bloom',
      'difficulty',
      'question',
      'answer_explanation',
      'hint',
      'source_span'
    ];
    for (final field in stringFields) {
      if (sanitized.containsKey(field) && sanitized[field] is String) {
        sanitized[field] = (sanitized[field] as String).trim();
      }
    }

    // Ensure choices is a list
    if (!sanitized.containsKey('choices') || sanitized['choices'] is! List) {
      sanitized['choices'] = <String>[];
    }

    // Ensure anchors is a list
    if (!sanitized.containsKey('anchors') || sanitized['anchors'] is! List) {
      sanitized['anchors'] = <String>[];
    } else {
      final anchors = sanitized['anchors'] as List;
      sanitized['anchors'] = anchors
          .where((anchor) =>
              anchor is String && anchor.toString().trim().isNotEmpty)
          .map((anchor) => anchor.toString().trim())
          .toList();
    }

    // Ensure correct_index is valid
    if (sanitized.containsKey('correct_index')) {
      final correctIndex = sanitized['correct_index'];
      if (correctIndex is num) {
        sanitized['correct_index'] = correctIndex.toInt().clamp(0, 10);
      }
    }

    return sanitized;
  }
}

/// Result of validation with errors and warnings
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Get a summary of the validation result
  String get summary {
    if (isValid && warnings.isEmpty) {
      return 'Validation passed with no issues';
    } else if (isValid) {
      return 'Validation passed with ${warnings.length} warnings';
    } else {
      return 'Validation failed with ${errors.length} errors${warnings.isNotEmpty ? ' and ${warnings.length} warnings' : ''}';
    }
  }

  /// Get all issues as a formatted string
  String get allIssues {
    final issues = <String>[];

    if (errors.isNotEmpty) {
      issues.add('ERRORS:');
      issues.addAll(errors.map((e) => '  • $e'));
    }

    if (warnings.isNotEmpty) {
      if (issues.isNotEmpty) issues.add('');
      issues.add('WARNINGS:');
      issues.addAll(warnings.map((w) => '  • $w'));
    }

    return issues.join('\n');
  }

  @override
  String toString() => summary;
}
