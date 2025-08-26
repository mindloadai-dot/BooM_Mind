import 'package:flutter/material.dart';
import 'package:mindload/constants/product_constants.dart';


// Product IDs for Pack-A tier system
// Same IDs on both iOS and Android as specified in requirements
class ProductIds {
  // Pack-A tier product IDs
  static const String neuronMonthly = 'neuron_monthly';
  static const String axonMonthly = 'axon_monthly';
  static const String synapseMonthly = 'synapse_monthly';
  static const String cortexMonthly = 'cortex_monthly';
  
  // MindLoad Logic Pack product IDs (One-Time Purchases)
  static const String sparkLogic = 'mindload_spark_logic';
  static const String neuroLogic = 'mindload_neuro_logic';
  static const String cortexLogic = 'mindload_cortex_logic';
  static const String synapseLogic = 'mindload_synapse_logic';
  static const String quantumLogic = 'mindload_quantum_logic';
  
  // Aliases for backward compatibility
  static const String sparkPack = sparkLogic;
  static const String neuroBurst = neuroLogic;
  static const String cortexPack = cortexLogic;
  static const String synapsePack = synapseLogic;
  static const String quantumPack = quantumLogic;
  
  // Legacy token product IDs (being replaced by new logic packs)
  static const String tokens250 = 'tokens_250';
  static const String tokens600 = 'tokens_600';
  
  // Legacy product IDs for backward compatibility
  static const String logicPack = 'logic_pack';
  static const String singularityMonthly = 'singularity_monthly';
}

// Pack-A pricing configuration (base USD prices - stores handle currency localization)
class PricingConfig {
  // Pack-A tier pricing (monthly only) - STANDARDIZED
  static const double neuronMonthlyPrice = 9.99;  // Fixed from 3.99
  static const double axonMonthlyPrice = ProductConstants.axonMonthlyPriceUsd;
  static const double synapseMonthlyPrice = 6.99;  // Added missing tier
  static const double cortexMonthlyPrice = 14.99;
  static const double singularityMonthlyPrice = 19.99;  // Added missing tier
  
  // MindLoad Logic Pack pricing (One-Time Purchases)
  static const double sparkLogicPrice = ProductConstants.sparkPackPriceUsd;
  static const double neuroLogicPrice = ProductConstants.neuroPackPriceUsd;
  static const double cortexLogicPrice = ProductConstants.cortexPackPriceUsd;
  static const double synapseLogicPrice = ProductConstants.synapsePackPriceUsd;
  static const double quantumLogicPrice = ProductConstants.quantumPackPriceUsd;
  
  // Aliases for backward compatibility
  static const double sparkPackPrice = sparkLogicPrice;
  static const double neuroBurstPrice = neuroLogicPrice;
  static const double cortexPackPrice = cortexLogicPrice;
  static const double synapsePackPrice = synapseLogicPrice;
  static const double quantumPackPrice = quantumLogicPrice;
  
  // MindLoad Logic Pack token amounts
  static const int sparkLogicTokens = ProductConstants.sparkPackTokens;
  static const int neuroLogicTokens = ProductConstants.neuroPackTokens;
  static const int cortexLogicTokens = ProductConstants.cortexPackTokens;
  static const int synapseLogicTokens = ProductConstants.synapsePackTokens;
  static const int quantumLogicTokens = ProductConstants.quantumPackTokens;
  
  // Pack-A tier monthly credits (MindLoad Tokens) - STANDARDIZED
  static const int neuronMonthlyCredits = 320;  // Fixed from 500
  static const int axonMonthlyCredits = ProductConstants.axonMonthlyTokens;
  static const int synapseMonthlyCredits = 200; // Added missing tier
  static const int cortexMonthlyCredits = 750;  // Fixed from 3500
  static const int singularityMonthlyCredits = 1600; // Fixed from 5000
  
  // Legacy credit quotas
  static const int freeMonthlyCredits = ProductConstants.freeMonthlyTokens;
  static const int maxRolloverCredits = 30;
  
  // Legacy properties for backward compatibility
  static const double tokens250Price = 2.99;
  static const double tokens600Price = 5.99;
  static const double logicPackPrice = 1.99;
  static const int logicPackCredits = 5;
}

