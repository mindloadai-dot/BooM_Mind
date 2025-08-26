import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mindload/models/study_data.dart';

import 'package:mindload/config/openai_config.dart';

class OpenAIService {
  // Use the API key from the configuration file
  static String get _apiKey => OpenAIConfig.apiKey;
  static const String _endpoint = OpenAIConfig.apiEndpoint;

  static OpenAIService? _instance;
  static OpenAIService get instance => _instance ??= OpenAIService._();
  OpenAIService._();

  // Rate limiting state
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const int _maxRequestsPerMinute =
      20; // Conservative limit for GPT-4o-mini

  // Method overload for generation dialog - returns flashcards from content
  Future<List<Flashcard>> generateFlashcardsFromContent(
    String content,
    int count,
    String difficulty,
  ) async {
    try {
      final prompt = '''
Generate $count flashcards from the following content. 
Difficulty level: $difficulty

Content:
$content

Generate flashcards in this exact JSON format:
{
  "flashcards": [
    {
      "question": "Question text here",
      "answer": "Answer text here",
      "difficulty": "$difficulty"
    }
  ]
}

Make sure the questions are clear, educational, and cover key concepts from the content.
''';

      final response = await _makeAPICall(
        messages: [
          {
            'role': 'system',
            'content': 'You are an expert educator creating flashcards.'
          },
          {'role': 'user', 'content': prompt},
        ],
        responseFormat: {'type': 'json_object'},
      );

      if (response != null) {
        try {
          final jsonResponse = json.decode(response);
          if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('flashcards')) {
            final flashcardsList = jsonResponse['flashcards'] as List;
            return flashcardsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              // Create a Flashcard with generated ID and safe parsing
              return Flashcard(
                id: 'fc_${DateTime.now().millisecondsSinceEpoch}_$index',
                question: data['question']?.toString() ?? 'Question $index',
                answer: data['answer']?.toString() ?? 'Answer $index',
                difficulty: _parseDifficulty(
                    data['difficulty']?.toString() ?? difficulty),
              );
            }).toList();
          } else if (jsonResponse is List) {
            return jsonResponse.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              return Flashcard(
                id: 'fc_${DateTime.now().millisecondsSinceEpoch}_$index',
                question: data['question']?.toString() ?? 'Question $index',
                answer: data['answer']?.toString() ?? 'Answer $index',
                difficulty: _parseDifficulty(
                    data['difficulty']?.toString() ?? difficulty),
              );
            }).toList();
          } else {
            throw Exception('Unexpected response format');
          }
        } catch (parseError) {
          debugPrint('Failed to parse flashcards response: $parseError');
          debugPrint('Raw response: $response');
          throw Exception('Failed to parse AI response');
        }
      } else {
        throw Exception('No response from AI service');
      }
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }

  // Method overload for generation dialog - returns quiz questions from content
  Future<List<QuizQuestion>> generateQuizQuestionsFromContent(
    String content,
    int count,
    String difficulty,
  ) async {
    try {
      final prompt = '''
Generate $count multiple choice quiz questions from the following content.
Difficulty level: $difficulty

Content:
$content

Generate quiz questions in this exact JSON format:
{
  "quizQuestions": [
    {
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": 0,
      "explanation": "Explanation of why this is correct",
      "difficulty": "$difficulty"
    }
  ]
}

Make sure the questions are clear, educational, and cover key concepts from the content.
The correctAnswer should be the index (0-3) of the correct option.
''';

      final response = await _makeAPICall(
        messages: [
          {
            'role': 'system',
            'content': 'You are an expert educator creating quiz questions.'
          },
          {'role': 'user', 'content': prompt},
        ],
        responseFormat: {'type': 'json_object'},
      );

      if (response != null) {
        try {
          final jsonResponse = json.decode(response);
          if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('quizQuestions')) {
            final questionsList = jsonResponse['quizQuestions'] as List;
            return questionsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              // Create a QuizQuestion with generated ID and safe parsing
              final correctAnswerIndex =
                  int.tryParse(data['correctAnswer']?.toString() ?? '0') ?? 0;
              final options = List<String>.from(data['options'] ??
                  ['Option A', 'Option B', 'Option C', 'Option D']);
              final correctAnswerText =
                  options.isNotEmpty && correctAnswerIndex < options.length
                      ? options[correctAnswerIndex]
                      : 'Option A';

              return QuizQuestion(
                id: 'qq_${DateTime.now().millisecondsSinceEpoch}_$index',
                question: data['question']?.toString() ?? 'Question $index',
                options: options,
                correctAnswer: correctAnswerText,
                type: QuizType.multipleChoice,
              );
            }).toList();
          } else if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('questions')) {
            final questionsList = jsonResponse['questions'] as List;
            return questionsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              final correctAnswerIndex =
                  int.tryParse(data['correctAnswer']?.toString() ?? '0') ?? 0;
              final options = List<String>.from(data['options'] ??
                  ['Option A', 'Option B', 'Option C', 'Option D']);
              final correctAnswerText =
                  options.isNotEmpty && correctAnswerIndex < options.length
                      ? options[correctAnswerIndex]
                      : 'Option A';

              return QuizQuestion(
                id: 'qq_${DateTime.now().millisecondsSinceEpoch}_$index',
                question: data['question']?.toString() ?? 'Question $index',
                options: options,
                correctAnswer: correctAnswerText,
                type: QuizType.multipleChoice,
              );
            }).toList();
          } else if (jsonResponse is List) {
            return jsonResponse.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              final correctAnswerIndex =
                  int.tryParse(data['correctAnswer']?.toString() ?? '0') ?? 0;
              final options = List<String>.from(data['options'] ??
                  ['Option A', 'Option B', 'Option C', 'Option D']);
              final correctAnswerText =
                  options.isNotEmpty && correctAnswerIndex < options.length
                      ? options[correctAnswerIndex]
                      : 'Option A';

              return QuizQuestion(
                id: 'qq_${DateTime.now().millisecondsSinceEpoch}_$index',
                question: data['question']?.toString() ?? 'Question $index',
                options: options,
                correctAnswer: correctAnswerText,
                type: QuizType.multipleChoice,
              );
            }).toList();
          } else {
            throw Exception('Unexpected response format');
          }
        } catch (parseError) {
          debugPrint('Failed to parse quiz questions response: $parseError');
          debugPrint('Raw response: $response');
          throw Exception('Failed to parse AI response');
        }
      } else {
        throw Exception('No response from AI service');
      }
    } catch (e) {
      debugPrint('Error generating quiz questions: $e');
      rethrow;
    }
  }

  // Legacy methods for compatibility
  Future<List<Flashcard>> generateFlashcards(String content,
      {int count = 10, String model = 'gpt-4o-mini'}) async {
    return generateFlashcardsFromContent(content, count, 'medium');
  }

  Future<List<QuizQuestion>> generateQuiz(String content,
      {int count = 10, String model = 'gpt-4o-mini'}) async {
    return generateQuizQuestionsFromContent(content, count, 'medium');
  }

  Future<Quiz> generateQuizFromContent(
      String content, String title, QuizType type,
      {int count = 10, String model = 'gpt-4o-mini'}) async {
    try {
      String typeInstructions;
      switch (type) {
        case QuizType.multipleChoice:
          typeInstructions =
              'Create multiple choice questions with 4 options each. Mark the correct answer clearly.';
          break;
        case QuizType.trueFalse:
          typeInstructions = 'Create true/false questions.';
          break;
        case QuizType.shortAnswer:
          typeInstructions =
              'Create short answer questions that require 1-3 word responses.';
          break;
      }

      final basePrompt = '''
Create exactly $count quiz questions from the following content.
Return the result as a JSON object with this structure:
{
  "questions": [
    {
      "question": "question text",
      "options": ["option1", "option2", "option3", "option4"],
      "correctAnswer": "correct answer"
    }
  ]
}

For true/false questions, use options: ["True", "False"]
For short answer questions, use options: [] (empty array)

Content to process:
''';

      final response = await _makeAPICall(
        messages: [
          {
            'role': 'system',
            'content':
                'You are an expert educator creating quiz questions. $typeInstructions Output your response as a JSON object.'
          },
          {'role': 'user', 'content': '$basePrompt\n\n$content'},
        ],
        responseFormat: {'type': 'json_object'},
      );

      if (response == null) {
        return _generateFallbackQuiz(title, type);
      }

      final jsonResponse = json.decode(response);
      final questionsData = jsonResponse['questions'] as List?;

      if (questionsData == null || questionsData.isEmpty) {
        return _generateFallbackQuiz(title, type);
      }

      final questions = questionsData.map((data) {
        // Handle numeric correctAnswer by converting to actual answer text
        String correctAnswerText;
        final options = List<String>.from(data['options'] ?? []);
        final correctAnswer = data['correctAnswer'];

        if (correctAnswer is int ||
            (correctAnswer is String && int.tryParse(correctAnswer) != null)) {
          // Numeric answer - convert to text
          final index = int.tryParse(correctAnswer.toString()) ?? 0;
          correctAnswerText = options.isNotEmpty && index < options.length
              ? options[index]
              : options.isNotEmpty
                  ? options[0]
                  : 'Answer';
        } else {
          // Text answer - use as is
          correctAnswerText = correctAnswer?.toString() ?? 'Answer';
        }

        return QuizQuestion(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_${questionsData.indexOf(data)}',
          question: data['question'],
          options: options,
          correctAnswer: correctAnswerText,
          type: type,
        );
      }).toList();

      final quiz = Quiz(
        id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        title: '$title - ${_getQuizTypeDisplayName(type)} Quiz',
        questions: questions,
        type: type,
        results: [],
        createdDate: DateTime.now(),
      );

      return quiz;
    } catch (e) {
      debugPrint('Error generating quiz: $e');
      return _generateFallbackQuiz(title, type);
    }
  }

  Future<String> generateStudyTips(String subject) async {
    try {
      const prompt =
          'Provide 3-5 concise study tips for the following subject. Keep each tip under 50 words.';

      final response = await _makeAPICall(
        messages: [
          {
            'role': 'system',
            'content':
                'You are a study advisor providing helpful learning tips.'
          },
          {'role': 'user', 'content': '$prompt\n\nSubject: $subject'},
        ],
      );

      return response ??
          'Focus on understanding concepts rather than memorization. Practice active recall and spaced repetition. Take regular breaks during study sessions.';
    } catch (e) {
      debugPrint('Error generating study tips: $e');
      return 'Focus on understanding concepts rather than memorization. Practice active recall and spaced repetition. Take regular breaks during study sessions.';
    }
  }

  /// Check rate limiting before making API calls
  bool _checkRateLimit() {
    final now = DateTime.now();

    // Reset counter if a minute has passed
    if (_lastRequestTime == null ||
        now.difference(_lastRequestTime!).inMinutes >= 1) {
      _requestCount = 0;
      _lastRequestTime = now;
    }

    // Check if we're under the limit
    if (_requestCount >= _maxRequestsPerMinute) {
      return false;
    }

    _requestCount++;
    return true;
  }

  Future<String?> _makeAPICall({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? responseFormat,
  }) async {
    try {
      // Check rate limiting
      if (!_checkRateLimit()) {
        debugPrint('Rate limit exceeded, please wait a moment and try again');
        throw Exception(
            'Rate limit exceeded. Please wait a moment and try again.');
      }

      // Budget checking is now handled by MindloadEconomyService at the application level

      final requestBody = {
        'model': OpenAIConfig.defaultModel, // Use GPT-4o-mini as default
        'messages': messages,
        'max_tokens': OpenAIConfig.maxTokensPerRequest,
        'temperature': OpenAIConfig.defaultTemperature,
      };

      if (responseFormat != null) {
        requestBody['response_format'] = responseFormat;
      }

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              if (OpenAIConfig.organizationId != null)
                'OpenAI-Organization': OpenAIConfig.organizationId!,
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: OpenAIConfig.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        final content = jsonResponse['choices'][0]['message']['content'];

        // Token usage is now tracked by MindloadEconomyService at the application level

        return content;
      } else if (response.statusCode == 429) {
        // Handle rate limiting from the API - wait and retry with exponential backoff
        debugPrint('API rate limit exceeded, waiting before retry...');
        await Future.delayed(const Duration(seconds: 5));

        // Try one more time
        try {
          final retryResponse = await http
              .post(
                Uri.parse(_endpoint),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_apiKey',
                  if (OpenAIConfig.organizationId != null)
                    'OpenAI-Organization': OpenAIConfig.organizationId!,
                },
                body: json.encode(requestBody),
              )
              .timeout(Duration(seconds: OpenAIConfig.requestTimeoutSeconds));

          if (retryResponse.statusCode == 200) {
            final jsonResponse =
                json.decode(utf8.decode(retryResponse.bodyBytes));
            final content = jsonResponse['choices'][0]['message']['content'];
            return content;
          }
        } catch (retryError) {
          debugPrint('Retry failed: $retryError');
        }

        // If retry fails, throw rate limit error
        throw Exception(
            'API rate limit exceeded. Please wait a moment and try again.');
      } else {
        debugPrint(
          'OpenAI API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('AI service error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAI API call failed: $e');

      if (e.toString().contains('rate limit') ||
          e.toString().contains('credits')) {
        rethrow; // Re-throw credit/rate limit errors
      }
      // Re-throw all errors to prevent silent failures
      rethrow;
    }
  }

  // Helper methods for fallback content
  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium;
    }
  }

  String _getQuizTypeDisplayName(QuizType type) {
    switch (type) {
      case QuizType.multipleChoice:
        return 'Multiple Choice';
      case QuizType.trueFalse:
        return 'True/False';
      case QuizType.shortAnswer:
        return 'Short Answer';
    }
  }

  List<QuizQuestion> _generateFallbackQuizQuestions() {
    final baseId = DateTime.now().millisecondsSinceEpoch;

    return [
      QuizQuestion(
        id: 'qq_${baseId}_1',
        question: 'What is the best approach to studying new material?',
        options: [
          'Active reading and note-taking',
          'Passive reading only',
          'Memorizing without understanding',
          'Skipping difficult sections'
        ],
        correctAnswer: 'Active reading and note-taking',
        type: QuizType.multipleChoice,
      ),
      QuizQuestion(
        id: 'qq_${baseId}_2',
        question:
            'Which study technique is most effective for long-term retention?',
        options: [
          'Cramming before exams',
          'Spaced repetition',
          'Single intensive session',
          'Reading once'
        ],
        correctAnswer: 'Spaced repetition',
        type: QuizType.multipleChoice,
      ),
      QuizQuestion(
        id: 'qq_${baseId}_3',
        question: 'What should you do when you encounter difficult concepts?',
        options: [
          'Skip them entirely',
          'Break them into smaller parts',
          'Give up immediately',
          'Memorize without understanding'
        ],
        correctAnswer: 'Break them into smaller parts',
        type: QuizType.multipleChoice,
      ),
    ];
  }

  List<Flashcard> _generateFallbackFlashcards(String title) {
    final baseId = DateTime.now().millisecondsSinceEpoch;
    final titleWords = title.toLowerCase().split(' ');
    final subject = titleWords.isNotEmpty ? titleWords[0] : 'study';

    return [
      Flashcard(
        id: 'fc_${baseId}_1',
        question: 'What is the main topic of $title?',
        answer:
            'This study set focuses on $subject and its key concepts. Review the content to understand the fundamental principles.',
        difficulty: DifficultyLevel.easy,
      ),
      Flashcard(
        id: 'fc_${baseId}_2',
        question: 'Name a key concept from $title',
        answer:
            'The content covers important aspects of $subject that are essential for understanding this topic.',
        difficulty: DifficultyLevel.medium,
      ),
      Flashcard(
        id: 'fc_${baseId}_3',
        question: 'Why is understanding $subject important?',
        answer:
            'Understanding $subject helps build foundational knowledge and provides context for more advanced topics.',
        difficulty: DifficultyLevel.medium,
      ),
      Flashcard(
        id: 'fc_${baseId}_4',
        question: 'How can you apply knowledge from $title?',
        answer:
            'The concepts from $subject can be applied in practical situations and serve as building blocks for further learning.',
        difficulty: DifficultyLevel.hard,
      ),
      Flashcard(
        id: 'fc_${baseId}_5',
        question: 'What are the benefits of studying $subject?',
        answer:
            'Studying $subject develops critical thinking skills and provides valuable insights for academic and professional growth.',
        difficulty: DifficultyLevel.medium,
      ),
    ];
  }

  Quiz _generateFallbackQuiz(String title, QuizType type) {
    final baseId = DateTime.now().millisecondsSinceEpoch;
    final titleWords = title.toLowerCase().split(' ');
    final subject = titleWords.isNotEmpty ? titleWords[0] : 'study';

    List<QuizQuestion> questions;

    switch (type) {
      case QuizType.multipleChoice:
        questions = [
          QuizQuestion(
            id: 'q_${baseId}_1',
            question: 'What is the primary focus of $title?',
            options: [
              'Understanding $subject concepts',
              'Memorizing unrelated facts',
              'Ignoring key principles',
              'Avoiding the topic entirely'
            ],
            correctAnswer: 'Understanding $subject concepts',
            type: QuizType.multipleChoice,
          ),
          QuizQuestion(
            id: 'q_${baseId}_2',
            question: 'How should you approach studying $subject?',
            options: [
              'Skip reading the material',
              'Focus only on memorization',
              'Understand concepts and practice regularly',
              'Study only before exams'
            ],
            correctAnswer: 'Understand concepts and practice regularly',
            type: QuizType.multipleChoice,
          ),
          QuizQuestion(
            id: 'q_${baseId}_3',
            question: 'What is a good study strategy for $subject?',
            options: [
              'Cramming all information at once',
              'Active recall and spaced repetition',
              'Reading notes passively',
              'Studying without breaks'
            ],
            correctAnswer: 'Active recall and spaced repetition',
            type: QuizType.multipleChoice,
          ),
        ];
        break;

      case QuizType.trueFalse:
        questions = [
          QuizQuestion(
            id: 'q_${baseId}_1',
            question: 'Regular practice is important for mastering $subject',
            options: ['True', 'False'],
            correctAnswer: 'True',
            type: QuizType.trueFalse,
          ),
          QuizQuestion(
            id: 'q_${baseId}_2',
            question:
                'Understanding concepts is more important than memorizing facts in $subject',
            options: ['True', 'False'],
            correctAnswer: 'True',
            type: QuizType.trueFalse,
          ),
          QuizQuestion(
            id: 'q_${baseId}_3',
            question: 'You can master $subject without consistent study habits',
            options: ['True', 'False'],
            correctAnswer: 'False',
            type: QuizType.trueFalse,
          ),
        ];
        break;

      case QuizType.shortAnswer:
        questions = [
          QuizQuestion(
            id: 'q_${baseId}_1',
            question: 'Name one key aspect of $title',
            options: [],
            correctAnswer: subject,
            type: QuizType.shortAnswer,
          ),
          QuizQuestion(
            id: 'q_${baseId}_2',
            question: 'What study method works best for $subject?',
            options: [],
            correctAnswer: 'Practice',
            type: QuizType.shortAnswer,
          ),
          QuizQuestion(
            id: 'q_${baseId}_3',
            question: 'Why is $subject important to learn?',
            options: [],
            correctAnswer: 'Foundation',
            type: QuizType.shortAnswer,
          ),
        ];
        break;
    }

    return Quiz(
      id: 'quiz_$baseId',
      title: '$title - ${_getQuizTypeDisplayName(type)} Quiz',
      questions: questions,
      type: type,
      results: [],
      createdDate: DateTime.now(),
    );
  }
}
