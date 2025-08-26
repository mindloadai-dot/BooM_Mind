import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/enhanced_onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('EnhancedOnboardingService', () {
    late EnhancedOnboardingService service;

    setUp(() {
      service = EnhancedOnboardingService();
    });

    tearDown(() async {
      // Clean up SharedPreferences after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('should be singleton', () {
      final instance1 = EnhancedOnboardingService();
      final instance2 = EnhancedOnboardingService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should detect first launch correctly', () async {
      // Initially should be first launch
      expect(await service.isFirstLaunch(), isTrue);

      // After marking welcome dialog as shown, should not be first launch
      await service.markWelcomeDialogShown();
      expect(await service.isFirstLaunch(), isFalse);
    });

    test('should show welcome dialog on first launch', () async {
      expect(await service.shouldShowWelcomeDialog(), isTrue);
    });

    test('should not show welcome dialog after marking as shown', () async {
      await service.markWelcomeDialogShown();
      expect(await service.shouldShowWelcomeDialog(), isFalse);
    });

    test('should not show welcome dialog after marking never show again', () async {
      await service.markWelcomeDialogNeverShow();
      expect(await service.shouldShowWelcomeDialog(), isFalse);
    });

    test('should reset onboarding preferences correctly', () async {
      // Set some preferences
      await service.markWelcomeDialogShown();
      await service.completeOnboarding();
      
      // Verify they are set
      expect(await service.isOnboardingCompleted(), isTrue);
      expect(await service.shouldShowWelcomeDialog(), isFalse);
      
      // Reset
      await service.resetOnboarding();
      
      // Verify they are reset
      expect(await service.isOnboardingCompleted(), isFalse);
      expect(await service.shouldShowWelcomeDialog(), isTrue);
    });

    test('should track first launch date', () async {
      final firstLaunch = await service.getFirstLaunchDate();
      expect(firstLaunch, isNull);
      
      await service.markWelcomeDialogShown();
      
      final firstLaunchAfter = await service.getFirstLaunchDate();
      expect(firstLaunchAfter, isNotNull);
      expect(firstLaunchAfter!.isAfter(DateTime.now().subtract(const Duration(seconds: 1))), isTrue);
    });

    test('should calculate days since first launch', () async {
      expect(await service.getDaysSinceFirstLaunch(), equals(0));
      
      await service.markWelcomeDialogShown();
      
      expect(await service.getDaysSinceFirstLaunch(), equals(0)); // Same day
    });
  });
}
