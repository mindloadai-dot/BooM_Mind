import 'package:flutter/material.dart';
import 'package:mindload/constants/product_constants.dart';

// Pack-A tier system for Mindload Economy
enum MindloadTier {
  free, // Dendrite tier
  axon,
  neuron,
  cortex,
  singularity,

  // Legacy tiers (for backward compatibility during transition)
  synapse, // Old tier name
}

// Extension methods for MindloadTier
extension MindloadTierExtension on MindloadTier {
  String get displayName {
    switch (this) {
      case MindloadTier.free:
        return 'Dendrite';
      case MindloadTier.axon:
        return 'Axon';
      case MindloadTier.neuron:
        return 'Neuron';
      case MindloadTier.cortex:
        return 'Cortex';
      case MindloadTier.singularity:
        return 'Singularity';
      case MindloadTier.synapse:
        return 'Synapse';
    }
  }

  String get subtitle {
    switch (this) {
      case MindloadTier.free:
        return 'Free tier with basic features';
      case MindloadTier.axon:
        return 'Entry-level premium features';
      case MindloadTier.neuron:
        return 'Enhanced learning capabilities';
      case MindloadTier.cortex:
        return 'Advanced AI-powered features';
      case MindloadTier.singularity:
        return 'Ultimate learning experience';
      case MindloadTier.synapse:
        return 'Legacy tier - upgrade recommended';
    }
  }

  Color get color {
    switch (this) {
      case MindloadTier.free:
        return const Color(0xFF9E9E9E);
      case MindloadTier.axon:
        return const Color(0xFF4CAF50);
      case MindloadTier.neuron:
        return const Color(0xFF2196F3);
      case MindloadTier.cortex:
        return const Color(0xFF9C27B0);
      case MindloadTier.singularity:
        return const Color(0xFFFF9800);
      case MindloadTier.synapse:
        return const Color(0xFF4CAF50);
    }
  }
}

// Mindload Economy configuration for Pack-A system
class MindloadEconomyConfig {
  final MindloadTier tier;
  final int monthlyTokens;
  final int monthlyExports;
  final int flashcardsPerToken;
  final int quizPerToken;
  final int pasteCharCaps;
  final int pdfPageCaps;
  final int activeSetLimits;
  final int rolloverLimits;
  final double tierPrice;
  final int monthlyYoutubeIngests;
  final bool hasUltraAccess;

  const MindloadEconomyConfig({
    required this.tier,
    required this.monthlyTokens,
    required this.monthlyExports,
    required this.flashcardsPerToken,
    required this.quizPerToken,
    required this.pasteCharCaps,
    required this.pdfPageCaps,
    required this.activeSetLimits,
    required this.rolloverLimits,
    required this.tierPrice,
    required this.monthlyYoutubeIngests,
    required this.hasUltraAccess,
  });

