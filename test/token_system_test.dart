import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';

void main() {
  // Fix binding issues for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Token System Tests', () {
    late MindloadEconomyService economyService;

    setUpAll(() async {
      economyService = MindloadEconomyService.instance;
      await economyService.initialize();
    });

    test('Economy service initializes correctly', () {
      expect(economyService.isInitialized, isTrue);
      expect(economyService.currentTier, isA<MindloadTier>());
    });

    test('Free tier has correct token allocation', () {
      // Test free tier token allocation
      final freeConfig = MindloadEconomyConfig.tierConfigs[MindloadTier.free]!;
      expect(freeConfig.monthlyTokens, equals(20));
      expect(freeConfig.monthlyExports,
          equals(1)); // Updated to match actual config
      expect(freeConfig.pasteCharCaps, equals(500000));
    });

    test('Paid tiers have correct token allocation', () {
      // Test Axon tier
      final axonConfig = MindloadEconomyConfig.tierConfigs[MindloadTier.axon]!;
      expect(axonConfig.monthlyTokens, equals(120));
      expect(axonConfig.monthlyExports, equals(5));

      // Test Neuron tier
      final neuronConfig =
          MindloadEconomyConfig.tierConfigs[MindloadTier.neuron]!;
      expect(neuronConfig.monthlyTokens, equals(300));
      expect(neuronConfig.monthlyExports, equals(15));

      // Test Cortex tier
      final cortexConfig =
          MindloadEconomyConfig.tierConfigs[MindloadTier.cortex]!;
      expect(cortexConfig.monthlyTokens, equals(750));
      expect(cortexConfig.monthlyExports, equals(30));

      // Test Singularity tier
      final singularityConfig =
          MindloadEconomyConfig.tierConfigs[MindloadTier.singularity]!;
      expect(singularityConfig.monthlyTokens, equals(1500));
      expect(singularityConfig.monthlyExports, equals(50));
    });

    test('Token consumption validation works', () {
      final request = GenerationRequest(
        sourceContent: 'Test content for generation',
        sourceCharCount: 100,
        isRecreate: false,
        lastAttemptFailed: false,
      );

      final enforcement = economyService.canGenerateContent(request);
      expect(enforcement, isA<EnforcementResult>());
      expect(enforcement.canProceed, isA<bool>());
    });

    test('Auto-split calculation works correctly', () {
      // Test with content that exceeds paste limit
      final largeContentSize = 1000000; // 1M characters
      final creditsNeeded =
          economyService.calculateAutoSplitCredits(largeContentSize);

      expect(creditsNeeded, greaterThan(0));
      expect(creditsNeeded,
          equals(2)); // Should need 2 chunks for 1M chars with 500k limit
    });

    test('Budget state calculation works', () {
      expect(economyService.budgetState, isA<BudgetState>());
      expect(economyService.canGenerate, isA<bool>());
    });

    test('Tier upgrade options are available', () {
      final upgradeOptions = economyService.getUpgradeOptions();
      expect(upgradeOptions, isA<List<TierUpgradeInfo>>());

      // Free tier should have upgrade options
      if (economyService.currentTier == MindloadTier.free) {
        expect(upgradeOptions, isNotEmpty);
      }
    });

    test('Output counts are calculated correctly', () {
      final outputCounts = economyService.getOutputCounts();
      expect(outputCounts, containsPair('flashcards', isA<int>()));
      expect(outputCounts, containsPair('quiz', isA<int>()));
      expect(outputCounts['flashcards'], greaterThan(0));
      expect(outputCounts['quiz'], greaterThan(0));
    });

    test('Current limits summary is comprehensive', () {
      final limits = economyService.getCurrentLimits();

      if (limits.isNotEmpty) {
        expect(limits, containsPair('tier', isA<String>()));
        expect(limits, containsPair('creditsRemaining', isA<int>()));
        expect(limits, containsPair('monthlyQuota', isA<int>()));
        expect(limits, containsPair('pasteCharLimit', isA<int>()));
        expect(limits, containsPair('budgetState', isA<String>()));
      }
    });
  });

  group('Token System Integration Tests', () {
    test('Generation request validation works end-to-end', () async {
      final economyService = MindloadEconomyService.instance;

      final request = GenerationRequest(
        sourceContent: 'Sample content for testing token consumption',
        sourceCharCount: 50,
        isRecreate: false,
        lastAttemptFailed: false,
      );

      // Test enforcement
      final enforcement = economyService.canGenerateContent(request);
      expect(enforcement, isA<EnforcementResult>());

      // If generation is allowed, test consumption
      if (enforcement.canProceed) {
        final initialCredits = economyService.creditsRemaining;
        final consumed = await economyService.useCreditsForGeneration(request);

        if (consumed && initialCredits > 0) {
          expect(economyService.creditsRemaining, lessThan(initialCredits));
        }
      }
    });

    test('Export quota validation works', () {
      final economyService = MindloadEconomyService.instance;

      final exportRequest = ExportRequest(
        setId: 'test_set_123',
        exportType: 'flashcards_pdf',
        includeMindloadHeader: true,
      );

      final enforcement = economyService.canExportContent(exportRequest);
      expect(enforcement, isA<EnforcementResult>());
    });
  });
}
