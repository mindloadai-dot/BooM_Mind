import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/widgets/youtube_preview_card.dart';


void main() {
  group('YouTubePreviewCard', () {
    late YouTubePreview mockPreview;

    setUp(() {
      mockPreview = const YouTubePreview(
        videoId: 'dQw4w9WgXcQ',
        title: 'Test Video Title',
        channel: 'Test Channel',
        durationSeconds: 600,
        thumbnail: 'https://example.com/thumbnail.jpg',
        captionsAvailable: true,
        primaryLang: 'en',
        estimatedTokens: 1500,
        estimatedMindLoadTokens: 3,
        blocked: false,
        blockReason: null,
        limits: YouTubeLimits(
          maxDurationSeconds: 1800,
          plan: 'Free',
          monthlyYoutubeIngests: 1,
          youtubeIngestsRemaining: 1,
        ),
      );
    });

    Widget createTestWidget({
      YouTubePreview? preview,
      VoidCallback? onIngest,
      bool isLoading = false,
      String? errorMessage,
    }) {
      return MaterialApp(
                theme: ThemeData(),
        home: Scaffold(
          body: YouTubePreviewCard(
            preview: preview ?? mockPreview,
            onIngest: onIngest,
            isLoading: isLoading,
            errorMessage: errorMessage,
          ),
        ),
      );
    }

    testWidgets('should render video title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Test Video Title'), findsOneWidget);
    });

    testWidgets('should render channel name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Test Channel'), findsOneWidget);
    });

    testWidgets('should render duration correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('should render token information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('3 MindLoad Tokens'), findsOneWidget);
    });

    testWidgets('should render status pill correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Transcript detected • EN'), findsOneWidget);
    });

    testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isLoading: true));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Release to confirm'), findsOneWidget);
    });

    testWidgets('should show correct button text when captions not available', (WidgetTester tester) async {
      final previewWithoutCaptions = mockPreview.copyWith(
        captionsAvailable: false,
        primaryLang: null,
      );
      
      await tester.pumpWidget(createTestWidget(preview: previewWithoutCaptions));
      
      expect(find.text('No transcript available'), findsOneWidget);
    });

    testWidgets('should show correct button text when blocked', (WidgetTester tester) async {
      final blockedPreview = mockPreview.copyWith(
        blocked: true,
        blockReason: 'Over plan limit',
      );
      
      await tester.pumpWidget(createTestWidget(preview: blockedPreview));
      
      expect(find.text('Cannot proceed'), findsOneWidget);
    });

    testWidgets('should show correct button text when ready to ingest', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Hold to spend 3 MindLoad Tokens'), findsOneWidget);
    });

    testWidgets('should call onIngest when long press is completed', (WidgetTester tester) async {
      bool onIngestCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onIngest: () => onIngestCalled = true,
      ));
      
      // Find the ingest button
      final button = find.byType(GestureDetector);
      expect(button, findsOneWidget);
      
      // Simulate long press start
      await tester.longPress(button);
      await tester.pump();
      
      // Wait for long press to complete (600ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      
      expect(onIngestCalled, isTrue);
    });

    testWidgets('should show error message when provided', (WidgetTester tester) async {
      const errorMessage = 'Test error message';
      
      await tester.pumpWidget(createTestWidget(errorMessage: errorMessage));
      
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should format duration correctly for different lengths', (WidgetTester tester) async {
      // Test short duration (under 1 hour)
      final shortPreview = mockPreview.copyWith(durationSeconds: 125);
      await tester.pumpWidget(createTestWidget(preview: shortPreview));
      expect(find.text('2:05'), findsOneWidget);
      
      await tester.pumpWidget(createTestWidget());
      
      // Test long duration (over 1 hour)
      final longPreview = mockPreview.copyWith(durationSeconds: 7325); // 2:02:05
      await tester.pumpWidget(createTestWidget(preview: longPreview));
      expect(find.text('2:02:05'), findsOneWidget);
    });

    testWidgets('should handle different status colors correctly', (WidgetTester tester) async {
      // Test success status
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      
      // Test warning status (no captions)
      final warningPreview = mockPreview.copyWith(captionsAvailable: false);
      await tester.pumpWidget(createTestWidget(preview: warningPreview));
      expect(find.byIcon(Icons.warning), findsOneWidget);
      
      // Test error status (blocked)
      final errorPreview = mockPreview.copyWith(blocked: true);
      await tester.pumpWidget(createTestWidget(preview: errorPreview));
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show thumbnail placeholder when loading', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // The thumbnail should be present
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should show play button overlay on thumbnail', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should show duration badge on thumbnail', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('10:00'), findsNWidgets(2)); // One in info, one in badge
    });
  });
}
