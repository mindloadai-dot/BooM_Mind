import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/screens/create_screen.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';

void main() {
  group('CreateScreen Tests', () {
    testWidgets('CreateScreen should render without errors', (WidgetTester tester) async {
      // Build the CreateScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MindloadEconomyService>(
            create: (context) => MindloadEconomyService.instance,
            child: const CreateScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the screen renders without throwing exceptions
      expect(find.byType(CreateScreen), findsOneWidget);
      
      // Verify that the app bar is present
      expect(find.text('Create Study Set'), findsOneWidget);
      
      // Verify that the step indicator is present
      expect(find.byType(Container), findsWidgets);
      
      // Verify that the main content area is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('CreateScreen should show step 1 content initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MindloadEconomyService>(
            create: (context) => MindloadEconomyService.instance,
            child: const CreateScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that step 1 content is shown (Basic Information)
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Let\'s start with the basics for your study set'), findsOneWidget);
      
      // Verify that the title input field is present
      expect(find.byType(TextField), findsWidgets);
      
      // Verify that content source selector is present
      expect(find.text('Content Source'), findsOneWidget);
    });

    testWidgets('CreateScreen should have navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MindloadEconomyService>(
            create: (context) => MindloadEconomyService.instance,
            child: const CreateScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the Next button is present
      expect(find.text('Next'), findsOneWidget);
      
      // Verify that the button is initially disabled (no title entered)
      final nextButton = find.text('Next');
      expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);
    });

    testWidgets('CreateScreen should enable Next button when title is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MindloadEconomyService>(
            create: (context) => MindloadEconomyService.instance,
            child: const CreateScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and enter text in the title field
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Test Study Set');
      await tester.pump();

      // Verify that the Next button is now enabled
      final nextButton = find.text('Next');
      expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
    });
  });
}