  // Pack-A tier configurations
  static const Map<MindloadTier, MindloadEconomyConfig> tierConfigs = {
    MindloadTier.free: MindloadEconomyConfig(
      tier: MindloadTier.free,
      monthlyTokens: ProductConstants.freeMonthlyTokens,
      monthlyExports: 1,
      flashcardsPerToken: 50, // Free tier gets basic features
      quizPerToken: 30, // Free tier gets basic features
      pasteCharCaps: 1000,
      pdfPageCaps: 2,
      activeSetLimits: 3,
      rolloverLimits: 0,
      tierPrice: 0.0,
      monthlyYoutubeIngests: 0,
      hasUltraAccess: false,
    ),
    MindloadTier.axon: MindloadEconomyConfig(
      tier: MindloadTier.axon,
      monthlyTokens: ProductConstants.axonMonthlyTokens,
      monthlyExports: 5,
      flashcardsPerToken: 50,
      quizPerToken: 30,
      pasteCharCaps: 5000,
      pdfPageCaps: 10,
      activeSetLimits: 10,
      rolloverLimits: 60,
      tierPrice: ProductConstants.axonMonthlyPriceUsd,
      monthlyYoutubeIngests: ProductConstants.axonMonthlyYtIngests,
      hasUltraAccess: true,
    ),
    MindloadTier.neuron: MindloadEconomyConfig(
      tier: MindloadTier.neuron,
      monthlyTokens: 300,
      monthlyExports: 15,
      flashcardsPerToken: 50,
      quizPerToken: 30,
      pasteCharCaps: 100000,
      pdfPageCaps: 25,
      activeSetLimits: 25,
      rolloverLimits: 160,
      tierPrice: 9.99,
      monthlyYoutubeIngests: 3,
      hasUltraAccess: true,
    ),
    MindloadTier.cortex: MindloadEconomyConfig(
      tier: MindloadTier.cortex,
      monthlyTokens: 750,
      monthlyExports: 30,
      flashcardsPerToken: 50,
      quizPerToken: 30,
      pasteCharCaps: 100000,
      pdfPageCaps: 50,
      activeSetLimits: 50,
      rolloverLimits: 375,
      tierPrice: 14.99,
      monthlyYoutubeIngests: 5,
      hasUltraAccess: true,
    ),
    MindloadTier.singularity: MindloadEconomyConfig(
      tier: MindloadTier.singularity,
      monthlyTokens: 1500,
      monthlyExports: 50,
      flashcardsPerToken: 50,
      quizPerToken: 30,
      pasteCharCaps: 100000,
      pdfPageCaps: 100,
      activeSetLimits: 100,
      rolloverLimits: 800,
      tierPrice: 19.99,
      monthlyYoutubeIngests: 10,
      hasUltraAccess: true,
    ),

    // Legacy tier configurations (for backward compatibility during transition)
    MindloadTier.synapse: MindloadEconomyConfig(
      tier: MindloadTier.synapse,
      monthlyTokens: 500, // Convert old credits to tokens
      monthlyExports: 10,
      flashcardsPerToken: 50,
      quizPerToken: 30,
      pasteCharCaps: 100000,
      pdfPageCaps: 15,
      activeSetLimits: 15,
      rolloverLimits: 100,
      tierPrice: 6.99,
      monthlyYoutubeIngests: 2,
      hasUltraAccess: true,
    ),
  };

  static MindloadEconomyConfig getConfig(MindloadTier tier) {
    return tierConfigs[tier] ?? tierConfigs[MindloadTier.free]!;
  }

  // Get all Pack-A tier configs
  static List<MindloadEconomyConfig> getPackATiers() {
    return [
      tierConfigs[MindloadTier.free]!,
      tierConfigs[MindloadTier.axon]!,
      tierConfigs[MindloadTier.neuron]!,
      tierConfigs[MindloadTier.cortex]!,
      tierConfigs[MindloadTier.singularity]!,
    ];
  }

  // Get legacy tier configs
  static List<MindloadEconomyConfig> getLegacyTiers() {
    return [
      tierConfigs[MindloadTier.synapse]!,
    ];
  }

  // Check if tier has Ultra Mode access
  bool get hasUltraMode => hasUltraAccess;

  // Get MindLoad Tokens for this tier
  int get tokens => monthlyTokens;

  // Get YouTube ingests for this tier
  int get youtubeIngests => monthlyYoutubeIngests;

  // Static accessors for backward compatibility
  static Map<MindloadTier, int> get monthlyCredits => {
        for (final entry in tierConfigs.entries)
          entry.key: entry.value.monthlyTokens,
      };

  static Map<MindloadTier, int> get monthlyExportLimits => {
        for (final entry in tierConfigs.entries)
          entry.key: entry.value.monthlyExports,
      };

  static double get pausedThreshold => 0.8;
  static double get savingsModeThreshold => 0.6;
}

// Budget Controller States
enum BudgetState {
  normal, // Under 80%
  savingsMode, // 80-100%
  paused, // 100%+
}

enum QueuePriority {
  standard, // Neuron
  priority, // Synapse
  priorityPlus, // Cortex
}

// User Economy State
class MindloadUserEconomy {
  final String userId;
  final MindloadTier tier;
  final int creditsRemaining;
  final int creditsUsedThisMonth;
  final int rolloverCredits;
  final int exportsRemaining;
  final int exportsUsedThisMonth;
  final int activeSetCount;
  final DateTime lastCreditRefill;
  final DateTime nextResetDate;
  final bool isActive; // Subscription active
  final DateTime? subscriptionExpiry;

