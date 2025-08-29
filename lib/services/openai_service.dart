import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';
import 'dart:convert'; // Added for json.decode
import 'package:uuid/uuid.dart'; // Added for uuid.v4
import 'package:http/http.dart' as http; // Added for http client

class OpenAIService {
  static OpenAIService? _instance;
  static OpenAIService get instance => _instance ??= OpenAIService._();
  OpenAIService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;

  // Rate limiting state
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const int _maxRequestsPerMinute = 20;

  // Method overload for generation dialog - returns flashcards from content
  Future<List<Flashcard>> generateFlashcardsFromContent(
    String content,
    int count,
    String difficulty, {
    String? questionTypes, // e.g., "concept, application, analysis, synthesis"
    String?
        cognitiveLevel, // e.g., "remember, understand, apply, analyze, evaluate, create"
    String?
        realWorldContext, // e.g., "business, healthcare, technology, daily life"
    String? challengeLevel, // e.g., "basic, intermediate, advanced, expert"
    String? learningStyle, // e.g., "visual, auditory, kinesthetic, reading"
    String? promptEnhancement, // Custom additional instructions
  }) async {
    try {
      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Call Cloud Function for secure API access
      final result = await _functions.httpsCallable('generateFlashcards').call({
        'content': content,
        'count': count,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        try {
          final responseData = result.data as Map<String, dynamic>;
          if (responseData.containsKey('flashcards')) {
            final flashcardsList = responseData['flashcards'] as List;
            return flashcardsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              // Create a Flashcard with generated ID and safe parsing
              return Flashcard(
                id: 'generated_${DateTime.now().millisecondsSinceEpoch}_$index',
                question:
                    data['question']?.toString() ?? 'Question not available',
                answer: data['answer']?.toString() ?? 'Answer not available',
                difficulty: _parseDifficulty(
                    data['difficulty']?.toString() ?? difficulty),
              );
            }).toList();
          }
        } catch (parseError) {
          debugPrint('Error parsing flashcards response: $parseError');
        }
      }

      // Fallback: return empty list if parsing fails
      return [];
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      debugPrint('🔄 Attempting local fallback for flashcards...');

      // Try local fallback when Cloud Functions fail
      try {
        return await LocalAIFallbackService.instance.generateFlashcards(content,
            count: count, targetDifficulty: _parseDifficulty(difficulty));
      } catch (fallbackError) {
        debugPrint('❌ Local fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  // Generate study material from content
  Future<String?> generateStudyMaterial(
    String content,
    String materialType,
    String difficulty,
  ) async {
    try {
      return await _makeSecureAPICall(
        content: content,
        materialType: materialType,
        difficulty: difficulty,
      );
    } catch (e) {
      debugPrint('Error generating study material: $e');
      return null;
    }
  }

  // Legacy method name for compatibility
  Future<List<QuizQuestion>> generateQuizQuestionsFromContent(
    String content,
    int count,
    String difficulty,
  ) async {
    return generateQuizQuestions(content, count, difficulty);
  }

  /// Generate advanced, adaptive flashcards with multiple difficulty levels
  Future<List<Flashcard>> generateFlashcards(
    String content, {
    int count = 10,
    DifficultyLevel targetDifficulty = DifficultyLevel.intermediate,
  }) async {
    try {
      final uuid = Uuid();
      final prompt = '''
      Generate $count highly sophisticated and intellectually challenging flashcards from the following content. Create flashcards that promote deep understanding and critical thinking rather than rote memorization.

      ADVANCED FLASHCARD DESIGN PRINCIPLES:
      - Focus on conceptual understanding and practical application
      - Create questions that require explanation, analysis, and reasoning
      - Test understanding of relationships, patterns, and implications
      - Design questions that connect concepts to real-world scenarios
      - Encourage synthesis of ideas and critical evaluation
      - Build questions that reveal depth of understanding

      SOPHISTICATED QUESTION TYPES:
      - Explanatory Analysis: "Explain why this phenomenon occurs and what factors influence it"
      - Comparative Reasoning: "Compare and contrast these approaches, analyzing their strengths and limitations"
      - Application Synthesis: "How would you apply this concept to solve a complex real-world problem?"
      - Causal Investigation: "What are the underlying causes and what would be the consequences if conditions changed?"
      - Evaluative Judgment: "Assess the effectiveness of this approach and justify your reasoning"
      - Predictive Analysis: "Based on these principles, predict what would happen in this new scenario"

      ANSWER REQUIREMENTS:
      - Provide comprehensive, detailed explanations that demonstrate deep understanding
      - Include reasoning, evidence, and logical connections
      - Connect concepts to broader contexts and implications
      - Use specific examples and applications where relevant
      - Explain the "why" and "how" behind facts and concepts
      - Address common misconceptions and clarify nuances

      DIFFICULTY DISTRIBUTION:
      - 30% Advanced: Require analysis, application, and synthesis of key concepts
      - 50% Expert: Require mastery-level understanding and complex reasoning
      - 20% Mastery: Require innovative thinking and creative application

      Content to analyze: $content
      
      Output Format for EACH Flashcard:
      {
        "question": "Thought-provoking question that requires deep analysis and explanation",
        "answer": "Comprehensive answer with detailed reasoning, examples, and connections to broader concepts",
        "difficulty": "advanced/expert/mastery",
        "questionType": "explanatory/comparative/application/causal/evaluative/predictive",
        "keyTerms": ["important", "concepts", "covered"],
        "cognitiveLevel": "The specific type of thinking required",
        "realWorldConnection": "How this concept applies in practical situations"
      }
      ''';

      final response = await _callOpenAI(
        model: 'gpt-4-turbo',
        messages: [
          {
            'role': 'system',
            'content':
                'You are a world-renowned educational content specialist with expertise in cognitive science, advanced pedagogy, and deep learning methodologies. Your expertise lies in creating intellectually challenging content that promotes critical thinking, conceptual understanding, and practical application.'
          },
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.8,
        maxTokens: 3000,
      );

      // Parse and transform OpenAI response into Flashcards
      final List<dynamic> parsedCards = json.decode(response);

      return parsedCards.map((card) {
        final difficulty = _mapStringToDifficultyLevel(card['difficulty']);
        final questionType = _mapStringToQuestionType(card['questionType']);

        return Flashcard(
          id: uuid.v4(),
          question: card['question'],
          answer: card['answer'],
          difficulty: difficulty,
          questionType: questionType,
        );
      }).toList();
    } catch (e) {
      print('Flashcard Generation Error: $e');
      return [];
    }
  }

  /// Generate advanced, adaptive quiz questions
  Future<List<QuizQuestion>> generateQuiz(
    String content, {
    int count = 10,
    DifficultyLevel targetDifficulty = DifficultyLevel.intermediate,
  }) async {
    try {
      final uuid = Uuid();
      final prompt = '''
      Generate $count highly challenging and thought-provoking quiz questions from the following content. Create questions that go far beyond simple recall and test deep conceptual understanding.

      ADVANCED QUESTION DESIGN PRINCIPLES:
      - Focus exclusively on higher-order thinking: analysis, synthesis, evaluation, application
      - Create scenario-based questions that apply knowledge to new, complex situations
      - Test understanding of cause-and-effect relationships and implications
      - Design questions that require connecting multiple concepts and ideas
      - Use critical thinking prompts: "Why would...", "What would happen if...", "How does this relate to..."
      - Create questions that challenge assumptions and require careful reasoning

      SOPHISTICATED QUESTION TYPES:
      - Analytical Reasoning: "Given this scenario, what would be the most likely outcome and why?"
      - Application Transfer: "How would you apply this principle in a completely different context?"
      - Synthesis & Integration: "What is the underlying relationship between these seemingly unrelated concepts?"
      - Evaluation & Judgment: "Which approach would be most effective in this situation and what are the trade-offs?"
      - Inference & Prediction: "Based on these patterns, what can you predict about future developments?"
      - Problem-Solving: "If faced with this complex problem, what systematic approach would yield the best results?"

      DIFFICULTY DISTRIBUTION:
      - 20% Intermediate: Require connecting 2-3 key concepts with some analysis
      - 60% Advanced: Require deep analysis, application to new contexts, and synthesis
      - 20% Expert: Require mastery-level synthesis of multiple complex ideas and evaluation

      ANSWER OPTION SOPHISTICATION:
      - Create 4 highly plausible options that all seem reasonable at first glance
      - Include sophisticated distractors based on common expert-level misconceptions
      - Make wrong answers that would trap someone with superficial understanding
      - Ensure the correct answer requires deep analysis and cannot be guessed
      - Each distractor should test a specific aspect of understanding

      Content to analyze: $content
      
      Output Format for EACH Question (JSON array):
      {
        "question": "Complex, thought-provoking question requiring deep analysis",
        "options": ["Sophisticated option 1", "Nuanced option 2", "Complex option 3", "Detailed option 4"],
        "correctAnswer": "The option that requires deepest understanding",
        "difficulty": "intermediate/advanced/expert",
        "questionType": "analytical/application/synthesis/evaluation/inference",
        "explanation": "Comprehensive explanation of why the answer is correct and detailed analysis of why each distractor is wrong",
        "cognitiveLevel": "The specific type of thinking required (e.g., 'causal analysis', 'pattern recognition', 'systems thinking')"
      }
      ''';

      final response = await _callOpenAI(
        model: 'gpt-4-turbo',
        messages: [
          {
            'role': 'system',
            'content':
                'You are a world-class educational assessment designer with expertise in cognitive science and advanced pedagogy. Your specialty is creating intellectually rigorous quiz questions that challenge even the most knowledgeable students and promote deep, critical thinking.'
          },
          {'role': 'user', 'content': prompt}
        ],
        temperature: 0.9,
        maxTokens: 3500,
      );

      // Parse and transform OpenAI response into QuizQuestions
      final List<dynamic> parsedQuestions = json.decode(response);

      return parsedQuestions.map((q) {
        final difficulty = _mapStringToDifficultyLevel(q['difficulty']);
        final questionType = _mapStringToQuestionType(q['questionType']);

        return QuizQuestion(
          id: uuid.v4(),
          question: q['question'],
          options: List<String>.from(q['options']),
          correctAnswer: q['correctAnswer'],
          difficulty: difficulty,
          type: questionType,
        );
      }).toList();
    } catch (e) {
      print('Quiz Generation Error: $e');
      return [];
    }
  }

  // Generate quiz questions from content
  Future<List<QuizQuestion>> generateQuizQuestions(
    String content,
    int count,
    String difficulty, {
    String?
        questionTypes, // e.g., "multipleChoice, trueFalse, fillInBlanks, scenario"
    String?
        cognitiveLevel, // e.g., "remember, understand, apply, analyze, evaluate, create"
    String?
        realWorldContext, // e.g., "business, healthcare, technology, daily life"
    String? challengeLevel, // e.g., "basic, intermediate, advanced, expert"
    String? learningStyle, // e.g., "visual, auditory, kinesthetic, reading"
    String? promptEnhancement, // Custom additional instructions
  }) async {
    try {
      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Call Cloud Function for secure API access
      final result = await _functions.httpsCallable('generateQuiz').call({
        'content': content,
        'questionCount': count,
        'type': 'multipleChoice',
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        try {
          final responseData = result.data as Map<String, dynamic>;
          if (responseData.containsKey('quiz')) {
            final quizData = responseData['quiz'] as Map<String, dynamic>;
            if (quizData.containsKey('questions')) {
              final questionsList = quizData['questions'] as List;
              return questionsList.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value as Map<String, dynamic>;

                return QuizQuestion(
                  id: 'generated_${DateTime.now().millisecondsSinceEpoch}_$index',
                  question:
                      data['question']?.toString() ?? 'Question not available',
                  options: List<String>.from(data['options'] ?? []),
                  correctAnswer: data['correctAnswer']?.toString() ?? '',
                  type:
                      QuestionType.multipleChoice, // Default to multiple choice
                );
              }).toList();
            }
          }
        } catch (parseError) {
          debugPrint('Error parsing quiz questions response: $parseError');
        }
      }

      // Fallback: return empty list if parsing fails
      return [];
    } catch (e) {
      debugPrint('Error generating quiz questions: $e');
      debugPrint('🔄 Attempting local fallback for quiz questions...');

      // Try local fallback when Cloud Functions fail
      try {
        return await LocalAIFallbackService.instance
            .generateQuizQuestions(content, count, difficulty);
      } catch (fallbackError) {
        debugPrint('❌ Local fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  // Check rate limiting
  bool _checkRateLimit() {
    final now = DateTime.now();

    if (_lastRequestTime == null) {
      _lastRequestTime = now;
      _requestCount = 1;
      return true;
    }

    final timeDiff = now.difference(_lastRequestTime!);

    if (timeDiff.inMinutes >= 1) {
      // Reset counter after 1 minute
      _lastRequestTime = now;
      _requestCount = 1;
      return true;
    }

    if (_requestCount >= _maxRequestsPerMinute) {
      return false;
    }

    _requestCount++;
    return true;
  }

  Future<String?> _makeSecureAPICall({
    required String content,
    required String materialType,
    required String difficulty,
  }) async {
    try {
      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Call Cloud Function for secure API access
      final result =
          await _functions.httpsCallable('generateStudyMaterial').call({
        'content': content,
        'materialType': materialType,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        final responseData = result.data as Map<String, dynamic>;
        return responseData['content'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Secure API call failed: $e');
      return null;
    }
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

  // Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isConfigured': true,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'requestCount': _requestCount,
      'maxRequestsPerMinute': _maxRequestsPerMinute,
      'canMakeRequest': _checkRateLimit(),
    };
  }

  // Convenience method for generating intelligent flashcards
  Future<List<Flashcard>> generateIntelligentFlashcards(
    String content,
    int count, {
    String difficulty = 'medium',
    String cognitiveLevel = 'analyze, evaluate, create',
    String realWorldContext = 'business, technology, daily life',
    String challengeLevel = 'intermediate',
  }) async {
    return generateFlashcardsFromContent(
      content,
      count,
      difficulty,
      questionTypes: 'concept, application, analysis, synthesis',
      cognitiveLevel: cognitiveLevel,
      realWorldContext: realWorldContext,
      challengeLevel: challengeLevel,
      learningStyle: 'visual, auditory, reading',
      promptEnhancement:
          'Focus on critical thinking and real-world applications',
    );
  }

  // Convenience method for generating challenging quiz questions
  Future<List<QuizQuestion>> generateChallengingQuiz(
    String content,
    int count, {
    String difficulty = 'hard',
    String cognitiveLevel = 'analyze, evaluate, create',
    String realWorldContext = 'business, healthcare, technology',
    String challengeLevel = 'advanced',
  }) async {
    return generateQuizQuestions(
      content,
      count,
      difficulty,
      questionTypes: 'multipleChoice, scenario, analysis',
      cognitiveLevel: cognitiveLevel,
      realWorldContext: realWorldContext,
      challengeLevel: challengeLevel,
      learningStyle: 'visual, reading',
      promptEnhancement:
          'Create questions that require deep understanding and application',
    );
  }

  // Build enhanced prompt for more intelligent content generation

  /// Map string difficulty to enum
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

  /// Map string question type to enum
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

  // Add a method to call OpenAI
  Future<String> _callOpenAI({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      // Implement actual OpenAI API call
      // This is a placeholder - replace with actual implementation
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_OPENAI_API_KEY',
        },
        body: json.encode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to call OpenAI API');
      }
    } catch (e) {
      print('OpenAI API Error: $e');
      rethrow;
    }
  }
}
