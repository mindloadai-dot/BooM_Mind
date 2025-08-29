import 'package:flutter/material.dart';
import 'package:mindload/constants/product_constants.dart';

// MindLoad Product IDs - Single Source of Truth
// This file centralizes all product identifiers for in-app purchases
// Used across IAP service, paywall, settings, and Firebase backend

class ProductIds {
  // ============================================================================
  // SUBSCRIPTION PLANS (Monthly/Annual)
  // ============================================================================

  // Axon Monthly Subscription
  static const String axonMonthly = 'axon_monthly';
  static const String axonAnnual = 'axon_annual';

  // Neuron Monthly Subscription
  static const String neuronMonthly = 'neuron_monthly';
  static const String neuronAnnual = 'neuron_annual';

  // Cortex Monthly Subscription
  static const String cortexMonthly = 'cortex_monthly';
  static const String cortexAnnual = 'cortex_annual';

  static const String singularityAnnual = 'singularity_annual';

  // ============================================================================
  // LOGIC PACKS (One-time top-ups)
  // ============================================================================

  // Spark Pack (Entry level)
  static const String sparkLogic = 'mindload_spark_logic';

  // Neuro Pack (Popular)
  static const String neuroLogic = 'mindload_neuro_logic';

  // Cortex Pack (Premium)
  static const String cortexLogic = 'mindload_cortex_logic';

  // Quantum Pack (Ultimate)
  static const String quantumLogic = 'mindload_quantum_logic';

  // ============================================================================
  // ALIASES & LEGACY SUPPORT
  // ============================================================================

  // Aliases for backward compatibility
  static const String sparkPack = sparkLogic;
  static const String neuroBurst = neuroLogic;
  static const String cortexPack = cortexLogic;
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
  static const double neuronMonthlyPrice = 9.99; // Fixed from 3.99
  static const double axonMonthlyPrice = ProductConstants.axonMonthlyPriceUsd;
  static const double cortexMonthlyPrice = 14.99;
  static const double singularityMonthlyPrice = 19.99; // Added missing tier

  // MindLoad Logic Pack pricing (One-Time Purchases)
  static const double sparkLogicPrice = ProductConstants.sparkPackPriceUsd;
  static const double neuroLogicPrice = ProductConstants.neuroPackPriceUsd;
  static const double cortexLogicPrice = ProductConstants.cortexPackPriceUsd;
  static const double quantumLogicPrice = ProductConstants.quantumPackPriceUsd;

  // Aliases for backward compatibility
  static const double sparkPackPrice = sparkLogicPrice;
  static const double neuroBurstPrice = neuroLogicPrice;
  static const double cortexPackPrice = cortexLogicPrice;
  static const double quantumPackPrice = quantumLogicPrice;

  // MindLoad Logic Pack token amounts
  static const int sparkLogicTokens = ProductConstants.sparkPackTokens;
  static const int neuroLogicTokens = ProductConstants.neuroPackTokens;
  static const int cortexLogicTokens = ProductConstants.cortexPackTokens;
  static const int quantumLogicTokens = ProductConstants.quantumPackTokens;

  // Pack-A tier monthly credits (MindLoad Tokens) - STANDARDIZED
  static const int neuronMonthlyCredits = 320; // Fixed from 500
  static const int axonMonthlyCredits = ProductConstants.axonMonthlyTokens;
  static const int cortexMonthlyCredits = 750; // Fixed from 3500
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

// Subscription plan definition
class SubscriptionPlan {
  final String productId;
  final String title;
  final String description;
  final String type;
  final double monthlyPrice;
  final double annualPrice;
  final int monthlyTokens;
  final int annualTokens;
  final bool hasIntroOffer;
  final double introPrice;
  final int introDurationDays;
  final List<String> features;
  final String? badge;
  final Color color;
  final bool isPopular;
  final bool isRecommended;

  const SubscriptionPlan({
    required this.productId,
    required this.title,
    required this.description,
    required this.type,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.monthlyTokens,
    required this.annualTokens,
    this.hasIntroOffer = false,
    this.introPrice = 0.0,
    this.introDurationDays = 0,
    required this.features,
    this.badge,
    required this.color,
    this.isPopular = false,
    this.isRecommended = false,
  });

  // Get annual savings percentage
  double get annualSavings {
    final annualCost = annualPrice;
    final monthlyCost = monthlyPrice * 12;
    return ((monthlyCost - annualCost) / monthlyCost) * 100;
  }