  const MindloadUserEconomy({
    required this.userId,
    required this.tier,
    required this.creditsRemaining,
    this.creditsUsedThisMonth = 0,
    this.rolloverCredits = 0,
    required this.exportsRemaining,
    this.exportsUsedThisMonth = 0,
    required this.activeSetCount,
    required this.lastCreditRefill,
    required this.nextResetDate,
    this.isActive = true,
    this.subscriptionExpiry,
  });

  // Getters for tier limits
  int get monthlyQuota => MindloadEconomyConfig.tierConfigs[tier]!.tokens;
  int get monthlyExports =>
      MindloadEconomyConfig.tierConfigs[tier]!.monthlyExports;
  int get pasteCharLimit =>
      MindloadEconomyConfig.tierConfigs[tier]!.pasteCharCaps;
  int get pdfPageLimit => MindloadEconomyConfig.tierConfigs[tier]!.pdfPageCaps;
  int get activeSetLimit =>
      MindloadEconomyConfig.tierConfigs[tier]!.activeSetLimits;
  int get rolloverLimit =>
      MindloadEconomyConfig.tierConfigs[tier]!.rolloverLimits;
  QueuePriority get queuePriority {
    switch (tier) {
      case MindloadTier.free:
        return QueuePriority.standard;
      case MindloadTier.axon:
        return QueuePriority.priority;
      case MindloadTier.neuron:
        return QueuePriority.priorityPlus;
      case MindloadTier.cortex:
        return QueuePriority.priorityPlus;
      case MindloadTier.singularity:
        return QueuePriority.priorityPlus;
      case MindloadTier.synapse:
        return QueuePriority.priorityPlus;
    }
  }

  // Per-credit output (affected by budget state)
  int getFlashcardsPerCredit(BudgetState budgetState) {
    if (budgetState == BudgetState.savingsMode) {
      return (MindloadEconomyConfig.tierConfigs[tier]!.flashcardsPerToken * 0.8)
          .round();
    }
    return MindloadEconomyConfig.tierConfigs[tier]!.flashcardsPerToken;
  }

  int getQuizPerCredit(BudgetState budgetState) {
    if (budgetState == BudgetState.savingsMode) {
      return (MindloadEconomyConfig.tierConfigs[tier]!.quizPerToken * 0.8)
          .round();
    }
    return MindloadEconomyConfig.tierConfigs[tier]!.quizPerToken;
  }

  // Paste cap (affected by budget state)
  int getPasteCharLimit(BudgetState budgetState) {
    if (budgetState == BudgetState.savingsMode) {
      return (pasteCharLimit * 0.8).round();
    }
    return pasteCharLimit;
  }

  // Validation checks
  bool get hasCredits => creditsRemaining > 0;
  bool get hasExports => exportsRemaining > 0;
  bool get canAddActiveSet => activeSetCount < activeSetLimit;
  bool get isPaidTier => tier != MindloadTier.free;
  bool get hasRollover => tier != MindloadTier.free;
  bool get needsRenewal =>
      subscriptionExpiry != null &&
      DateTime.now().isAfter(subscriptionExpiry!) &&
      !isActive;

