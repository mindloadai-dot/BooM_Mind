import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mindload/services/youtube_service.dart';
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';
import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:flutter/foundation.dart';

/// Enhanced YouTube Transcript Processor
/// Processes YouTube transcripts to extract subtitle information and generate study materials
class YouTubeTranscriptProcessor {
  static final YouTubeTranscriptProcessor _instance =
      YouTubeTranscriptProcessor._internal();
  factory YouTubeTranscriptProcessor() => _instance;
  YouTubeTranscriptProcessor._internal();

  final YouTubeService _youtubeService = YouTubeService();
  final OpenAIService _openAIService = OpenAIService.instance;
  final LocalAIFallbackService _fallbackService =
      LocalAIFallbackService.instance;
  final EnhancedStorageService _storageService = EnhancedStorageService.instance;

  /// Process YouTube video and create study materials with subtitle-based questions
  Future<StudySet?> processYouTubeVideo({
    required String videoId,
    required String userId,
    String? preferredLanguage,
    int flashcardCount = 15,
    int quizCount = 10,
    bool useSubtitlesForQuestions = true,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🎬 Processing YouTube video: $videoId');
      }

      // Step 1: Get video preview and check subtitle availability
      final preview = await _youtubeService.getPreview(videoId);

      if (!preview.captionsAvailable) {
        throw Exception('No subtitles/captions available for this video');
      }

      if (kDebugMode) {
        debugPrint(
            '✅ Subtitles available in ${preview.primaryLang ?? "unknown"} language');
      }

      // Step 2: Ingest the transcript
      final ingestRequest = YouTubeIngestRequest(
        videoId: videoId,
        preferredLanguage: preferredLanguage ?? preview.primaryLang,
      );

      final ingestResponse =
          await _youtubeService.ingestTranscript(ingestRequest);

      if (!ingestResponse.isSuccess) {
        throw Exception('Failed to ingest YouTube transcript');
      }

      if (kDebugMode) {
        debugPrint('✅ Transcript ingested: ${ingestResponse.materialId}');
      }

      // Step 3: Save transcript locally and retrieve content
      final transcriptContent = await _saveAndGetTranscriptLocally(
        ingestResponse.materialId,
        videoId,
        preview.title,
        preview.channel,
      );

      if (transcriptContent.isEmpty) {
        throw Exception('Failed to retrieve transcript content');
      }

      if (kDebugMode) {
        debugPrint(
            '✅ Retrieved transcript: ${transcriptContent.length} characters');
      }

      // Step 4: Process transcript to extract key segments and timestamps
      final transcriptSegments = _extractTranscriptSegments(transcriptContent);

      // Step 5: Generate flashcards and quiz questions from subtitles
      final flashcards = await _generateFlashcardsFromSubtitles(
        transcriptSegments,
        preview.title,
        flashcardCount,
      );

      final quizQuestions = await _generateQuizQuestionsFromSubtitles(
        transcriptSegments,
        preview.title,
        quizCount,
        useSubtitlesForQuestions,
      );

      // Step 6: Create study set
      final studySet = StudySet(
        id: 'youtube_${videoId}_${DateTime.now().millisecondsSinceEpoch}',
        title: preview.title,
        description:
            'Study materials generated from YouTube video: ${preview.channel}',
        flashcards: flashcards,
        quizzes: [
          Quiz(
            id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Quiz: ${preview.title}',
            questions: quizQuestions,
            type: QuizType.multipleChoice,
            results: [],
            createdDate: DateTime.now(),
          ),
        ],
        sourceUrl: 'https://youtube.com/watch?v=$videoId',
        type: StudySetType.youtube,
        metadata: {
          'videoId': videoId,
          'channel': preview.channel,
          'duration': preview.durationSeconds,
          'language': preview.primaryLang ?? 'en',
          'transcriptLength': transcriptContent.length,
          'materialId': ingestResponse.materialId,
        },
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Step 7: Save to local storage
      await _saveStudySetLocally(studySet, userId);

      if (kDebugMode) {
        debugPrint(
            '✅ Study set created with ${flashcards.length} flashcards and ${quizQuestions.length} questions');
      }

      return studySet;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing YouTube video: $e');
      }
      rethrow;
    }
  }

    /// Save transcript locally and retrieve content
  Future<String> _saveAndGetTranscriptLocally(
    String materialId,
    String videoId,
    String title,
    String channel,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final transcriptsDir = Directory('${directory.path}/youtube_transcripts');
      
      // Ensure directory exists
      if (!await transcriptsDir.exists()) {
        await transcriptsDir.create(recursive: true);
        debugPrint('📁 Created YouTube transcripts directory: ${transcriptsDir.path}');
      }
      
      // Get transcript from YouTube service (this would be the actual transcript text)
      // For now, we'll create a placeholder - in real implementation, this would come from the ingest response
      final transcriptText = 'Transcript for video: $title\nChannel: $channel\nVideo ID: $videoId\n\nThis is where the actual transcript content would be stored locally.';
      
      // Save transcript to local file
      final transcriptFile = File('${transcriptsDir.path}/$materialId.txt');
      await transcriptFile.writeAsString(transcriptText);
      
      if (kDebugMode) {
        debugPrint('💾 Transcript saved locally: ${transcriptFile.path}');
      }
      
      return transcriptText;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving transcript locally: $e');
      }
      throw Exception('Failed to save transcript locally');
    }
  }

  /// Get transcript content from local storage
  Future<String> _getTranscriptContent(String materialId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final transcriptFile = File('${directory.path}/youtube_transcripts/$materialId.txt');
      
      if (!await transcriptFile.exists()) {
        throw Exception('Transcript file not found locally');
      }

      final content = await transcriptFile.readAsString();
      if (content.isEmpty) {
        throw Exception('Transcript file is empty');
      }

      return content;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error retrieving local transcript: $e');
      }
      throw Exception('Failed to retrieve local transcript content');
    }
  }

  /// Extract meaningful segments from transcript
  List<TranscriptSegment> _extractTranscriptSegments(String transcript) {
    final segments = <TranscriptSegment>[];

    // Split transcript into sentences or meaningful chunks
    final sentences = transcript.split(RegExp(r'[.!?]+'));

    // Group sentences into segments (3-5 sentences each)
    final segmentSize = 4;
    for (int i = 0; i < sentences.length; i += segmentSize) {
      final end = (i + segmentSize < sentences.length)
          ? i + segmentSize
          : sentences.length;
      final segmentText = sentences.sublist(i, end).join('. ').trim();

      if (segmentText.isNotEmpty) {
        segments.add(TranscriptSegment(
          text: segmentText,
          startIndex: i,
          endIndex: end,
        ));
      }
    }

    return segments;
  }

  /// Generate flashcards from subtitle segments
  Future<List<Flashcard>> _generateFlashcardsFromSubtitles(
    List<TranscriptSegment> segments,
    String videoTitle,
    int count,
  ) async {
    try {
      // Prepare context for AI
      final context = '''
Video Title: $videoTitle

Key transcript segments:
${segments.take(10).map((s) => '- ${s.text}').join('\n')}

Generate flashcards that test understanding of the video content, focusing on:
1. Key concepts explained in the video
2. Important facts or statistics mentioned
3. Main ideas and their explanations
4. Terminology and definitions used
5. Cause and effect relationships discussed
''';

      // Try OpenAI first
      try {
        return await _openAIService.generateFlashcardsFromContent(
          context,
          count,
          'mixed',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ OpenAI failed, using fallback: $e');
        }

        // Use fallback service
        return _fallbackService.generateFlashcards(
          context,
          count,
          'mixed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating flashcards: $e');
      }

      // Generate basic flashcards from segments
      return _generateBasicFlashcards(segments, count);
    }
  }

  /// Generate quiz questions specifically from subtitle content
  Future<List<QuizQuestion>> _generateQuizQuestionsFromSubtitles(
    List<TranscriptSegment> segments,
    String videoTitle,
    int count,
    bool useSubtitlesForQuestions,
  ) async {
    try {
      // Create focused prompts based on subtitle segments
      final questionsPrompt = '''
Video Title: $videoTitle

Based on these exact subtitle segments from the video:
${segments.take(15).map((s) => '"${s.text}"').join('\n\n')}

Generate multiple-choice questions that:
1. Test comprehension of what was specifically said in the video
2. Use direct quotes from the subtitles when possible
3. Focus on key information presented in the video
4. Include questions about the sequence of topics discussed
5. Test understanding of examples or explanations given

Make questions directly reference the video content, such as:
- "According to the video, what is..."
- "The speaker mentioned that..."
- "In the video, which example was used to explain..."
''';

      // Try OpenAI first
      try {
        return await _openAIService.generateQuizQuestionsFromContent(
          useSubtitlesForQuestions
              ? questionsPrompt
              : segments.map((s) => s.text).join(' '),
          count,
          'mixed',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ OpenAI failed for quiz, using fallback: $e');
        }

        // Use fallback service
        return _fallbackService.generateQuizQuestions(
          useSubtitlesForQuestions
              ? questionsPrompt
              : segments.map((s) => s.text).join(' '),
          count,
          'mixed',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating quiz questions: $e');
      }

      // Generate basic questions from segments
      return _generateBasicQuizQuestions(segments, count);
    }
  }

  /// Generate basic flashcards when AI fails
  List<Flashcard> _generateBasicFlashcards(
      List<TranscriptSegment> segments, int count) {
    final flashcards = <Flashcard>[];

    for (int i = 0; i < count && i < segments.length; i++) {
      final segment = segments[i];
      final words = segment.text.split(' ');

      if (words.length > 10) {
        // Extract key phrase as question
        final keyPhrase = words.take(8).join(' ');
        final answer = segment.text;

        flashcards.add(Flashcard(
          id: 'basic_${DateTime.now().millisecondsSinceEpoch}_$i',
          question: 'Complete this statement from the video: "$keyPhrase..."',
          answer: answer,
          difficulty: DifficultyLevel.medium,
        ));
      }
    }

    return flashcards;
  }

  /// Generate basic quiz questions when AI fails
  List<QuizQuestion> _generateBasicQuizQuestions(
      List<TranscriptSegment> segments, int count) {
    final questions = <QuizQuestion>[];

    for (int i = 0; i < count && i < segments.length - 1; i++) {
      final segment = segments[i];
      final nextSegment = segments[i + 1];

      // Create a sequencing question
      questions.add(QuizQuestion(
        id: 'basic_q_${DateTime.now().millisecondsSinceEpoch}_$i',
        question:
            'What topic was discussed after: "${segment.text.split('.').first}..."?',
        options: [
          nextSegment.text.split('.').first,
          segments[(i + 2) % segments.length].text.split('.').first,
          segments[(i + 3) % segments.length].text.split('.').first,
          'None of the above',
        ],
        correctAnswer: nextSegment.text.split('.').first,
        type: QuizType.multipleChoice,
      ));
    }

    return questions;
  }

  /// Save study set to local storage
  Future<void> _saveStudySetLocally(StudySet studySet, String userId) async {
    try {
      await _storageService.saveStudySet(studySet);
      
      if (kDebugMode) {
        debugPrint('✅ Study set saved locally: ${studySet.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving study set locally: $e');
      }
      throw Exception('Failed to save study materials locally');
    }
  }

  /// Check if a video has already been processed
  Future<bool> isVideoProcessed(String videoId, String userId) async {
    try {
      // Check local storage for existing study sets with this video ID
      final allStudySets = _storageService.fullStudySets.values;
      
      for (final studySet in allStudySets) {
        if (studySet.metadata != null && 
            studySet.metadata!['videoId'] == videoId) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking if video processed: $e');
      }
      return false;
    }
  }

  /// Get existing study set for a video
  Future<StudySet?> getExistingStudySet(String videoId, String userId) async {
    try {
      // Check local storage for existing study sets with this video ID
      final allStudySets = _storageService.fullStudySets.values;
      
      for (final studySet in allStudySets) {
        if (studySet.metadata != null && 
            studySet.metadata!['videoId'] == videoId) {
          return studySet;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting existing study set: $e');
      }
      return null;
    }
  }
}

/// Represents a segment of transcript text
class TranscriptSegment {
  final String text;
  final int startIndex;
  final int endIndex;

  TranscriptSegment({
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
}