// Budget configuration
class BudgetConfig {
  static const double monthlyCapUsd = 120.0;
  static const double warnThreshold = 0.80;
  static const double limitThreshold = 1.00;
  static const double hardThreshold = 1.00;
}

enum SubscriptionType {
  free, // Dendrite tier
  neuronMonthly,
  axonMonthly,
  synapseMonthly,
  cortexMonthly,
  singularityMonthly, // Legacy subscription type
}

enum SubscriptionStatus {
  active,
  expired,
  canceled,
  pendingRenewal,
  introTrialing,
}

enum BudgetMode {
  standard,
  efficient,
}

enum BudgetThreshold {
  normal,
  warn,
  limit,
  hardBlock,
}

class SubscriptionPlan {
  final SubscriptionType type;
  final String productId;
  final double price;
  final String displayPrice;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool hasIntroOffer;
  final double? introPrice;
  final String? introDescription;
  final Color accentColor;
  final String? badge;
  final int mindloadTokens;
  final int youtubeIngests;
  final bool hasUltraAccess;

  const SubscriptionPlan({
    required this.type,
    required this.productId,
    required this.price,
    required this.displayPrice,
    required this.title,
    required this.subtitle,
    required this.features,
    this.hasIntroOffer = false,
    this.introPrice,
    this.introDescription,
    required this.accentColor,
    this.badge,
    required this.mindloadTokens,
    required this.youtubeIngests,
    required this.hasUltraAccess,
  });

  static const List<SubscriptionPlan> availablePlans = [
    SubscriptionPlan(
      type: SubscriptionType.axonMonthly,
      productId: ProductIds.axonMonthly,
      price: ProductConstants.axonMonthlyPriceUsd,
      displayPrice: ProductConstants.axonMonthlyPrice,
      title: ProductConstants.axonMonthlyName,
      subtitle: ProductConstants.axonMonthlyDescription,
      features: [
        '${ProductConstants.axonMonthlyTokens} ${ProductConstants.tokenUnitName}/month',
        '${ProductConstants.axonMonthlyYtIngests} YouTube ingest/month',
        ProductConstants.ultraModeFeature,
        ProductConstants.priorityProcessingFeature,
      ],
      hasIntroOffer: false,
      accentColor: Color(0xFF4CAF50),
      mindloadTokens: ProductConstants.axonMonthlyTokens,
      youtubeIngests: ProductConstants.axonMonthlyYtIngests,
      hasUltraAccess: true,
    ),
    SubscriptionPlan(
      type: SubscriptionType.neuronMonthly,
      productId: ProductIds.neuronMonthly,
      price: 9.99,
      displayPrice: '\$9.99/month',
      title: 'Neuron Monthly',
      subtitle: 'Popular plan with Ultra Mode',
      features: [
        '320 MindLoad Tokens/month',
        '3 YouTube ingests/month',
        'Ultra Mode access',
        'Priority processing',
        'Advanced features',
      ],
      hasIntroOffer: false,
      accentColor: Color(0xFF2196F3),
      mindloadTokens: 320,
      youtubeIngests: 3,
      hasUltraAccess: true,
    ),
    SubscriptionPlan(
      type: SubscriptionType.synapseMonthly,
      productId: ProductIds.synapseMonthly,
      price: 6.99,
      displayPrice: '\$6.99/month',
      title: 'Synapse Monthly',
      subtitle: 'Advanced plan with Ultra Mode',
      features: [
        '200 MindLoad Tokens/month',
        '2 YouTube ingests/month',
        'Ultra Mode access',
        'Priority processing',
        'Advanced features',
      ],
      hasIntroOffer: false,
      accentColor: Color(0xFF9C27B0),
      mindloadTokens: 200,
      youtubeIngests: 2,
      hasUltraAccess: true,
    ),
    SubscriptionPlan(
      type: SubscriptionType.cortexMonthly,
      productId: ProductIds.cortexMonthly,
      price: 14.99,
      displayPrice: '\$14.99/month',
      title: 'Cortex Monthly',
      subtitle: 'Advanced plan with Ultra Mode',
      features: [
        '750 MindLoad Tokens/month',
        '5 YouTube ingests/month',
        'Ultra Mode access',
        'Priority processing',
        'Advanced features',
        'Premium support',
      ],
      hasIntroOffer: false,
      accentColor: Color(0xFFFF9800),
      mindloadTokens: 750,
      youtubeIngests: 5,
      hasUltraAccess: true,
    ),
    SubscriptionPlan(
      type: SubscriptionType.singularityMonthly,
      productId: ProductIds.singularityMonthly,
      price: 19.99,
      displayPrice: '\$19.99/month',
      title: 'Singularity Monthly',
      subtitle: 'Ultimate plan with Ultra Mode',
      features: [
        '1,600 MindLoad Tokens/month',
        '10 YouTube ingests/month',
        'Ultra Mode access',
        'Priority processing',
        'Advanced features',
        'Premium support',
        'Unlimited features',
      ],
      hasIntroOffer: false,
      accentColor: Color(0xFFE91E63),
      mindloadTokens: 1600,
      youtubeIngests: 10,
      hasUltraAccess: true,
    ),
  ];