  // Create copy with updates
  MindloadUserEconomy copyWith({
    MindloadTier? tier,
    int? creditsRemaining,
    int? creditsUsedThisMonth,
    int? rolloverCredits,
    int? exportsRemaining,
    int? exportsUsedThisMonth,
    int? activeSetCount,
    DateTime? lastCreditRefill,
    DateTime? nextResetDate,
    bool? isActive,
    DateTime? subscriptionExpiry,
  }) {
    return MindloadUserEconomy(
      userId: userId,
      tier: tier ?? this.tier,
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      creditsUsedThisMonth: creditsUsedThisMonth ?? this.creditsUsedThisMonth,
      rolloverCredits: rolloverCredits ?? this.rolloverCredits,
      exportsRemaining: exportsRemaining ?? this.exportsRemaining,
      exportsUsedThisMonth: exportsUsedThisMonth ?? this.exportsUsedThisMonth,
      activeSetCount: activeSetCount ?? this.activeSetCount,
      lastCreditRefill: lastCreditRefill ?? this.lastCreditRefill,
      nextResetDate: nextResetDate ?? this.nextResetDate,
      isActive: isActive ?? this.isActive,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'tier': tier.name,
        'creditsRemaining': creditsRemaining,
        'creditsUsedThisMonth': creditsUsedThisMonth,
        'rolloverCredits': rolloverCredits,
        'exportsRemaining': exportsRemaining,
        'exportsUsedThisMonth': exportsUsedThisMonth,
        'activeSetCount': activeSetCount,
        'lastCreditRefill': lastCreditRefill.millisecondsSinceEpoch,
        'nextResetDate': nextResetDate.millisecondsSinceEpoch,
        'isActive': isActive,
        'subscriptionExpiry': subscriptionExpiry?.millisecondsSinceEpoch,
      };

  factory MindloadUserEconomy.fromJson(Map<String, dynamic> json) {
    return MindloadUserEconomy(
      userId: json['userId'] as String,
      tier: MindloadTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => MindloadTier.free,
      ),
      creditsRemaining: json['creditsRemaining'] as int? ?? 0,
      creditsUsedThisMonth: json['creditsUsedThisMonth'] as int? ?? 0,
      rolloverCredits: json['rolloverCredits'] as int? ?? 0,
      exportsRemaining: json['exportsRemaining'] as int? ?? 0,
      exportsUsedThisMonth: json['exportsUsedThisMonth'] as int? ?? 0,
      activeSetCount: json['activeSetCount'] as int? ?? 0,
      lastCreditRefill: DateTime.fromMillisecondsSinceEpoch(
        json['lastCreditRefill'] as int? ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      nextResetDate: DateTime.fromMillisecondsSinceEpoch(
        json['nextResetDate'] as int? ??
            DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
      ),
      isActive: json['isActive'] as bool? ?? true,
      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['subscriptionExpiry'] as int)
          : null,
    );
  }

  // Create default user economy
  factory MindloadUserEconomy.createDefault(String userId) {
    final now = DateTime.now();
    return MindloadUserEconomy(
      userId: userId,
      tier: MindloadTier.free,
      creditsRemaining:
          MindloadEconomyConfig.tierConfigs[MindloadTier.free]!.tokens,
      exportsRemaining:
          MindloadEconomyConfig.tierConfigs[MindloadTier.free]!.monthlyExports,
      activeSetCount: 0,
      lastCreditRefill: now,
      nextResetDate: () {
        // Reset on 1st of next month at 00:00 America/Chicago
        var nextMonth = DateTime(now.year, now.month + 1, 1);
        // Add 6 hours for Chicago timezone offset (UTC-6/UTC-5)
        return nextMonth.toUtc().add(const Duration(hours: 6));
      }(),
    );
  }
}

// Global Budget State
class MindloadBudgetController {
  final double monthlySpent;
  final double monthlyLimit;
  final BudgetState state;
  final DateTime lastReset;
  final DateTime nextResetDate;
  final bool useEfficientModel; // Lower-cost model when in savings mode

  const MindloadBudgetController({
    required this.monthlySpent,
    this.monthlyLimit = 0, // Default to free tier limit, will be set by factory
    required this.state,
    required this.lastReset,
    required this.nextResetDate,
    this.useEfficientModel = false,
  });

  // Factory constructor with proper default
  factory MindloadBudgetController.defaultController({
    required double monthlySpent,
    required BudgetState state,
    required DateTime lastReset,
    required DateTime nextResetDate,
    bool useEfficientModel = false,
  }) {
    final defaultLimit =
        MindloadEconomyConfig.tierConfigs[MindloadTier.free]!.monthlyTokens *
            10.0;
    return MindloadBudgetController(
      monthlySpent: monthlySpent,
      monthlyLimit: defaultLimit,
      state: state,
      lastReset: lastReset,
      nextResetDate: nextResetDate,
      useEfficientModel: useEfficientModel,
    );
  }

  double get usagePercentage => monthlySpent / monthlyLimit;

  BudgetState calculateState() {
    if (usagePercentage >= 1.0) {
      // Assuming 100% is the threshold for paused
      return BudgetState.paused;
    } else if (usagePercentage >= 0.8) {
      // Assuming 80% is the threshold for savings mode
      return BudgetState.savingsMode;
    }
    return BudgetState.normal;
  }

  String get statusMessage {
    switch (state) {
      case BudgetState.normal:
        return '';
      case BudgetState.savingsMode:
        return 'High demand detected. Using efficient mode to serve everyone better.';
      case BudgetState.paused:
        return 'Monthly AI capacity reached. New generations paused until next cycle reset.';
    }
  }

