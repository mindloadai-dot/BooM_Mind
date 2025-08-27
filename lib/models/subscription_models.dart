import 'package:flutter/material.dart';

// System status enum for budget management
enum SystemStatus {
  normal,
  highDemand,
  paused,
}

// Pack-A tier system
enum SubscriptionTier {
  free, // Dendrite tier
  axon,
  neuron,
  synapse,
  cortex,
  singularity,

  // Legacy tiers (for backward compatibility during transition)
  pro,
  admin,
}

// Tier limits for Pack-A system
class TierLimits {
  final int dailyQuizQuestions;
  final int dailyFlashcards;
  final int dailyPdfPages;
  final int dailyUploads;
  final String aiModel;
  final bool priorityProcessing;
  final int monthlyTokens;
  final int monthlyYoutubeIngests;
  final bool hasUltraAccess;
  final int maxPdfPages;
  final int examWeekBoosts;
  final int
      maxYouTubeDurationMinutes; // Maximum YouTube video duration in minutes

  const TierLimits({
    required this.dailyQuizQuestions,
    required this.dailyFlashcards,
    required this.dailyPdfPages,
    required this.dailyUploads,
    required this.aiModel,
    required this.priorityProcessing,
    required this.monthlyTokens,
    required this.monthlyYoutubeIngests,
    required this.hasUltraAccess,
    required this.maxPdfPages,
    required this.examWeekBoosts,
    required this.maxYouTubeDurationMinutes,
  });

  // Pack-A tier limits
  static const Map<SubscriptionTier, TierLimits> limits = {
    SubscriptionTier.free: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-3.5-turbo',
      priorityProcessing: false,
      monthlyTokens: 0,
      monthlyYoutubeIngests: 0,
      hasUltraAccess: false,
      maxPdfPages: 2,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 0, // No YouTube access
    ),
    SubscriptionTier.axon: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4o',
      priorityProcessing: true,
      monthlyTokens: 120,
      monthlyYoutubeIngests: 1,
      hasUltraAccess: true,
      maxPdfPages: 10,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),
    SubscriptionTier.neuron: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4-turbo',
      priorityProcessing: true,
      monthlyTokens: 300,
      monthlyYoutubeIngests: 3,
      hasUltraAccess: true,
      maxPdfPages: 25,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),
    SubscriptionTier.synapse: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4-turbo',
      priorityProcessing: true,
      monthlyTokens: 500,
      monthlyYoutubeIngests: 2,
      hasUltraAccess: true,
      maxPdfPages: 35,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),
    SubscriptionTier.cortex: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4-turbo',
      priorityProcessing: true,
      monthlyTokens: 750,
      monthlyYoutubeIngests: 5,
      hasUltraAccess: true,
      maxPdfPages: 50,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),
    SubscriptionTier.singularity: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4-turbo',
      priorityProcessing: true,
      monthlyTokens: 1500,
      monthlyYoutubeIngests: 10,
      hasUltraAccess: true,
      maxPdfPages: 100,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),

    // Legacy tier limits (for backward compatibility during transition)
    SubscriptionTier.pro: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4o',
      priorityProcessing: true,
      monthlyTokens: 125, // Convert credits to tokens
      monthlyYoutubeIngests: 2,
      hasUltraAccess: true,
      maxPdfPages: 15,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 45, // 45 minute videos
    ),
    SubscriptionTier.admin: TierLimits(
      dailyQuizQuestions: 999999, // Unlimited - token-based
      dailyFlashcards: 999999, // Unlimited - token-based
      dailyPdfPages: 999999, // Unlimited - token-based
      dailyUploads: 999999, // Unlimited - token-based
      aiModel: 'gpt-4-turbo',
      priorityProcessing: true,
      monthlyTokens: 5000,
      monthlyYoutubeIngests: 50,
      hasUltraAccess: true,
      maxPdfPages: 200,
      examWeekBoosts: 0,
      maxYouTubeDurationMinutes: 999, // Unlimited for admin
    ),
  };

  // Alias for backward compatibility
  static const Map<SubscriptionTier, TierLimits> tierLimits = limits;

  static TierLimits getLimits(SubscriptionTier tier) {
    return limits[tier] ?? limits[SubscriptionTier.free]!;
  }

  /// Get formatted YouTube duration limit for display
  String get formattedYouTubeDurationLimit {
    if (maxYouTubeDurationMinutes == 0) return 'No access';
    if (maxYouTubeDurationMinutes >= 999) return 'Unlimited';
    if (maxYouTubeDurationMinutes >= 60) {
      final hours = maxYouTubeDurationMinutes ~/ 60;
      final minutes = maxYouTubeDurationMinutes % 60;
      if (minutes == 0) return '${hours}h videos';
      return '${hours}h ${minutes}m videos';
    }
    return '${maxYouTubeDurationMinutes}m videos';
  }

  /// Check if YouTube access is available
  bool get hasYouTubeAccess => maxYouTubeDurationMinutes > 0;
}