  // Legacy plans for backward compatibility during transition
  static const List<SubscriptionPlan> legacyPlans = [
    // Pro Monthly plans removed
  ];

  // Get all available plans (Pack-A + legacy during transition)
  static List<SubscriptionPlan> get allPlans => [
    ...availablePlans,
    ...legacyPlans,
  ];

  // Get plan by type
  static SubscriptionPlan? getPlanByType(SubscriptionType type) {
    try {
      return allPlans.firstWhere((plan) => plan.type == type);
    } catch (e) {
      return null;
    }
  }

  // Check if plan has Ultra Mode access
  bool get hasUltraMode => hasUltraAccess;

  // Get MindLoad Tokens for this plan
  int get tokens => mindloadTokens;

  // Get YouTube ingests for this plan
  int get ytIngests => youtubeIngests;
}

// MindLoad Logic Pack plans (One-Time Purchases)
class MindLoadLogicPack {
  final String productId;
  final String title;
  final String subtitle;
  final int tokens;
  final double price;
  final String displayPrice;
  final String description;
  final Color accentColor;
  final bool isPopular;
  final bool isBestValue;
  final IconData icon;

  const MindLoadLogicPack({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.tokens,
    required this.price,
    required this.displayPrice,
    required this.description,
    required this.accentColor,
    this.isPopular = false,
    this.isBestValue = false,
    required this.icon,
  });

  static final List<MindLoadLogicPack> availableLogicPacks = [
    MindLoadLogicPack(
      productId: ProductIds.sparkLogic,
              title: '⚡ Spark Pack',
      subtitle: '50 ML Tokens',
      tokens: PricingConfig.sparkLogicTokens,
      price: PricingConfig.sparkLogicPrice,
      displayPrice: '\$2.99',
      description: 'Quick start for exploring features',
      accentColor: Color(0xFF4CAF50),
      icon: Icons.flash_on,
    ),
    MindLoadLogicPack(
      productId: ProductIds.neuroLogic,
              title: '🔬 Neuro Pack',
      subtitle: '100 ML Tokens',
      tokens: PricingConfig.neuroLogicTokens,
      price: PricingConfig.neuroLogicPrice,
      displayPrice: '\$2.99',
      description: 'Boost your learning momentum',
      accentColor: Color(0xFF2196F3),
      icon: Icons.science,
    ),
    MindLoadLogicPack(
      productId: ProductIds.cortexLogic,
      title: '🧠 Cortex Pack',
      subtitle: '250 ML Tokens',
      tokens: PricingConfig.cortexLogicTokens,
      price: PricingConfig.cortexLogicPrice,
      displayPrice: '\$9.99',
      description: 'Extra bonus kicks in here (125% vs Neuro). Feels like a bargain',
      accentColor: Color(0xFF9C27B0),
      icon: Icons.science,
    ),
    MindLoadLogicPack(
      productId: ProductIds.synapseLogic,
      title: '⚡ Synapse Pack',
      subtitle: '500 ML Tokens',
      tokens: PricingConfig.synapseLogicTokens,
      price: PricingConfig.synapseLogicPrice,
      displayPrice: '\$19.99',
      description: 'Power-user pack. Clear 2x value over Cortex',
      accentColor: Color(0xFFFF9800),
      isPopular: true,
      icon: Icons.electric_bolt,
    ),
    MindLoadLogicPack(
      productId: ProductIds.quantumLogic,
      title: '🌌 Quantum Pack',
      subtitle: '1,500 ML Tokens',
      tokens: PricingConfig.quantumLogicTokens,
      price: PricingConfig.quantumLogicPrice,
      displayPrice: '\$49.99',
      description: 'Your "whale" pack. This locks in serious spenders at the lowest token-per-dollar rate',
      accentColor: Color(0xFFE91E63),
      isBestValue: true,
      icon: Icons.auto_awesome,
    ),
  ];
}