  bool canGenerate() => state != BudgetState.paused;

  MindloadBudgetController copyWith({
    double? monthlySpent,
    double? monthlyLimit,
    BudgetState? state,
    DateTime? lastReset,
    DateTime? nextResetDate,
    bool? useEfficientModel,
  }) {
    return MindloadBudgetController(
      monthlySpent: monthlySpent ?? this.monthlySpent,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      state: state ?? this.state,
      lastReset: lastReset ?? this.lastReset,
      nextResetDate: nextResetDate ?? this.nextResetDate,
      useEfficientModel: useEfficientModel ?? this.useEfficientModel,
    );
  }

  Map<String, dynamic> toJson() => {
        'monthlySpent': monthlySpent,
        'monthlyLimit': monthlyLimit,
        'state': state.name,
        'lastReset': lastReset.millisecondsSinceEpoch,
        'nextResetDate': nextResetDate.millisecondsSinceEpoch,
        'useEfficientModel': useEfficientModel,
      };

  factory MindloadBudgetController.fromJson(Map<String, dynamic> json) {
    return MindloadBudgetController(
      monthlySpent: json['monthlySpent'] as double? ?? 0.0,
      monthlyLimit: json['monthlyLimit'] as double? ??
          MindloadEconomyConfig.tierConfigs[MindloadTier.free]!.tokens * 10,
      state: BudgetState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => BudgetState.normal,
      ),
      lastReset: DateTime.fromMillisecondsSinceEpoch(
        json['lastReset'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      nextResetDate: DateTime.fromMillisecondsSinceEpoch(
        json['nextResetDate'] as int? ??
            DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
      ),
      useEfficientModel: json['useEfficientModel'] as bool? ?? false,
    );
  }
}

// Enforcement Result
class EnforcementResult {
  final bool canProceed;
  final String? blockReason;
  final List<String> suggestedActions;
  final bool showUpgrade;
  final bool showBuyCredits;

  const EnforcementResult({
    required this.canProceed,
    this.blockReason,
    this.suggestedActions = const [],
    this.showUpgrade = false,
    this.showBuyCredits = false,
  });

  factory EnforcementResult.allow() =>
      const EnforcementResult(canProceed: true);

  factory EnforcementResult.block({
    required String reason,
    List<String> actions = const [],
    bool showUpgrade = false,
    bool showBuyCredits = false,
  }) {
    return EnforcementResult(
      canProceed: false,
      blockReason: reason,
      suggestedActions: actions,
      showUpgrade: showUpgrade,
      showBuyCredits: showBuyCredits,
    );
  }
}

// Content Generation Request
class GenerationRequest {
  final String sourceContent;
  final int sourceCharCount;
  final int? pdfPageCount;
  final bool isRecreate;
  final bool lastAttemptFailed;

  const GenerationRequest({
    required this.sourceContent,
    required this.sourceCharCount,
    this.pdfPageCount,
    this.isRecreate = false,
    this.lastAttemptFailed = false,
  });
}

// Export Request
class ExportRequest {
  final String setId;
  final String exportType; // 'flashcards_pdf', 'quiz_pdf'
  final bool includeMindloadHeader;

  const ExportRequest({
    required this.setId,
    required this.exportType,
    this.includeMindloadHeader = true,
  });
}

/// Tier Upgrade Information
class TierUpgradeInfo {
  final MindloadTier fromTier;
  final MindloadTier toTier;
  final double price;
  final String displayPrice;
  final List<String> benefits;
  final String cta;
  final Color accentColor;

  const TierUpgradeInfo({
    required this.fromTier,
    required this.toTier,
    required this.price,
    required this.displayPrice,
    required this.benefits,
    required this.cta,
    required this.accentColor,
  });

