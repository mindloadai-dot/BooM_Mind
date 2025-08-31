import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';

// Generation options
enum GenerationMethod {
  openai, // Primary: OpenAI Cloud Functions
  localAI, // Secondary: Local AI fallback
  template, // Tertiary: Template-based generation
  hybrid // Quaternary: Mixed approach
}

// Generation result with metadata
class GenerationResult {
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quizQuestions;
  final GenerationMethod method;
  final String? errorMessage;
  final bool isFallback;
  final int processingTimeMs;

  GenerationResult({
    required this.flashcards,
    required this.quizQuestions,
    required this.method,
    this.errorMessage,
    this.isFallback = false,
    required this.processingTimeMs,
  });

  bool get isSuccess => errorMessage == null;
}

/// Enhanced AI Service with multiple fallback options and robust error handling
class EnhancedAIService {
  static EnhancedAIService? _instance;
  static EnhancedAIService get instance => _instance ??= EnhancedAIService._();
  EnhancedAIService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;
  final LocalAIFallbackService _localFallback = LocalAIFallbackService.instance;

  /// Main entry point for generating study materials
  Future<GenerationResult> generateStudyMaterials({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Try OpenAI first
      final openaiResult = await _tryOpenAIGeneration(
        content: content,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
        questionTypes: questionTypes,
        cognitiveLevel: cognitiveLevel,
        realWorldContext: realWorldContext,
        challengeLevel: challengeLevel,
        learningStyle: learningStyle,
        promptEnhancement: promptEnhancement,
      );

      if (openaiResult.isSuccess) {
        stopwatch.stop();
        return GenerationResult(
          flashcards: openaiResult.flashcards,
          quizQuestions: openaiResult.quizQuestions,
          method: GenerationMethod.openai,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Try Local AI fallback
      final localResult = await _tryLocalAIGeneration(
        content: content,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      if (localResult.isSuccess) {
        stopwatch.stop();
        return GenerationResult(
          flashcards: localResult.flashcards,
          quizQuestions: localResult.quizQuestions,
          method: GenerationMethod.localAI,
          isFallback: true,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Try Template-based generation
      final templateResult = await _tryTemplateGeneration(
        content: content,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      if (templateResult.isSuccess) {
        stopwatch.stop();
        return GenerationResult(
          flashcards: templateResult.flashcards,
          quizQuestions: templateResult.quizQuestions,
          method: GenerationMethod.template,
          isFallback: true,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Try Hybrid approach
      final hybridResult = await _tryHybridGeneration(
        content: content,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      stopwatch.stop();
      return GenerationResult(
        flashcards: hybridResult.flashcards,
        quizQuestions: hybridResult.quizQuestions,
        method: GenerationMethod.hybrid,
        isFallback: true,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ All generation methods failed: $e');

      // Return basic template as last resort
      final basicResult = await _generateBasicTemplates(
        content: content,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      return GenerationResult(
        flashcards: basicResult.flashcards,
        quizQuestions: basicResult.quizQuestions,
        method: GenerationMethod.template,
        errorMessage: e.toString(),
        isFallback: true,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Try OpenAI Cloud Functions generation
  Future<GenerationResult> _tryOpenAIGeneration({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    try {
      debugPrint('🚀 Enhanced AI: Attempting OpenAI generation...');

      // Ensure authentication
      await _ensureAuthentication();
      debugPrint('✅ Enhanced AI: Authentication ensured');

      // Get tokens
      final appCheckToken = await _getAppCheckToken();
      final idToken = await _getIdToken();
      debugPrint(
          '✅ Enhanced AI: Tokens obtained - AppCheck: ${appCheckToken != null}, ID: ${idToken != null}');

      // Generate flashcards
      debugPrint(
          '🔍 Enhanced AI: Calling generateFlashcards Cloud Function...');
      final flashcardCallable = _functions.httpsCallable('generateFlashcards');
      final flashcardResult = await flashcardCallable.call({
        'content': content,
        'count': flashcardCount,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });
      debugPrint('✅ Enhanced AI: Flashcard Cloud Function call successful');

      debugPrint(
          '🔍 Enhanced AI: Flashcard result data type: ${flashcardResult.data.runtimeType}');
      debugPrint(
          '🔍 Enhanced AI: Flashcard result data: ${flashcardResult.data}');

      // Generate quiz questions
      debugPrint('🔍 Enhanced AI: Calling generateQuiz Cloud Function...');
      final quizCallable = _functions.httpsCallable('generateQuiz');
      final quizResult = await quizCallable.call({
        'content': content,
        'count': quizCount,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });
      debugPrint('✅ Enhanced AI: Quiz Cloud Function call successful');

      debugPrint(
          '🔍 Enhanced AI: Quiz result data type: ${quizResult.data.runtimeType}');
      debugPrint('🔍 Enhanced AI: Quiz result data: ${quizResult.data}');

      // Parse results
      debugPrint('🔍 Enhanced AI: Parsing flashcards...');
      final flashcards = _parseFlashcards(flashcardResult.data);
      debugPrint('🔍 Enhanced AI: Parsing quiz questions...');
      final quizQuestions = _parseQuizQuestions(quizResult.data);

      debugPrint('✅ Enhanced AI: OpenAI generation successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.openai,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint('❌ Enhanced AI: OpenAI generation failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.openai,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Try Local AI fallback generation
  Future<GenerationResult> _tryLocalAIGeneration({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint('🔄 Attempting Local AI fallback...');

      final flashcards = await _localFallback.generateFlashcards(
        content,
        count: flashcardCount,
        targetDifficulty: _mapStringToDifficultyLevel(difficulty),
      );

      final quizQuestions = await _localFallback.generateQuizQuestions(
        content,
        quizCount,
        difficulty,
      );

      debugPrint('✅ Local AI fallback successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.localAI,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint('❌ Local AI fallback failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.localAI,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Try Template-based generation
  Future<GenerationResult> _tryTemplateGeneration({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint('📋 Attempting Template-based generation...');

      final flashcards = await _generateTemplateFlashcards(
        content: content,
        count: flashcardCount,
        difficulty: difficulty,
      );

      final quizQuestions = await _generateTemplateQuizQuestions(
        content: content,
        count: quizCount,
        difficulty: difficulty,
      );

      debugPrint('✅ Template generation successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.template,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint('❌ Template generation failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.template,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Try Hybrid generation (mix of methods)
  Future<GenerationResult> _tryHybridGeneration({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint('🔀 Attempting Hybrid generation...');

      // Try to get some from OpenAI, rest from local
      final openaiFlashcards = await _tryOpenAIGeneration(
        content: content,
        flashcardCount: flashcardCount ~/ 2,
        quizCount: quizCount ~/ 2,
        difficulty: difficulty,
      );

      final localFlashcards = await _tryLocalAIGeneration(
        content: content,
        flashcardCount: flashcardCount - (flashcardCount ~/ 2),
        quizCount: quizCount - (quizCount ~/ 2),
        difficulty: difficulty,
      );

      final allFlashcards = [
        ...openaiFlashcards.flashcards,
        ...localFlashcards.flashcards,
      ];

      final allQuizQuestions = [
        ...openaiFlashcards.quizQuestions,
        ...localFlashcards.quizQuestions,
      ];

      debugPrint('✅ Hybrid generation successful');
      return GenerationResult(
        flashcards: allFlashcards,
        quizQuestions: allQuizQuestions,
        method: GenerationMethod.hybrid,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint('❌ Hybrid generation failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.hybrid,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Generate basic templates as last resort
  Future<GenerationResult> _generateBasicTemplates({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    debugPrint('📝 Generating basic templates as last resort...');

    final flashcards =
        _createBasicFlashcards(content, flashcardCount, difficulty);
    final quizQuestions =
        _createBasicQuizQuestions(content, quizCount, difficulty);

    return GenerationResult(
      flashcards: flashcards,
      quizQuestions: quizQuestions,
      method: GenerationMethod.template,
      processingTimeMs: 0,
    );
  }

  // Helper methods
  Future<void> _ensureAuthentication() async {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('⚠️ User not authenticated, attempting anonymous sign-in...');
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('✅ Anonymous sign-in successful');
      } catch (e) {
        debugPrint('❌ Anonymous sign-in failed: $e');
        throw Exception('Authentication failed: $e');
      }
    }
  }

  Future<String?> _getAppCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      debugPrint('App Check token failed: $e');
      return null;
    }
  }

  Future<String?> _getIdToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return await firebaseUser.getIdToken(true);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get ID token: $e');
      return null;
    }
  }

  List<Flashcard> _parseFlashcards(dynamic data) {
    try {
      debugPrint('🔍 Parsing flashcards data type: ${data.runtimeType}');
      debugPrint('🔍 Parsing flashcards data: $data');

      // Handle different data types more robustly
      Map<String, dynamic> parsedData;
      if (data is Map<Object?, Object?>) {
        // Convert Map<Object?, Object?> to Map<String, dynamic> safely
        parsedData = <String, dynamic>{};
        data.forEach((key, value) {
          if (key is String) {
            parsedData[key] = value;
          } else {
            parsedData[key.toString()] = value;
          }
        });
        debugPrint('✅ Converted Map<Object?, Object?> to Map<String, dynamic>');
      } else if (data is Map<String, dynamic>) {
        parsedData = data;
        debugPrint('✅ Data is already Map<String, dynamic>');
      } else {
        debugPrint(
            '❌ Error parsing flashcards: Invalid data type: ${data.runtimeType}');
        return [];
      }

      if (parsedData.containsKey('flashcards')) {
        final List<dynamic> flashcardsData = parsedData['flashcards'];
        debugPrint('✅ Found ${flashcardsData.length} flashcards in data');
        return flashcardsData
            .map((item) {
              // Convert each item to Map<String, dynamic> if needed
              Map<String, dynamic> itemMap;
              if (item is Map<Object?, Object?>) {
                itemMap = Map<String, dynamic>.from(item);
              } else if (item is Map<String, dynamic>) {
                itemMap = item;
              } else {
                debugPrint(
                    '❌ Invalid flashcard item type: ${item.runtimeType}');
                return null;
              }

              // Create a complete flashcard with required fields
              return Flashcard(
                id: itemMap['id'] ??
                    'flashcard_${DateTime.now().millisecondsSinceEpoch}_${itemMap.hashCode}',
                question: itemMap['question'] ?? 'No question provided',
                answer: itemMap['answer'] ?? 'No answer provided',
                difficulty: _mapStringToDifficultyLevel(
                    itemMap['difficulty'] ?? 'intermediate'),
              );
            })
            .where((flashcard) => flashcard != null)
            .cast<Flashcard>()
            .toList();
      } else {
        debugPrint(
            '❌ No flashcards key found in data. Keys: ${parsedData.keys}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing flashcards: $e');
      return [];
    }
  }

  List<QuizQuestion> _parseQuizQuestions(dynamic data) {
    try {
      debugPrint('🔍 Parsing quiz questions data type: ${data.runtimeType}');
      debugPrint('🔍 Parsing quiz questions data: $data');

      // Handle different data types more robustly
      Map<String, dynamic> parsedData;
      if (data is Map<Object?, Object?>) {
        // Convert Map<Object?, Object?> to Map<String, dynamic> safely
        parsedData = <String, dynamic>{};
        data.forEach((key, value) {
          if (key is String) {
            parsedData[key] = value;
          } else {
            parsedData[key.toString()] = value;
          }
        });
        debugPrint('✅ Converted Map<Object?, Object?> to Map<String, dynamic>');
      } else if (data is Map<String, dynamic>) {
        parsedData = data;
        debugPrint('✅ Data is already Map<String, dynamic>');
      } else {
        debugPrint(
            '❌ Error parsing quiz questions: Invalid data type: ${data.runtimeType}');
        return [];
      }

      if (parsedData.containsKey('questions')) {
        final List<dynamic> questionsData = parsedData['questions'];
        debugPrint('✅ Found ${questionsData.length} quiz questions in data');
        return questionsData
            .map((item) {
              // Convert each item to Map<String, dynamic> if needed
              Map<String, dynamic> itemMap;
              if (item is Map<Object?, Object?>) {
                itemMap = Map<String, dynamic>.from(item);
              } else if (item is Map<String, dynamic>) {
                itemMap = item;
              } else {
                debugPrint(
                    '❌ Invalid quiz question item type: ${item.runtimeType}');
                return null;
              }
              // Create a complete quiz question with required fields
              return QuizQuestion(
                id: itemMap['id'] ??
                    'quiz_${DateTime.now().millisecondsSinceEpoch}_${itemMap.hashCode}',
                question: itemMap['question'] ?? 'No question provided',
                options:
                    (itemMap['options'] as List<dynamic>?)?.cast<String>() ??
                        ['No options provided'],
                correctAnswer:
                    itemMap['correctAnswer'] ?? 'No correct answer provided',
                difficulty: _mapStringToDifficultyLevel(
                    itemMap['difficulty'] ?? 'intermediate'),
              );
            })
            .where((question) => question != null)
            .cast<QuizQuestion>()
            .toList();
      } else {
        debugPrint(
            '❌ No questions key found in data. Keys: ${parsedData.keys}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing quiz questions: $e');
      return [];
    }
  }

  // Helper method to map string to DifficultyLevel
  DifficultyLevel _mapStringToDifficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'medium':
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'hard':
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  List<Flashcard> _createBasicFlashcards(
      String content, int count, String difficulty) {
    final flashcards = <Flashcard>[];
    final words = content.split(' ').where((word) => word.length > 3).toList();

    for (int i = 0; i < count && i < words.length; i++) {
      flashcards.add(Flashcard(
        id: 'basic_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: 'What is the meaning of "${words[i]}"?',
        answer:
            'This term appears in the provided content and is important for understanding the material.',
        difficulty: _mapStringToDifficultyLevel(difficulty),
      ));
    }

    return flashcards;
  }

  List<QuizQuestion> _createBasicQuizQuestions(
      String content, int count, String difficulty) {
    final questions = <QuizQuestion>[];
    final sentences =
        content.split('.').where((s) => s.trim().length > 10).toList();

    for (int i = 0; i < count && i < sentences.length; i++) {
      questions.add(QuizQuestion(
        id: 'basic_quiz_${DateTime.now().millisecondsSinceEpoch}_$i',
        question:
            'Which of the following best describes the main concept in this content?',
        options: [
          'A key principle discussed in the material',
          'An important application of the concepts',
          'A fundamental understanding of the topic',
          'A practical implementation of the ideas',
        ],
        correctAnswer: 'A key principle discussed in the material',
        difficulty: _mapStringToDifficultyLevel(difficulty),
      ));
    }

    return questions;
  }

  Future<List<Flashcard>> _generateTemplateFlashcards({
    required String content,
    required int count,
    required String difficulty,
  }) async {
    // Enhanced template-based flashcard generation
    final flashcards = <Flashcard>[];
    final paragraphs =
        content.split('\n\n').where((p) => p.trim().length > 50).toList();

    for (int i = 0; i < count && i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final sentences =
          paragraph.split('.').where((s) => s.trim().length > 20).toList();

      if (sentences.isNotEmpty) {
        final question = _generateTemplateQuestion(sentences.first, difficulty);
        final answer = _generateTemplateAnswer(sentences, difficulty);

        flashcards.add(Flashcard(
          id: 'template_${DateTime.now().millisecondsSinceEpoch}_$i',
          question: question,
          answer: answer,
          difficulty: _mapStringToDifficultyLevel(difficulty),
        ));
      }
    }

    return flashcards;
  }

  Future<List<QuizQuestion>> _generateTemplateQuizQuestions({
    required String content,
    required int count,
    required String difficulty,
  }) async {
    // Enhanced template-based quiz generation
    final questions = <QuizQuestion>[];
    final paragraphs =
        content.split('\n\n').where((p) => p.trim().length > 50).toList();

    for (int i = 0; i < count && i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final question = _generateTemplateQuizQuestion(paragraph, difficulty);
      final options = _generateTemplateOptions(paragraph, difficulty);

      questions.add(QuizQuestion(
        id: 'template_quiz_${DateTime.now().millisecondsSinceEpoch}_$i',
        question: question,
        options: options,
        correctAnswer: options.isNotEmpty
            ? options.first
            : 'The main concept discussed in the material',
        difficulty: _mapStringToDifficultyLevel(difficulty),
      ));
    }

    return questions;
  }

  String _generateTemplateQuestion(String sentence, String difficulty) {
    final words = sentence.split(' ').where((word) => word.length > 4).toList();
    if (words.isEmpty) return 'What is the main concept discussed?';

    final keyWord = words.first;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'What does "$keyWord" mean in this context?';
      case 'medium':
        return 'How does "$keyWord" relate to the main topic?';
      case 'hard':
        return 'What are the implications of "$keyWord" in this context?';
      default:
        return 'What is the significance of "$keyWord"?';
    }
  }

  String _generateTemplateAnswer(List<String> sentences, String difficulty) {
    if (sentences.isEmpty) {
      return 'The answer can be found in the provided content.';
    }

    final keySentence = sentences.first;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return keySentence;
      case 'medium':
        return '$keySentence This concept is important for understanding the broader context.';
      case 'hard':
        return '$keySentence This has significant implications for the overall understanding of the topic.';
      default:
        return keySentence;
    }
  }

  String _generateTemplateQuizQuestion(String paragraph, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'What is the main topic discussed in this content?';
      case 'medium':
        return 'Which of the following best summarizes the key concept?';
      case 'hard':
        return 'What are the underlying principles that support this content?';
      default:
        return 'What is the primary focus of this material?';
    }
  }

  List<String> _generateTemplateOptions(String paragraph, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return [
          'The main concept discussed in the material',
          'A secondary topic mentioned briefly',
          'An unrelated concept',
          'A technical detail',
        ];
      case 'medium':
        return [
          'A comprehensive understanding of the topic',
          'A basic overview of the subject',
          'A detailed analysis of one aspect',
          'A comparison of different approaches',
        ];
      case 'hard':
        return [
          'The fundamental principles underlying the concepts',
          'The practical applications of the ideas',
          'The historical context of the topic',
          'The theoretical framework',
        ];
      default:
        return [
          'The primary focus of the material',
          'A supporting detail',
          'An example or illustration',
          'A conclusion or summary',
        ];
    }
  }

  /// Generate additional study materials that are different from existing ones
  Future<GenerationResult> generateAdditionalStudyMaterials({
    required String content,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
    required List<Flashcard> existingFlashcards,
    required List<QuizQuestion> existingQuizQuestions,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Create enhanced prompt that ensures different content
      final enhancedContent = _createEnhancedPromptForAdditionalContent(
        content: content,
        existingFlashcards: existingFlashcards,
        existingQuizQuestions: existingQuizQuestions,
        difficulty: difficulty,
        questionTypes: questionTypes,
        cognitiveLevel: cognitiveLevel,
        realWorldContext: realWorldContext,
        challengeLevel: challengeLevel,
        learningStyle: learningStyle,
        promptEnhancement: promptEnhancement,
      );

      // Try OpenAI with enhanced prompt
      final openaiResult = await _tryOpenAIGenerationWithEnhancedPrompt(
        enhancedContent: enhancedContent,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      if (openaiResult.isSuccess) {
        stopwatch.stop();
        return GenerationResult(
          flashcards: openaiResult.flashcards,
          quizQuestions: openaiResult.quizQuestions,
          method: GenerationMethod.openai,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Try Local AI fallback with enhanced prompt
      final localResult = await _tryLocalAIGenerationWithEnhancedPrompt(
        enhancedContent: enhancedContent,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      if (localResult.isSuccess) {
        stopwatch.stop();
        return GenerationResult(
          flashcards: localResult.flashcards,
          quizQuestions: localResult.quizQuestions,
          method: GenerationMethod.localAI,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          isFallback: true,
        );
      }

      // Try Template-based generation as last resort
      final templateResult = await _tryTemplateGenerationWithEnhancedPrompt(
        enhancedContent: enhancedContent,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
      );

      stopwatch.stop();
      return GenerationResult(
        flashcards: templateResult.flashcards,
        quizQuestions: templateResult.quizQuestions,
        method: GenerationMethod.template,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        isFallback: true,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Enhanced AI: All generation methods failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.openai,
        errorMessage: e.toString(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Create enhanced prompt that ensures different content from existing
  String _createEnhancedPromptForAdditionalContent({
    required String content,
    required List<Flashcard> existingFlashcards,
    required List<QuizQuestion> existingQuizQuestions,
    required String difficulty,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) {
    // Extract existing questions to avoid duplication
    final existingQuestions = <String>[];
    existingQuestions
        .addAll(existingFlashcards.map((f) => f.question.toLowerCase()));
    existingQuestions
        .addAll(existingQuizQuestions.map((q) => q.question.toLowerCase()));

    // Create a comprehensive prompt that ensures different content
    final enhancedPrompt = '''
IMPORTANT: Generate COMPLETELY DIFFERENT questions and answers from the existing ones.

EXISTING QUESTIONS TO AVOID:
${existingQuestions.take(10).join('\n')}

CONTENT TO USE:
$content

REQUIREMENTS:
1. Generate questions that are COMPLETELY DIFFERENT from the existing ones
2. Focus on different aspects, details, or perspectives of the content
3. Use different wording, phrasing, and question structures
4. Ensure answers cover different parts of the content
5. Target difficulty: $difficulty
${questionTypes != null ? '6. Question types: $questionTypes' : ''}
${cognitiveLevel != null ? '7. Cognitive level: $cognitiveLevel' : ''}
${realWorldContext != null ? '8. Real-world context: $realWorldContext' : ''}
${challengeLevel != null ? '9. Challenge level: $challengeLevel' : ''}
${learningStyle != null ? '10. Learning style: $learningStyle' : ''}
${promptEnhancement != null ? '11. Additional requirements: $promptEnhancement' : ''}

GENERATION INSTRUCTIONS:
- Analyze the content from different angles
- Focus on unexplored aspects, examples, or applications
- Use different question formats and structures
- Ensure variety in difficulty and complexity
- Make questions engaging and thought-provoking
''';

    return enhancedPrompt;
  }

  /// Try OpenAI generation with enhanced prompt for additional content
  Future<GenerationResult> _tryOpenAIGenerationWithEnhancedPrompt({
    required String enhancedContent,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint(
          '🚀 Enhanced AI: Attempting OpenAI generation for additional content...');
      // Ensure authentication
      await _ensureAuthentication();
      debugPrint('✅ Enhanced AI: Authentication ensured');
      // Get tokens
      final appCheckToken = await _getAppCheckToken();
      final idToken = await _getIdToken();
      debugPrint(
          '✅ Enhanced AI: Tokens obtained - AppCheck: ${appCheckToken != null}, ID: ${idToken != null}');
      // Generate flashcards
      debugPrint(
          '🔍 Enhanced AI: Calling generateFlashcards Cloud Function with enhanced prompt...');
      final flashcardCallable = _functions.httpsCallable('generateFlashcards');
      final flashcardResult = await flashcardCallable.call({
        'content': enhancedContent,
        'count': flashcardCount,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });
      debugPrint('✅ Enhanced AI: Flashcard Cloud Function call successful');
      debugPrint(
          '🔍 Enhanced AI: Flashcard result data type: ${flashcardResult.data.runtimeType}');
      debugPrint(
          '🔍 Enhanced AI: Flashcard result data: ${flashcardResult.data}');
      // Generate quiz questions
      debugPrint(
          '🔍 Enhanced AI: Calling generateQuiz Cloud Function with enhanced prompt...');
      final quizCallable = _functions.httpsCallable('generateQuiz');
      final quizResult = await quizCallable.call({
        'content': enhancedContent,
        'count': quizCount,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });
      debugPrint('✅ Enhanced AI: Quiz Cloud Function call successful');
      debugPrint(
          '🔍 Enhanced AI: Quiz result data type: ${quizResult.data.runtimeType}');
      debugPrint('🔍 Enhanced AI: Quiz result data: ${quizResult.data}');
      // Parse results
      debugPrint('🔍 Enhanced AI: Parsing flashcards...');
      final flashcards = _parseFlashcards(flashcardResult.data);
      debugPrint('🔍 Enhanced AI: Parsing quiz questions...');
      final quizQuestions = _parseQuizQuestions(quizResult.data);
      debugPrint(
          '✅ Enhanced AI: OpenAI generation for additional content successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.openai,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint(
          '❌ Enhanced AI: OpenAI generation for additional content failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.openai,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Try Local AI fallback with enhanced prompt for additional content
  Future<GenerationResult> _tryLocalAIGenerationWithEnhancedPrompt({
    required String enhancedContent,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint('🔄 Attempting Local AI fallback for additional content...');

      final flashcards = await _localFallback.generateFlashcards(
        enhancedContent,
        count: flashcardCount,
        targetDifficulty: _mapStringToDifficultyLevel(difficulty),
      );

      final quizQuestions = await _localFallback.generateQuizQuestions(
        enhancedContent,
        quizCount,
        difficulty,
      );

      debugPrint('✅ Local AI fallback for additional content successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.localAI,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint('❌ Local AI fallback for additional content failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.localAI,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Try Template-based generation with enhanced prompt for additional content
  Future<GenerationResult> _tryTemplateGenerationWithEnhancedPrompt({
    required String enhancedContent,
    required int flashcardCount,
    required int quizCount,
    required String difficulty,
  }) async {
    try {
      debugPrint(
          '📋 Attempting Template-based generation for additional content...');

      final flashcards = await _generateTemplateFlashcards(
        content: enhancedContent,
        count: flashcardCount,
        difficulty: difficulty,
      );

      final quizQuestions = await _generateTemplateQuizQuestions(
        content: enhancedContent,
        count: quizCount,
        difficulty: difficulty,
      );

      debugPrint(
          '✅ Template-based generation for additional content successful');
      return GenerationResult(
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        method: GenerationMethod.template,
        processingTimeMs: 0,
      );
    } catch (e) {
      debugPrint(
          '❌ Template-based generation for additional content failed: $e');
      return GenerationResult(
        flashcards: [],
        quizQuestions: [],
        method: GenerationMethod.template,
        errorMessage: e.toString(),
        processingTimeMs: 0,
      );
    }
  }

  /// Test the EnhancedAIService functionality
  static Future<void> testEnhancedAIService() async {
    debugPrint('🧪 Testing EnhancedAIService functionality...');
    
    try {
      // Test with simple content
      final testContent = '''
        Artificial Intelligence (AI) is a branch of computer science that aims to create intelligent machines that work and react like humans. 
        Some of the activities computers with artificial intelligence are designed for include speech recognition, learning, planning, and problem solving.
        AI can be categorized as either weak AI or strong AI. Weak AI, also known as narrow AI, is designed to perform a narrow task. 
        Strong AI, also known as artificial general intelligence, is an AI system with generalized human cognitive abilities.
      ''';
      
      debugPrint('📝 Test content length: ${testContent.length} characters');
      
      // Test each generation method individually
      debugPrint('🔍 Testing OpenAI generation...');
      try {
        final openaiResult = await instance._tryOpenAIGeneration(
          content: testContent,
          flashcardCount: 2,
          quizCount: 1,
          difficulty: 'medium',
        );
        debugPrint('✅ OpenAI test result: ${openaiResult.isSuccess}');
        if (!openaiResult.isSuccess) {
          debugPrint('❌ OpenAI error: ${openaiResult.errorMessage}');
        }
      } catch (e) {
        debugPrint('❌ OpenAI test failed: $e');
      }
      
      debugPrint('🔍 Testing Local AI fallback...');
      try {
        final localResult = await instance._tryLocalAIGeneration(
          content: testContent,
          flashcardCount: 2,
          quizCount: 1,
          difficulty: 'medium',
        );
        debugPrint('✅ Local AI test result: ${localResult.isSuccess}');
        if (!localResult.isSuccess) {
          debugPrint('❌ Local AI error: ${localResult.errorMessage}');
        }
      } catch (e) {
        debugPrint('❌ Local AI test failed: $e');
      }
      
      debugPrint('🔍 Testing Template generation...');
      try {
        final templateResult = await instance._tryTemplateGeneration(
          content: testContent,
          flashcardCount: 2,
          quizCount: 1,
          difficulty: 'medium',
        );
        debugPrint('✅ Template test result: ${templateResult.isSuccess}');
        if (!templateResult.isSuccess) {
          debugPrint('❌ Template error: ${templateResult.errorMessage}');
        }
      } catch (e) {
        debugPrint('❌ Template test failed: $e');
      }
      
      // Test main generation method
      debugPrint('🔍 Testing main generation method...');
      final result = await instance.generateStudyMaterials(
        content: testContent,
        flashcardCount: 3,
        quizCount: 2,
        difficulty: 'medium',
      );
      
      debugPrint('✅ EnhancedAIService test completed');
      debugPrint('📊 Method used: ${result.method.name}');
      debugPrint('📊 Flashcards generated: ${result.flashcards.length}');
      debugPrint('📊 Quiz questions generated: ${result.quizQuestions.length}');
      debugPrint('📊 Processing time: ${result.processingTimeMs}ms');
      debugPrint('📊 Is fallback: ${result.isFallback}');
      debugPrint('📊 Success: ${result.isSuccess}');
      
      if (!result.isSuccess) {
        debugPrint('❌ Error message: ${result.errorMessage}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ EnhancedAIService test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
}