// Legacy token add-on plans (being replaced by MindLoad Logic Packs)
class TokenAddonPlan {
  final String productId;
  final String title;
  final int tokens;
  final double price;
  final String displayPrice;
  final Color accentColor;

  const TokenAddonPlan({
    required this.productId,
    required this.title,
    required this.tokens,
    required this.price,
    required this.displayPrice,
    required this.accentColor,
  });

  static const List<TokenAddonPlan> availableAddons = [
    TokenAddonPlan(
      productId: ProductIds.tokens250,
      title: '250 MindLoad Tokens',
      tokens: 250,
      price: PricingConfig.tokens250Price,
      displayPrice: '\$2.99',
      accentColor: Color(0xFF4CAF50),
    ),
    TokenAddonPlan(
      productId: ProductIds.tokens600,
      title: '600 MindLoad Tokens',
      tokens: 600,
      price: PricingConfig.tokens600Price,
      displayPrice: '\$5.99',
      accentColor: Color(0xFF2196F3),
    ),
  ];
}

class CreditPack {
  final String productId;
  final double price;
  final int credits;
  final String title;
  final String description;
  final String displayPrice;
  final Color accentColor;

  const CreditPack({
    required this.productId,
    required this.price,
    required this.credits,
    required this.title,
    required this.description,
    required this.displayPrice,
    required this.accentColor,
  });

  // Legacy logic pack (being replaced by MindLoad Logic Packs)
  static const CreditPack logicPack = CreditPack(
    productId: ProductIds.logicPack,
    price: PricingConfig.logicPackPrice,
    credits: PricingConfig.logicPackCredits,
    title: 'Logic Pack',
            description: '+50 tokens immediately available',
    displayPrice: '\$1.99', // Store handles local currency
    accentColor: Color(0xFF2196F3),
  );
}

class UserSubscriptionNew {
  final String userId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final DateTime? renewalDate;
  final bool autoRenew;
  final int creditsRemaining;
  final int creditsUsedThisMonth;
  final int rolloverCredits; // Pro only
  final DateTime? lastCreditRefill;
  final bool hasIntroOfferUsed;

  const UserSubscriptionNew({
    required this.userId,
    required this.type,
    required this.status,
    this.purchaseDate,
    this.expiryDate,
    this.renewalDate,
    this.autoRenew = true,
    required this.creditsRemaining,
    this.creditsUsedThisMonth = 0,
    this.rolloverCredits = 0,
    this.lastCreditRefill,
    this.hasIntroOfferUsed = false,
  });

  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.introTrialing;
  bool get isPro => false; // Pro Monthly removed
  bool get isIntroTrialing => status == SubscriptionStatus.introTrialing;
  bool get canRollover => false; // Pro Monthly removed

  int get monthlyQuota {
    switch (type) {
      case SubscriptionType.free:
        return PricingConfig.freeMonthlyCredits;
      case SubscriptionType.axonMonthly:
        return PricingConfig.axonMonthlyCredits;
      case SubscriptionType.neuronMonthly:
        return PricingConfig.neuronMonthlyCredits;
      case SubscriptionType.synapseMonthly:
        return PricingConfig.synapseMonthlyCredits;
      case SubscriptionType.cortexMonthly:
        return PricingConfig.cortexMonthlyCredits;
      case SubscriptionType.singularityMonthly:
        return PricingConfig.singularityMonthlyCredits;
    }
  }