  // Get annual savings amount
  double get annualSavingsAmount {
    final annualCost = annualPrice;
    final monthlyCost = monthlyPrice * 12;
    return monthlyCost - annualCost;
  }

  // Check if plan has significant annual savings
  bool get hasSignificantSavings => annualSavings >= 10.0;

  // Get formatted price strings
  String get formattedMonthlyPrice => '\$${monthlyPrice.toStringAsFixed(2)}';
  String get formattedAnnualPrice => '\$${annualPrice.toStringAsFixed(2)}';
  String get formattedIntroPrice => '\$${introPrice.toStringAsFixed(2)}';

  // Get token value per dollar
  double get monthlyTokensPerDollar => monthlyTokens / monthlyPrice;
  double get annualTokensPerDollar => annualTokens / annualPrice;

  // Check if this is the best value plan
  bool get isBestValue => annualTokensPerDollar > 80.0; // 80+ tokens per dollar

  // Static getter for all available plans
  static List<SubscriptionPlan> get availablePlans =>
      SubscriptionPlans.allPlans;

  // Legacy property aliases for backward compatibility
  Color get accentColor => color;
  String get subtitle => description;
  String get displayPrice => formattedMonthlyPrice;
  String get introDescription =>
      '$formattedIntroPrice for $introDurationDays days';

  // Convert string type to SubscriptionType enum
  SubscriptionType get subscriptionType {
    switch (type) {
      case 'axon_monthly':
        return SubscriptionType.axonMonthly;
      case 'neuron_monthly':
        return SubscriptionType.neuronMonthly;
      case 'cortex_monthly':
        return SubscriptionType.cortexMonthly;
      case 'singularity_monthly':
        return SubscriptionType.singularityMonthly;
      default:
        return SubscriptionType.free;
    }
  }
}

// All available subscription plans
class SubscriptionPlans {
  static const List<SubscriptionPlan> allPlans = [
    SubscriptionPlan(
      type: 'axon_monthly',
      productId: ProductIds.axonMonthly,
      title: 'Axon Monthly',
      description: 'Essential plan with Ultra Mode access',
      monthlyPrice: 4.99,
      annualPrice: 54.0,
      monthlyTokens: 120,
      annualTokens: 1440,
      features: [
        '120 tokens/month',
        'Priority queue',
        'Auto-retry',
        '5 exports/month',
        'Up to 10 PDF pages',
        '10 active sets'
      ],
      color: Color(0xFF4CAF50),
      isPopular: true,
    ),
    SubscriptionPlan(
      type: 'neuron_monthly',
      productId: ProductIds.neuronMonthly,
      title: 'Neuron Monthly',
      description: 'Popular plan with Ultra Mode',
      monthlyPrice: 9.99,
      annualPrice: 109.0,
      monthlyTokens: 320,
      annualTokens: 3840,
      features: [
        '320 tokens/month',
        'Credit rollover up to 160',
        'Priority+ queue',
        'Batch export (up to 3 sets)',
        '15 exports/month',
        'Up to 25 PDF pages',
        '25 active sets'
      ],
      color: Color(0xFF2196F3),
      isPopular: true,
      isRecommended: true,
    ),
    SubscriptionPlan(
      type: 'cortex_monthly',
      productId: ProductIds.cortexMonthly,
      title: 'Cortex Monthly',
      description: 'Advanced plan with Ultra Mode',
      monthlyPrice: 14.99,
      annualPrice: 159.0,
      monthlyTokens: 750,
      annualTokens: 9000,
      features: [
        '750 tokens/month',
        'Credit rollover up to 375',
        'Priority+ queue',
        'Batch export (up to 3 sets)',
        '30 exports/month',
        'Up to 50 PDF pages',
        '50 active sets'
      ],
      color: Color(0xFF9C27B0),
    ),
    SubscriptionPlan(
      type: 'singularity_monthly',
      productId: ProductIds.singularityMonthly,
      title: 'Singularity Monthly',
      description: 'Ultimate plan with Ultra Mode',
      monthlyPrice: 19.99,
      annualPrice: 219.0,
      monthlyTokens: 1600,
      annualTokens: 19200,
      features: [
        '1600 tokens/month',
        'Credit rollover up to 800',
        'Priority+ queue',
        'Batch export (up to 3 sets)',
        '50 exports/month',
        'Up to 100 PDF pages',
        '100 active sets'
      ],
      color: Color(0xFFFF9800),
      badge: 'BEST VALUE',
    ),
  ];