// Tier information for UI display
class TierInfo {
  final SubscriptionTier tier;
  final String name;
  final String description;
  final Color color;
  final String? badge;
  final bool isPopular;
  final bool isRecommended;
  final double? price;

  const TierInfo({
    required this.tier,
    required this.name,
    required this.description,
    required this.color,
    this.badge,
    this.isPopular = false,
    this.isRecommended = false,
    this.price,
  });

  static const List<TierInfo> allTiers = [
    TierInfo(
      tier: SubscriptionTier.free,
      name: 'Dendrite',
      description: 'Free tier with basic features',
      color: Color(0xFF9E9E9E),
      price: 0.0,
    ),
    TierInfo(
      tier: SubscriptionTier.axon,
      name: 'Axon',
      description: 'Essential plan with Ultra Mode',
      color: Color(0xFF4CAF50),
      price: 4.99,
    ),
    TierInfo(
      tier: SubscriptionTier.neuron,
      name: 'Neuron',
      description: 'Popular plan with Ultra Mode',
      color: Color(0xFF2196F3),
      isPopular: true,
      isRecommended: true,
      price: 9.99,
    ),
    TierInfo(
      tier: SubscriptionTier.synapse,
      name: 'Synapse',
      description: 'Advanced plan with Ultra Mode',
      color: Color(0xFF9C27B0),
      price: 6.99,
    ),
    TierInfo(
      tier: SubscriptionTier.cortex,
      name: 'Cortex',
      description: 'Advanced plan with Ultra Mode',
      color: Color(0xFF9C27B0),
      price: 14.99,
    ),
    TierInfo(
      tier: SubscriptionTier.singularity,
      name: 'Singularity',
      description: 'Ultimate plan with Ultra Mode',
      color: Color(0xFFFF9800),
      badge: 'BEST VALUE',
      price: 19.99,
    ),

    // Legacy tiers (for backward compatibility during transition)
    TierInfo(
      tier: SubscriptionTier.pro,
      name: 'Pro',
      description: 'Pro plan with Ultra Mode',
      color: Color(0xFF4CAF50),
      price: 6.99,
    ),
    TierInfo(
      tier: SubscriptionTier.admin,
      name: 'Admin',
      description: 'Administrator access',
      color: Color(0xFFF44336),
      price: 0.0,
    ),
  ];

  static TierInfo getTierInfo(SubscriptionTier tier) {
    return allTiers.firstWhere(
      (info) => info.tier == tier,
      orElse: () => allTiers.first,
    );
  }

  static List<TierInfo> getPackATiers() {
    return allTiers
        .where((tier) =>
            tier.tier == SubscriptionTier.free ||
            tier.tier == SubscriptionTier.axon ||
            tier.tier == SubscriptionTier.neuron ||
            tier.tier == SubscriptionTier.cortex ||
            tier.tier == SubscriptionTier.singularity)
        .toList();
  }

  static List<TierInfo> getLegacyTiers() {
    return allTiers
        .where((tier) =>
            tier.tier == SubscriptionTier.pro ||
            tier.tier == SubscriptionTier.admin)
        .toList();
  }
}