  UserSubscriptionNew copyWith({
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    DateTime? renewalDate,
    bool? autoRenew,
    int? creditsRemaining,
    int? creditsUsedThisMonth,
    int? rolloverCredits,
    DateTime? lastCreditRefill,
    bool? hasIntroOfferUsed,
  }) {
    return UserSubscriptionNew(
      userId: userId,
      type: type ?? this.type,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      renewalDate: renewalDate ?? this.renewalDate,
      autoRenew: autoRenew ?? this.autoRenew,
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      creditsUsedThisMonth: creditsUsedThisMonth ?? this.creditsUsedThisMonth,
      rolloverCredits: rolloverCredits ?? this.rolloverCredits,
      lastCreditRefill: lastCreditRefill ?? this.lastCreditRefill,
      hasIntroOfferUsed: hasIntroOfferUsed ?? this.hasIntroOfferUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'renewalDate': renewalDate?.millisecondsSinceEpoch,
      'autoRenew': autoRenew,
      'creditsRemaining': creditsRemaining,
      'creditsUsedThisMonth': creditsUsedThisMonth,
      'rolloverCredits': rolloverCredits,
      'lastCreditRefill': lastCreditRefill?.millisecondsSinceEpoch,
      'hasIntroOfferUsed': hasIntroOfferUsed,
    };
  }

  factory UserSubscriptionNew.fromMap(Map<String, dynamic> map, String userId) {
    return UserSubscriptionNew(
      userId: userId,
      type: SubscriptionType.values.firstWhere((e) => e.name == map['type'], orElse: () => SubscriptionType.free),
      status: SubscriptionStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => SubscriptionStatus.active),
      purchaseDate: map['purchaseDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['purchaseDate']) : null,
      expiryDate: map['expiryDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate']) : null,
      renewalDate: map['renewalDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['renewalDate']) : null,
      autoRenew: map['autoRenew'] ?? true,
      creditsRemaining: map['creditsRemaining'] ?? PricingConfig.freeMonthlyCredits,
      creditsUsedThisMonth: map['creditsUsedThisMonth'] ?? 0,
      rolloverCredits: map['rolloverCredits'] ?? 0,
      lastCreditRefill: map['lastCreditRefill'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastCreditRefill']) : null,
      hasIntroOfferUsed: map['hasIntroOfferUsed'] ?? false,
    );
  }
}

class SystemBudgetNew {
  final double monthlySpentUsd;
  final double monthlyLimitUsd;
  final BudgetThreshold currentThreshold;
  final BudgetMode currentMode;
  final DateTime lastReset;
  final DateTime resetDate;

  const SystemBudgetNew({
    required this.monthlySpentUsd,
    required this.monthlyLimitUsd,
    required this.currentThreshold,
    required this.currentMode,
    required this.lastReset,
    required this.resetDate,
  });

  double get usagePercentage => monthlySpentUsd / monthlyLimitUsd;
  bool get isAtWarnThreshold => usagePercentage >= BudgetConfig.warnThreshold;
  bool get isAtLimitThreshold => usagePercentage >= BudgetConfig.limitThreshold;
  bool get isAtHardThreshold => usagePercentage >= BudgetConfig.hardThreshold;

  BudgetThreshold getThresholdLevel() {
    if (isAtHardThreshold) return BudgetThreshold.hardBlock;
    if (isAtLimitThreshold) return BudgetThreshold.limit;
    if (isAtWarnThreshold) return BudgetThreshold.warn;
    return BudgetThreshold.normal;
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlySpentUsd': monthlySpentUsd,
      'monthlyLimitUsd': monthlyLimitUsd,
      'currentThreshold': currentThreshold.name,
      'currentMode': currentMode.name,
      'lastReset': lastReset.millisecondsSinceEpoch,
      'resetDate': resetDate.millisecondsSinceEpoch,
    };
  }

  factory SystemBudgetNew.fromMap(Map<String, dynamic> map) {
    return SystemBudgetNew(
      monthlySpentUsd: map['monthlySpentUsd']?.toDouble() ?? 0.0,
      monthlyLimitUsd: map['monthlyLimitUsd']?.toDouble() ?? BudgetConfig.monthlyCapUsd,
      currentThreshold: BudgetThreshold.values.firstWhere((e) => e.name == map['currentThreshold'], orElse: () => BudgetThreshold.normal),
      currentMode: BudgetMode.values.firstWhere((e) => e.name == map['currentMode'], orElse: () => BudgetMode.standard),
      lastReset: DateTime.fromMillisecondsSinceEpoch(map['lastReset']),
      resetDate: DateTime.fromMillisecondsSinceEpoch(map['resetDate']),
    );
  }

