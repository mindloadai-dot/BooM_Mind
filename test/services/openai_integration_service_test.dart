import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:mindload/services/openai_integration_service.dart';
import 'package:mindload/models/study_data.dart';

void main() {
  group('OpenAIIntegrationService', () {
    late OpenAIIntegrationService service;

    setUp(() {
      service = OpenAIIntegrationService.instance;
    });

    group('Text Conversion', () {
      test('should convert text to study set', () async {
        const testText = '''
        Flutter is an open-source UI software development kit created by Google. 
        It is used to develop cross-platform applications for Android, iOS, Linux, 
        macOS, Windows, Google Fuchsia, and the web from a single codebase.
        ''';

        final studySet = await service.convertTextToStudySet(
          text: testText,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.title, isNotEmpty);
        expect(studySet.flashcards.length, greaterThan(0));
        expect(studySet.quizQuestions.length, greaterThan(0));
        expect(studySet.sourceType, equals('text'));
        expect(studySet.tags, contains('ai-generated'));
      });

      test('should handle empty text', () async {
        expect(
          () => service.convertTextToStudySet(text: ''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Document Conversion', () {
      test('should convert document to study set', () async {
        final testBytes = Uint8List.fromList([
          0x50, 0x4B, 0x03, 0x04, // ZIP header for DOCX
        ]);

        final studySet = await service.convertDocumentToStudySet(
          fileBytes: testBytes,
          fileName: 'test_document.docx',
          extension: 'docx',
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.title, isNotEmpty);
        expect(studySet.flashcards.length, greaterThan(0));
        expect(studySet.quizQuestions.length, greaterThan(0));
        expect(studySet.sourceType, equals('document'));
        expect(studySet.metadata!['originalFileName'], equals('test_document.docx'));
      });
    });

    group('YouTube Conversion', () {
      test('should convert YouTube URL to study set', () async {
        const youtubeUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

        final studySet = await service.convertYouTubeToStudySet(
          youtubeUrl: youtubeUrl,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.title, isNotEmpty);
        expect(studySet.flashcards.length, greaterThan(0));
        expect(studySet.quizQuestions.length, greaterThan(0));
        expect(studySet.sourceType, equals('youtube'));
        expect(studySet.sourceUrl, equals(youtubeUrl));
      });

      test('should handle invalid YouTube URL', () async {
        const invalidUrl = 'https://example.com/invalid';

        expect(
          () => service.convertYouTubeToStudySet(
            youtubeUrl: invalidUrl,
            flashcardCount: 5,
            quizCount: 3,
            difficulty: 'medium',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Website Conversion', () {
      test('should convert website URL to study set', () async {
        const websiteUrl = 'https://flutter.dev';

        final studySet = await service.convertWebsiteToStudySet(
          websiteUrl: websiteUrl,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.title, isNotEmpty);
        expect(studySet.flashcards.length, greaterThan(0));
        expect(studySet.quizQuestions.length, greaterThan(0));
        expect(studySet.sourceType, equals('website'));
        expect(studySet.sourceUrl, equals(websiteUrl));
      });

      test('should handle invalid website URL', () async {
        const invalidUrl = 'not-a-valid-url';

        expect(
          () => service.convertWebsiteToStudySet(
            websiteUrl: invalidUrl,
            flashcardCount: 5,
            quizCount: 3,
            difficulty: 'medium',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Auto Conversion', () {
      test('should auto-detect and convert text', () async {
        const text = 'This is plain text content for testing.';

        final studySet = await service.autoConvertToStudySet(
          input: text,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.sourceType, equals('text'));
      });

      test('should auto-detect and convert YouTube URL', () async {
        const youtubeUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

        final studySet = await service.autoConvertToStudySet(
          input: youtubeUrl,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.sourceType, equals('youtube'));
      });

      test('should auto-detect and convert website URL', () async {
        const websiteUrl = 'https://flutter.dev';

        final studySet = await service.autoConvertToStudySet(
          input: websiteUrl,
          flashcardCount: 5,
          quizCount: 3,
          difficulty: 'medium',
        );

        expect(studySet, isA<StudySet>());
        expect(studySet.sourceType, equals('website'));
      });
    });
  });
}