class UserSubscription {
  final SubscriptionTier tier;
  final DateTime? renewalDate;
  final DateTime? lastPaymentDate;
  final int examWeekBoostsUsed;
  final bool isActive;

  const UserSubscription({
    required this.tier,
    this.renewalDate,
    this.lastPaymentDate,
    this.examWeekBoostsUsed = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'renewalDate': renewalDate?.millisecondsSinceEpoch,
        'lastPaymentDate': lastPaymentDate?.millisecondsSinceEpoch,
        'examWeekBoostsUsed': examWeekBoostsUsed,
        'isActive': isActive,
      };

  factory UserSubscription.fromMap(Map<String, dynamic> map) =>
      UserSubscription(
        tier: SubscriptionTier.values.firstWhere((t) => t.name == map['tier']),
        renewalDate: map['renewalDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['renewalDate'])
            : null,
        lastPaymentDate: map['lastPaymentDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'])
            : null,
        examWeekBoostsUsed: map['examWeekBoostsUsed'] ?? 0,
        isActive: map['isActive'] ?? true,
      );
}

class DailyUsage {
  final int quizQuestionsUsed;
  final int flashcardsUsed;
  final int uploadsUsed;
  final DateTime lastReset;

  const DailyUsage({
    this.quizQuestionsUsed = 0,
    this.flashcardsUsed = 0,
    this.uploadsUsed = 0,
    required this.lastReset,
  });

  Map<String, dynamic> toMap() => {
        'quizQuestionsUsed': quizQuestionsUsed,
        'flashcardsUsed': flashcardsUsed,
        'uploadsUsed': uploadsUsed,
        'lastReset': lastReset.millisecondsSinceEpoch,
      };

  factory DailyUsage.fromMap(Map<String, dynamic> map) => DailyUsage(
        quizQuestionsUsed: map['quizQuestionsUsed'] ?? 0,
        flashcardsUsed: map['flashcardsUsed'] ?? 0,
        uploadsUsed: map['uploadsUsed'] ?? 0,
        lastReset: DateTime.fromMillisecondsSinceEpoch(map['lastReset']),
      );

  DailyUsage copyWith({
    int? quizQuestionsUsed,
    int? flashcardsUsed,
    int? uploadsUsed,
    DateTime? lastReset,
  }) =>
      DailyUsage(
        quizQuestionsUsed: quizQuestionsUsed ?? this.quizQuestionsUsed,
        flashcardsUsed: flashcardsUsed ?? this.flashcardsUsed,
        uploadsUsed: uploadsUsed ?? this.uploadsUsed,
        lastReset: lastReset ?? this.lastReset,
      );
}

class SystemBudget {
  final double dailyTokensUsed;
  final double dailyTokenLimit;
  final SystemStatus status;
  final DateTime lastReset;

  const SystemBudget({
    required this.dailyTokensUsed,
    required this.dailyTokenLimit,
    required this.status,
    required this.lastReset,
  });

  double get usagePercentage => dailyTokensUsed / dailyTokenLimit;
  bool get isSoftLimitReached => usagePercentage >= 0.8;
  bool get isHardLimitReached => usagePercentage >= 0.95;

  Map<String, dynamic> toMap() => {
        'dailyTokensUsed': dailyTokensUsed,
        'dailyTokenLimit': dailyTokenLimit,
        'status': status.name,
        'lastReset': lastReset.millisecondsSinceEpoch,
      };

  factory SystemBudget.fromMap(Map<String, dynamic> map) => SystemBudget(
        dailyTokensUsed: map['dailyTokensUsed']?.toDouble() ?? 0.0,
        dailyTokenLimit:
            map['dailyTokenLimit']?.toDouble() ?? 1.33 * 24, // $1.33/day
        status: SystemStatus.values.firstWhere((s) => s.name == map['status'],
            orElse: () => SystemStatus.normal),
        lastReset: DateTime.fromMillisecondsSinceEpoch(map['lastReset']),
      );
}