  SystemBudgetNew copyWith({
    double? monthlySpentUsd,
    double? monthlyLimitUsd,
    BudgetThreshold? currentThreshold,
    BudgetMode? currentMode,
    DateTime? lastReset,
    DateTime? resetDate,
  }) {
    return SystemBudgetNew(
      monthlySpentUsd: monthlySpentUsd ?? this.monthlySpentUsd,
      monthlyLimitUsd: monthlyLimitUsd ?? this.monthlyLimitUsd,
      currentThreshold: currentThreshold ?? this.currentThreshold,
      currentMode: currentMode ?? this.currentMode,
      lastReset: lastReset ?? this.lastReset,
      resetDate: resetDate ?? this.resetDate,
    );
  }
}

// Telemetry events as specified in requirements
enum TelemetryEvent {
  paywallView,
  paywallExit,
  introStarted,
  introConverted,
  introRenewed,
  logicPackShown,
  logicPackBought,
  generationBlockedFree,
  generationBlockedBudget,
  budgetWarn,
  budgetLimit,
  budgetHardBlock,
  // New international purchase lifecycle events
  purchaseStart,
  purchaseSuccess,
  purchaseFail,
  restoreSuccess,
  refundReceived,
  entitlementChanged,
}

extension TelemetryEventExtension on TelemetryEvent {
  String get name {
    switch (this) {
      case TelemetryEvent.paywallView:
        return 'paywall_view';
      case TelemetryEvent.paywallExit:
        return 'paywall_exit';
      case TelemetryEvent.introStarted:
        return 'intro_started';
      case TelemetryEvent.introConverted:
        return 'intro_converted';
      case TelemetryEvent.introRenewed:
        return 'intro_renewed';
      case TelemetryEvent.logicPackShown:
        return 'logic_pack_shown';
      case TelemetryEvent.logicPackBought:
        return 'logic_pack_bought';
      case TelemetryEvent.generationBlockedFree:
        return 'generation_blocked_free';
      case TelemetryEvent.generationBlockedBudget:
        return 'generation_blocked_budget';
      case TelemetryEvent.budgetWarn:
        return 'budget_warn';
      case TelemetryEvent.budgetLimit:
        return 'budget_limit';
      case TelemetryEvent.budgetHardBlock:
        return 'budget_hard_block';
      case TelemetryEvent.purchaseStart:
        return 'purchase_start';
      case TelemetryEvent.purchaseSuccess:
        return 'purchase_success';
      case TelemetryEvent.purchaseFail:
        return 'purchase_fail';
      case TelemetryEvent.restoreSuccess:
        return 'restore_success';
      case TelemetryEvent.refundReceived:
        return 'refund_received';
      case TelemetryEvent.entitlementChanged:
        return 'entitlement_changed';
    }
  }
}

class TelemetryEventData {
  final TelemetryEvent event;
  final DateTime timestamp;
  final Map<String, dynamic> parameters;

  const TelemetryEventData({
    required this.event,
    required this.timestamp,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'parameters': parameters,
    };
  }
}

// Token Pricing and Consumption Rules

class TokenPricingRules {
  // Equivalence constants
  static const int WORDS_PER_TOKEN = 1000;
  static const int YOUTUBE_MINUTES_PER_TOKEN = 5;
  static const int CARD_SET_SIZE = 10;
  static const int MCQ_SET_SIZE = 6;
  static const int MONTHLY_FREE_ACTIONS = 20;

  // Token cost calculation methods
  static int calculateTextGenerationTokens(int wordCount) {
    return (wordCount / WORDS_PER_TOKEN).ceil();
  }

  static int calculateYouTubeTokens(int minutes) {
    return (minutes / YOUTUBE_MINUTES_PER_TOKEN).ceil();
  }

  static int calculateRegenerateTokens(int itemCount, bool isCards) {
    final setSize = isCards ? CARD_SET_SIZE : MCQ_SET_SIZE;
    return (itemCount / setSize).ceil();
  }

  static int calculateReorganizeTokens(int setCount) {
    return setCount;
  }
}

class TokenTier {
  final String name;
  final double price;
  final int monthlyTokens;
  final String emoji;

  const TokenTier({
    required this.name, 
    required this.price, 
    required this.monthlyTokens,
    required this.emoji,
  });