  static List<TierUpgradeInfo> getUpgradeOptions(MindloadTier currentTier) {
    switch (currentTier) {
      case MindloadTier.free:
        return [
          TierUpgradeInfo(
            fromTier: MindloadTier.free,
            toTier: MindloadTier.axon,
            price: 4.99,
            displayPrice: '\$4.99/month',
            benefits: [
              '120 tokens/month',
              'Priority queue',
              'Auto-retry',
              '5 exports/month',
              'Up to 10 PDF pages',
              '10 active sets'
            ],
            cta: 'Upgrade to Axon',
            accentColor: MindloadTier.axon.color,
          ),
          TierUpgradeInfo(
            fromTier: MindloadTier.free,
            toTier: MindloadTier.neuron,
            price: 9.99,
            displayPrice: '\$9.99/month',
            benefits: [
              '320 tokens/month',
              'Credit rollover up to 160',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '15 exports/month',
              'Up to 25 PDF pages',
              '25 active sets'
            ],
            cta: 'Upgrade to Neuron',
            accentColor: MindloadTier.neuron.color,
          ),
        ];
      case MindloadTier.axon:
        return [
          TierUpgradeInfo(
            fromTier: MindloadTier.axon,
            toTier: MindloadTier.neuron,
            price: 9.99,
            displayPrice: '\$9.99/month',
            benefits: [
              '320 tokens/month (vs 120)',
              'Credit rollover up to 160',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '15 exports/month (vs 5)',
              'Up to 25 PDF pages (vs 10)',
              '25 active sets (vs 10)'
            ],
            cta: 'Upgrade to Neuron',
            accentColor: MindloadTier.neuron.color,
          ),
          TierUpgradeInfo(
            fromTier: MindloadTier.axon,
            toTier: MindloadTier.cortex,
            price: 14.99,
            displayPrice: '\$14.99/month',
            benefits: [
              '750 tokens/month (vs 120)',
              'Credit rollover up to 375',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '30 exports/month (vs 5)',
              'Up to 50 PDF pages (vs 10)',
              '50 active sets (vs 10)'
            ],
            cta: 'Upgrade to Cortex',
            accentColor: MindloadTier.cortex.color,
          ),
        ];
      case MindloadTier.neuron:
        return [
          TierUpgradeInfo(
            fromTier: MindloadTier.neuron,
            toTier: MindloadTier.cortex,
            price: 14.99,
            displayPrice: '\$14.99/month',
            benefits: [
              '750 tokens/month (vs 320)',
              'Credit rollover up to 375',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '30 exports/month (vs 15)',
              'Up to 50 PDF pages (vs 25)',
              '50 active sets (vs 25)'
            ],
            cta: 'Upgrade to Cortex',
            accentColor: MindloadTier.cortex.color,
          ),
          TierUpgradeInfo(
            fromTier: MindloadTier.neuron,
            toTier: MindloadTier.singularity,
            price: 19.99,
            displayPrice: '\$19.99/month',
            benefits: [
              '1600 tokens/month (vs 320)',
              'Credit rollover up to 800',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '50 exports/month (vs 30)',
              'Up to 100 PDF pages (vs 50)',
              '100 active sets (vs 50)'
            ],
            cta: 'Upgrade to Singularity',
            accentColor: MindloadTier.singularity.color,
          ),
        ];
      case MindloadTier.cortex:
        return [
          TierUpgradeInfo(
            fromTier: MindloadTier.cortex,
            toTier: MindloadTier.singularity,
            price: 19.99,
            displayPrice: '\$19.99/month',
            benefits: [
              '1600 tokens/month (vs 750)',
              'Credit rollover up to 800',
              'Priority+ queue',
              'Batch export (up to 3 sets)',
              '50 exports/month (vs 30)',
              'Up to 100 PDF pages (vs 50)',
              '100 active sets (vs 50)'
            ],
            cta: 'Upgrade to Singularity',
            accentColor: MindloadTier.singularity.color,
          ),
        ];
      case MindloadTier.singularity:
        return []; // No upgrades from singularity
      case MindloadTier.synapse:
        return [
          TierUpgradeInfo(
            fromTier: MindloadTier.synapse,
            toTier: MindloadTier.axon,
            price: 4.99,
            displayPrice: '\$4.99/month',
            benefits: [
              '120 tokens/month (vs 200)',
              'Priority queue',
              'Auto-retry',
              '5 exports/month (vs 10)',
              'Up to 10 PDF pages (vs 15)',
              '10 active sets (vs 15)'
            ],
            cta: 'Upgrade to Axon',
            accentColor: MindloadTier.axon.color,
          ),
        ];
    }
  }
}
