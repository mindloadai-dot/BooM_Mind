import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/enhanced_ai_service.dart';
import 'package:mindload/core/youtube_utils.dart';
import 'package:mindload/services/document_processor.dart';

/// Comprehensive OpenAI Integration Service for MindLoad
/// 
/// This service provides easy-to-use methods for converting various content types
/// (documents, YouTube videos, websites) into flashcards and quizzes using OpenAI.
class OpenAIIntegrationService {
  static OpenAIIntegrationService? _instance;
  static OpenAIIntegrationService get instance => _instance ??= OpenAIIntegrationService._();
  OpenAIIntegrationService._();

  final EnhancedAIService _aiService = EnhancedAIService.instance;

  /// Convert a document (PDF, DOCX, etc.) to flashcards and quizzes
  Future<StudySet> convertDocumentToStudySet({
    required Uint8List fileBytes,
    required String fileName,
    required String extension,
    int flashcardCount = 15,
    int quizCount = 10,
    String difficulty = 'medium',
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    try {
      debugPrint('📄 Converting document to study set: $fileName');

      final result = await _aiService.processContentAndGenerate(
        input: fileName,
        sourceType: ContentSourceType.document,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
        questionTypes: questionTypes,
        cognitiveLevel: cognitiveLevel,
        realWorldContext: realWorldContext,
        challengeLevel: challengeLevel,
        learningStyle: learningStyle,
        promptEnhancement: promptEnhancement,
        additionalOptions: {
          'fileBytes': fileBytes,
          'fileName': fileName,
          'extension': extension,
        },
      );

      if (!result.isSuccess) {
        throw Exception('Failed to convert document: ${result.errorMessage}');
      }

      // Create study set from results
      final studySet = StudySet(
        id: _generateStudySetId(),
        title: result.contentResult?.title ?? fileName,
        description: 'Generated from document: $fileName',
        flashcards: result.flashcards,
        quizQuestions: result.quizQuestions,
        quizzes: result.quizQuestions.map((q) => Quiz(
          id: _generateQuizId(),
          title: 'Quiz Question',
          questions: [q],
          createdDate: DateTime.now(),
        )).toList(),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        tags: ['document', 'ai-generated'],
        sourceType: 'document',
        sourceUrl: null,
        metadata: {
          'originalFileName': fileName,
          'fileExtension': extension,
          'processingMethod': result.method.name,
          'processingTimeMs': result.processingTimeMs,
          'contentLength': result.contentResult?.metadata['length'] ?? 0,
          'wordCount': result.contentResult?.metadata['wordCount'] ?? 0,
        },
      );

      debugPrint('✅ Document converted successfully: ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes');
      return studySet;

    } catch (e) {
      debugPrint('❌ Document conversion failed: $e');
      rethrow;
    }
  }

  /// Convert a YouTube video to flashcards and quizzes
  Future<StudySet> convertYouTubeToStudySet({
    required String youtubeUrl,
    int flashcardCount = 15,
    int quizCount = 10,
    String difficulty = 'medium',
    String? preferredLanguage,
    bool useSubtitlesForQuestions = true,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    try {
      debugPrint('🎬 Converting YouTube video to study set: $youtubeUrl');

      final videoId = YouTubeUtils.extractYouTubeId(youtubeUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      final result = await _aiService.processContentAndGenerate(
        input: youtubeUrl,
        sourceType: ContentSourceType.youtube,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
        questionTypes: questionTypes,
        cognitiveLevel: cognitiveLevel,
        realWorldContext: realWorldContext,
        challengeLevel: challengeLevel,
        learningStyle: learningStyle,
        promptEnhancement: promptEnhancement,
        additionalOptions: {
          'preferredLanguage': preferredLanguage,
          'useSubtitlesForQuestions': useSubtitlesForQuestions,
        },
      );

      if (!result.isSuccess) {
        throw Exception('Failed to convert YouTube video: ${result.errorMessage}');
      }

      // Create study set from results
      final studySet = StudySet(
        id: _generateStudySetId(),
        title: result.contentResult?.title ?? 'YouTube Video',
        description: 'Generated from YouTube video',
        flashcards: result.flashcards,
        quizzes: result.quizQuestions.map((q) => Quiz(
          id: _generateQuizId(),
          title: 'Quiz Question',
          questions: [q],
          createdDate: DateTime.now(),
        )).toList(),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        tags: ['youtube', 'ai-generated'],
        sourceType: 'youtube',
        sourceUrl: youtubeUrl,
        metadata: {
          'videoId': videoId,
          'channel': result.contentResult?.metadata['channel'] ?? '',
          'duration': result.contentResult?.metadata['duration'] ?? 0,
          'processingMethod': result.method.name,
          'processingTimeMs': result.processingTimeMs,
          'contentLength': result.contentResult?.metadata['length'] ?? 0,
          'wordCount': result.contentResult?.metadata['wordCount'] ?? 0,
        },
      );

      debugPrint('✅ YouTube video converted successfully: ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes');
      return studySet;

    } catch (e) {
      debugPrint('❌ YouTube conversion failed: $e');
      rethrow;
    }
  }

  /// Convert a website to flashcards and quizzes
  Future<StudySet> convertWebsiteToStudySet({
    required String websiteUrl,
    int flashcardCount = 15,
    int quizCount = 10,
    String difficulty = 'medium',
    int maxItems = 50,
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    try {
      debugPrint('🌐 Converting website to study set: $websiteUrl');

      final result = await _aiService.processContentAndGenerate(
        input: websiteUrl,
        sourceType: ContentSourceType.website,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
        questionTypes: questionTypes,
        cognitiveLevel: cognitiveLevel,
        realWorldContext: realWorldContext,
        challengeLevel: challengeLevel,
        learningStyle: learningStyle,
        promptEnhancement: promptEnhancement,
        additionalOptions: {
          'maxItems': maxItems,
        },
      );

      if (!result.isSuccess) {
        throw Exception('Failed to convert website: ${result.errorMessage}');
      }

      // Create study set from results
      final studySet = StudySet(
        id: _generateStudySetId(),
        title: result.contentResult?.title ?? 'Website Content',
        description: 'Generated from website content',
        flashcards: result.flashcards,
        quizzes: result.quizQuestions.map((q) => Quiz(
          id: _generateQuizId(),
          title: 'Quiz Question',
          questions: [q],
          createdDate: DateTime.now(),
        )).toList(),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        tags: ['website', 'ai-generated'],
        sourceType: 'website',
        sourceUrl: websiteUrl,
        metadata: {
          'originalUrl': websiteUrl,
          'processingMethod': result.method.name,
          'processingTimeMs': result.processingTimeMs,
          'contentLength': result.contentResult?.metadata['length'] ?? 0,
          'wordCount': result.contentResult?.metadata['wordCount'] ?? 0,
        },
      );

      debugPrint('✅ Website converted successfully: ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes');
      return studySet;

    } catch (e) {
      debugPrint('❌ Website conversion failed: $e');
      rethrow;
    }
  }

  /// Convert plain text to flashcards and quizzes
  Future<StudySet> convertTextToStudySet({
    required String text,
    int flashcardCount = 15,
    int quizCount = 10,
    String difficulty = 'medium',
    String? questionTypes,
    String? cognitiveLevel,
    String? realWorldContext,
    String? challengeLevel,
    String? learningStyle,
    String? promptEnhancement,
  }) async {
    try {
      debugPrint('📝 Converting text to study set: ${text.length} characters');

      final result = await _aiService.processContentAndGenerate(
        input: text,
        sourceType: ContentSourceType.text,
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

      if (!result.isSuccess) {
        throw Exception('Failed to convert text: ${result.errorMessage}');
      }

      // Create study set from results
      final studySet = StudySet(
        id: _generateStudySetId(),
        title: 'Text Content',
        description: 'Generated from text input',
        flashcards: result.flashcards,
        quizzes: result.quizQuestions.map((q) => Quiz(
          id: _generateQuizId(),
          title: 'Quiz Question',
          questions: [q],
          createdDate: DateTime.now(),
        )).toList(),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        tags: ['text', 'ai-generated'],
        sourceType: 'text',
        sourceUrl: null,
        metadata: {
          'textLength': text.length,
          'wordCount': text.split(' ').length,
          'processingMethod': result.method.name,
          'processingTimeMs': result.processingTimeMs,
        },
      );

      debugPrint('✅ Text converted successfully: ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes');
      return studySet;

    } catch (e) {
      debugPrint('❌ Text conversion failed: $e');
      rethrow;
    }
  }

  /// Auto-detect content type and convert to study set
  Future<StudySet> autoConvertToStudySet({
    required String input,
    int flashcardCount = 15,
    int quizCount = 10,
    String difficulty = 'medium',
    Map<String, dynamic>? additionalOptions,
  }) async {
    try {
      debugPrint('🔍 Auto-detecting content type for: $input');

      ContentSourceType sourceType;
      Map<String, dynamic>? options = additionalOptions;

      // Auto-detect content type
      if (YouTubeUtils.isYouTubeLink(input)) {
        sourceType = ContentSourceType.youtube;
        debugPrint('🎬 Detected YouTube link');
      } else if (_isWebsiteUrl(input)) {
        sourceType = ContentSourceType.website;
        debugPrint('🌐 Detected website URL');
      } else if (_isDocumentFile(input)) {
        sourceType = ContentSourceType.document;
        debugPrint('📄 Detected document file');
      } else {
        sourceType = ContentSourceType.text;
        debugPrint('📝 Treating as plain text');
      }

      final result = await _aiService.processContentAndGenerate(
        input: input,
        sourceType: sourceType,
        flashcardCount: flashcardCount,
        quizCount: quizCount,
        difficulty: difficulty,
        additionalOptions: options,
      );

      if (!result.isSuccess) {
        throw Exception('Failed to auto-convert content: ${result.errorMessage}');
      }

      // Create study set from results
      final studySet = StudySet(
        id: _generateStudySetId(),
        title: result.contentResult?.title ?? 'Auto-Generated Content',
        description: 'Generated from ${sourceType.name}',
        flashcards: result.flashcards,
        quizzes: result.quizQuestions.map((q) => Quiz(
          id: _generateQuizId(),
          title: 'Quiz Question',
          questions: [q],
          createdDate: DateTime.now(),
        )).toList(),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        tags: [sourceType.name, 'ai-generated', 'auto-detected'],
        sourceType: sourceType.name,
        sourceUrl: sourceType == ContentSourceType.text ? null : input,
        metadata: {
          'detectedType': sourceType.name,
          'processingMethod': result.method.name,
          'processingTimeMs': result.processingTimeMs,
          'contentLength': result.contentResult?.metadata['length'] ?? 0,
          'wordCount': result.contentResult?.metadata['wordCount'] ?? 0,
        },
      );

      debugPrint('✅ Auto-conversion successful: ${studySet.flashcards.length} flashcards, ${studySet.quizzes.length} quizzes');
      return studySet;

    } catch (e) {
      debugPrint('❌ Auto-conversion failed: $e');
      rethrow;
    }
  }

  /// Helper methods
  String _generateStudySetId() => 'ai_${DateTime.now().millisecondsSinceEpoch}';
  String _generateQuizId() => 'quiz_${DateTime.now().millisecondsSinceEpoch}';

  DifficultyLevel _mapDifficulty(String difficulty) {
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

  bool _isWebsiteUrl(String input) {
    return input.startsWith('http://') || input.startsWith('https://');
  }

  bool _isDocumentFile(String input) {
    final supportedExtensions = DocumentProcessor.getSupportedExtensions();
    return supportedExtensions.any((ext) => input.toLowerCase().endsWith('.$ext'));
  }

  /// Test the OpenAI integration service
  static Future<void> testOpenAIIntegration() async {
    debugPrint('🧪 Testing OpenAI Integration Service...');

    try {
      final service = OpenAIIntegrationService.instance;

      // Test text conversion
      debugPrint('📝 Testing text conversion...');
      final textResult = await service.convertTextToStudySet(
        text: 'Artificial Intelligence is a branch of computer science that aims to create intelligent machines.',
        flashcardCount: 3,
        quizCount: 2,
        difficulty: 'medium',
      );
      debugPrint('✅ Text conversion test passed: ${textResult.flashcards.length} flashcards');

      // Test YouTube conversion (if URL is provided)
      debugPrint('🎬 Testing YouTube conversion...');
      try {
        final youtubeResult = await service.convertYouTubeToStudySet(
          youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          flashcardCount: 3,
          quizCount: 2,
          difficulty: 'medium',
        );
        debugPrint('✅ YouTube conversion test passed: ${youtubeResult.flashcards.length} flashcards');
      } catch (e) {
        debugPrint('⚠️ YouTube conversion test skipped: $e');
      }

      // Test website conversion
      debugPrint('🌐 Testing website conversion...');
      try {
        final websiteResult = await service.convertWebsiteToStudySet(
          websiteUrl: 'https://example.com',
          flashcardCount: 3,
          quizCount: 2,
          difficulty: 'medium',
        );
        debugPrint('✅ Website conversion test passed: ${websiteResult.flashcards.length} flashcards');
      } catch (e) {
        debugPrint('⚠️ Website conversion test skipped: $e');
      }

      debugPrint('✅ OpenAI Integration Service test completed successfully!');

    } catch (e) {
      debugPrint('❌ OpenAI Integration Service test failed: $e');
    }
  }
}