  static final List<TokenTier> tiers = [
    TokenTier(
      name: 'Dendrite', 
      price: 0.0, 
      monthlyTokens: ProductConstants.freeMonthlyTokens,
      emoji: '🌱',
    ),
    TokenTier(
      name: 'Axon', 
      price: ProductConstants.axonMonthlyPriceUsd, 
      monthlyTokens: ProductConstants.axonMonthlyTokens,
      emoji: '🧩',
    ),
    TokenTier(
      name: 'Neuron', 
      price: 9.99, 
      monthlyTokens: 320,
      emoji: '⚡',
    ),
    TokenTier(
      name: 'Synapse', 
      price: 6.99, 
      monthlyTokens: 200,
      emoji: '🔗',
    ),
    TokenTier(
      name: 'Cortex', 
      price: 14.99, 
      monthlyTokens: 750,
      emoji: '🧬',
    ),
    TokenTier(
      name: 'Singularity', 
      price: 19.99, 
      monthlyTokens: 1600,
      emoji: '🌟',
    ),
  ];
}

class LogicPack {
  final String name;
  final double price;
  final int tokens;
  final String emoji;
  final bool isPopular;
  final bool isBestValue;

  const LogicPack({
    required this.name,
    required this.price,
    required this.tokens,
    required this.emoji,
    this.isPopular = false,
    this.isBestValue = false,
  });

  static final List<LogicPack> packs = [
    LogicPack(
      name: ProductConstants.sparkPackName, 
      price: ProductConstants.sparkPackPriceUsd, 
      tokens: ProductConstants.sparkPackTokens,
      emoji: '⚡',
    ),
    LogicPack(
      name: ProductConstants.neuroPackName, 
      price: ProductConstants.neuroPackPriceUsd, 
      tokens: ProductConstants.neuroPackTokens,
      emoji: '🔬',
    ),
    LogicPack(
      name: ProductConstants.cortexPackName, 
      price: ProductConstants.cortexPackPriceUsd, 
      tokens: ProductConstants.cortexPackTokens,
      emoji: '📚',
    ),
    LogicPack(
      name: ProductConstants.synapsePackName, 
      price: ProductConstants.synapsePackPriceUsd, 
      tokens: ProductConstants.synapsePackTokens,
      emoji: '🧠',
      isPopular: true,
    ),
    LogicPack(
      name: ProductConstants.quantumPackName, 
      price: ProductConstants.quantumPackPriceUsd, 
      tokens: ProductConstants.quantumPackTokens,
      emoji: '🌩',
      isBestValue: true,
    ),
  ];
}

class UserTokenAccount {
  int monthlyTokens;
  int welcomeBonus;
  int freeActions;
  DateTime lastResetDate;

  UserTokenAccount({
    this.monthlyTokens = 0,
    this.welcomeBonus = ProductConstants.freeMonthlyTokens,
    this.freeActions = ProductConstants.freeMonthlyTokens,
    DateTime? lastResetDate,
  }) : lastResetDate = lastResetDate ?? DateTime.now();

  bool canAffordAction(int requiredTokens) {
    // Consumption order: Free actions → Welcome Bonus → user tokens
    int availableTokens = freeActions + welcomeBonus + monthlyTokens;
    return availableTokens >= requiredTokens;
  }

  void deductTokens(int tokens) {
    // Deduct from free actions first
    if (freeActions >= tokens) {
      freeActions -= tokens;
      return;
    }
    tokens -= freeActions;
    freeActions = 0;

    // Then deduct from welcome bonus
    if (welcomeBonus >= tokens) {
      welcomeBonus -= tokens;
      return;
    }
    tokens -= welcomeBonus;
    welcomeBonus = 0;

    // Finally deduct from monthly tokens
    monthlyTokens -= tokens;
  }

  void resetMonthlyTokens(TokenTier tier) {
    // Reset on 1st of month, 00:00 America/Chicago
    final now = DateTime.now().toUtc();
    final resetTime = DateTime.utc(now.year, now.month, 1);
    
    if (lastResetDate.isBefore(resetTime)) {
      monthlyTokens = tier.monthlyTokens;
      freeActions = ProductConstants.freeMonthlyTokens;
      lastResetDate = resetTime;
    }
  }
}