  // Get plan by subscription type
  static SubscriptionPlan? getPlan(String type) {
    try {
      return allPlans.firstWhere((plan) => plan.type == type);
    } catch (e) {
      return null;
    }
  }

  // Get plan by product ID
  static SubscriptionPlan? getPlanByProductId(String productId) {
    try {
      return allPlans.firstWhere((plan) => plan.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get recommended plans
  static List<SubscriptionPlan> get recommendedPlans {
    return allPlans.where((plan) => plan.isRecommended).toList();
  }

  // Get popular plans
  static List<SubscriptionPlan> get popularPlans {
    return allPlans.where((plan) => plan.isPopular).toList();
  }

  // Get best value plan
  static SubscriptionPlan? get bestValuePlan {
    try {
      return allPlans.firstWhere((plan) => plan.isBestValue);
    } catch (e) {
      return null;
    }
  }

  // Get plans sorted by monthly price (ascending)
  static List<SubscriptionPlan> get sortedByPrice {
    final sorted = List<SubscriptionPlan>.from(allPlans);
    sorted.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
    return sorted;
  }

  // Get plans sorted by token value (descending)
  static List<SubscriptionPlan> get sortedByValue {
    final sorted = List<SubscriptionPlan>.from(allPlans);
    sorted.sort(
        (a, b) => b.monthlyTokensPerDollar.compareTo(a.monthlyTokensPerDollar));
    return sorted;
  }
}

// Logic Pack product definition
class LogicPackProduct {
  final String productId;
  final String title;
  final String description;
  final double price;
  final int tokens;
  final String? badge;
  final Color color;
  final bool isPopular;
  final bool isRecommended;

  const LogicPackProduct({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.tokens,
    this.badge,
    required this.color,
    this.isPopular = false,
    this.isRecommended = false,
  });

  // Get token value per dollar
  double get tokensPerDollar => tokens / price;

  // Get formatted price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  // Check if this is the best value pack
  bool get isBestValue => tokensPerDollar > 50.0; // 50+ tokens per dollar

  // Legacy property aliases for backward compatibility
  Color get accentColor => color;
  String get displayPrice => formattedPrice;
}

// All available logic pack products
class LogicPackProducts {
  static const List<LogicPackProduct> allProducts = [
    LogicPackProduct(
      productId: ProductIds.sparkLogic,
      title: '⚡ Spark Pack',
      description: 'Quick boost for immediate needs',
      price: PricingConfig.sparkLogicPrice,
      tokens: PricingConfig.sparkLogicTokens,
      color: Color(0xFFFF9800),
      isPopular: true,
    ),
    LogicPackProduct(
      productId: ProductIds.neuroLogic,
      title: '🧠 Neuro Pack',
      description: 'Popular choice for regular users',
      price: PricingConfig.neuroLogicPrice,
      tokens: PricingConfig.neuroLogicTokens,
      color: Color(0xFF2196F3),
      isPopular: true,
      isRecommended: true,
    ),
    LogicPackProduct(
      productId: ProductIds.cortexLogic,
      title: '⚡ Cortex Pack',
      description: 'Premium pack for power users',
      price: PricingConfig.cortexLogicPrice,
      tokens: PricingConfig.cortexLogicTokens,
      color: Color(0xFF9C27B0),
    ),
    LogicPackProduct(
      productId: ProductIds.quantumLogic,
      title: '⚡ Quantum Pack',
      description: 'Ultimate pack for serious learners',
      price: PricingConfig.quantumLogicPrice,
      tokens: PricingConfig.quantumLogicTokens,
      color: Color(0xFFFF5722),
      badge: 'BEST VALUE',
    ),
  ];

  // Get product by product ID
  static LogicPackProduct? getProduct(String productId) {
    try {
      return allProducts
          .firstWhere((product) => product.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Get recommended products
  static List<LogicPackProduct> get recommendedProducts {
    return allProducts.where((product) => product.isRecommended).toList();
  }

  // Get popular products
  static List<LogicPackProduct> get popularProducts {
    return allProducts.where((product) => product.isPopular).toList();
  }

  // Get best value product
  static LogicPackProduct? get bestValueProduct {
    try {
      return allProducts.firstWhere((product) => product.isBestValue);
    } catch (e) {
      return null;
    }
  }

  // Get products sorted by price (ascending)
  static List<LogicPackProduct> get sortedByPrice {
    final sorted = List<LogicPackProduct>.from(allProducts);
    sorted.sort((a, b) => a.price.compareTo(b.price));
    return sorted;
  }

  // Get products sorted by token value (descending)
  static List<LogicPackProduct> get sortedByValue {
    final sorted = List<LogicPackProduct>.from(allProducts);
    sorted.sort((a, b) => b.tokensPerDollar.compareTo(a.tokensPerDollar));
    return sorted;
  }
}

// Token credit allocation for subscription types
class TokenAllocation {
  static int getCreditsForSubscriptionType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return PricingConfig.freeMonthlyCredits;
      case SubscriptionType.axonMonthly:
        return PricingConfig.axonMonthlyCredits;
      case SubscriptionType.neuronMonthly:
        return PricingConfig.neuronMonthlyCredits;
      case SubscriptionType.cortexMonthly:
        return PricingConfig.cortexMonthlyCredits;
      case SubscriptionType.singularityMonthly:
        return PricingConfig.singularityMonthlyCredits;
    }
  }
}

// Legacy product definitions for backward compatibility
class LegacyProducts {
  // Legacy token packs (being replaced by logic packs)
  static const Map<String, Map<String, dynamic>> tokenPacks = {
    'tokens_250': {
      'name': '250 Tokens',
      'price': 2.99,
      'tokens': 250,
      'description': 'Quick token boost',
    },
    'tokens_600': {
      'name': '600 Tokens',
      'price': 5.99,
      'tokens': 600,
      'description': 'Popular token pack',
    },
  };

  // Legacy logic pack (being replaced by new logic packs)
  static const Map<String, dynamic> legacyLogicPack = {
    'name': 'Logic Pack',
    'price': 1.99,
    'credits': 5,
    'description': 'Legacy logic pack',
  };
}

// Product comparison utilities
class ProductComparison {
  // Compare two subscription plans
  static Map<String, dynamic> compareSubscriptionPlans(
    SubscriptionPlan plan1,
    SubscriptionPlan plan2,
  ) {
    final monthlySavings = plan2.monthlyPrice - plan1.monthlyPrice;
    final tokenDifference = plan2.monthlyTokens - plan1.monthlyTokens;
    final valueRatio =
        plan2.monthlyTokensPerDollar / plan1.monthlyTokensPerDollar;

    return {
      'monthlySavings': monthlySavings,
      'tokenDifference': tokenDifference,
      'valueRatio': valueRatio,
      'isBetterValue': valueRatio > 1.0,
      'breakEvenTokens':
          (monthlySavings / plan1.monthlyTokensPerDollar).round(),
    };
  }

  // Compare two logic pack products
  static Map<String, dynamic> compareLogicPacks(
    LogicPackProduct pack1,
    LogicPackProduct pack2,
  ) {
    final priceDifference = pack2.price - pack1.price;
    final tokenDifference = pack2.tokens - pack1.tokens;
    final valueRatio = pack2.tokensPerDollar / pack1.tokensPerDollar;

    return {
      'priceDifference': priceDifference,
      'tokenDifference': tokenDifference,
      'valueRatio': valueRatio,
      'isBetterValue': valueRatio > 1.0,
      'breakEvenTokens': (priceDifference / pack1.tokensPerDollar).round(),
    };
  }

  // Get upgrade recommendations for a user
  static List<Map<String, dynamic>> getUpgradeRecommendations(
    SubscriptionType currentType,
    int currentTokens,
    int targetTokens,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    final currentPlan = SubscriptionPlans.getPlan(currentType.name);

    if (currentPlan == null) return recommendations;

    for (final plan in SubscriptionPlans.allPlans) {
      if (plan.type == currentType.name) continue;

      final comparison = compareSubscriptionPlans(currentPlan, plan);
      if (plan.monthlyTokens >= targetTokens) {
        recommendations.add({
          'plan': plan,
          'comparison': comparison,
          'reason': 'Meets token requirements',
          'priority': 'high',
        });
      } else if (comparison['isBetterValue']) {
        recommendations.add({
          'plan': plan,
          'comparison': comparison,
          'reason': 'Better value per dollar',
          'priority': 'medium',
        });
      }
    }

    // Sort by priority and value
    recommendations.sort((a, b) {
      if (a['priority'] == b['priority']) {
        return (b['comparison']['valueRatio'] as double)
            .compareTo(a['comparison']['valueRatio'] as double);
      }
      return a['priority'] == 'high' ? -1 : 1;
    });

    return recommendations;
  }
}
