// Product & Pricing Constants - Single Source of Truth
// This file centralizes all product naming, pricing, and token terminology
// Used across paywall, settings, receipts, FAQs, empty states, dialogs, emails/notifications

class ProductConstants {
  // ============================================================================
  // SUBSCRIPTION PLANS
  // ============================================================================

  // Axon Monthly Subscription
  static const String axonMonthlyName = 'Axon Monthly';
  static const String axonMonthlyPrice = '\$4.99/month';
  static const double axonMonthlyPriceUsd = 4.99;
  static const String axonMonthlyDescription =
      'Essential plan with Ultra Mode access';
  static const int axonMonthlyTokens = 120;
  static const int axonMonthlyYtIngests = 1;

  // ============================================================================
  // LOGIC PACKS (One-time top-ups - DO NOT RENAME)
  // ============================================================================

  // Spark Pack
  static const String sparkPackName = 'Spark Pack';
  static const double sparkPackPriceUsd = 2.99;
  static const int sparkPackTokens = 50;
  static const String sparkPackDescription =
      'Cheap "snack" purchase, easy entry point';

  // Neuro Pack
  static const String neuroPackName = 'Neuro Pack';
  static const double neuroPackPriceUsd = 4.99;
  static const int neuroPackTokens = 100;
  static const String neuroPackDescription =
      'Clean \$0.05 per token ratio. Great perceived value upgrade from Spark';

  // Cortex Pack
  static const String cortexPackName = 'Cortex Pack';
  static const double cortexPackPriceUsd = 9.99;
  static const int cortexPackTokens = 250;
  static const String cortexPackDescription =
      'Extra bonus kicks in here (125% vs Neuro). Feels like a bargain';

  // Synapse Pack
  static const String synapsePackName = 'Synapse Pack';
  static const double synapsePackPriceUsd = 19.99;
  static const int synapsePackTokens = 500;
  static const String synapsePackDescription =
      'Power-user pack. Clear 2x value over Cortex';

  // Quantum Pack
  static const String quantumPackName = 'Quantum Pack';
  static const double quantumPackPriceUsd = 49.99;
  static const int quantumPackTokens = 1500;
  static const String quantumPackDescription =
      'Your "whale" pack. This locks in serious spenders at the lowest token-per-dollar rate';

  // ============================================================================
  // TOKEN SYSTEM
  // ============================================================================

  // Token Unit Name (NEVER use "credits")
  static const String tokenUnitName = 'MindLoad Tokens';
  static const String tokenUnitNameShort = 'ML Tokens';

  // Free Monthly Allowance
  static const int freeMonthlyTokens = 20;
  static const String freeMonthlyAllowanceMessage =
      'Every new user gets 20 MindLoad Tokens each month.';

  // ============================================================================
  // CONSUMPTION ORDER & COPY
  // ============================================================================

  // Consumption order: Monthly allowance → Logic Pack balances → Subscription bonuses
  static const String consumptionOrderMessage =
      'Tokens are consumed in this order: 20-Token monthly allowance first, then Logic Pack balances, then any subscription bonuses.';

  // Rollover Policy
  static const String rolloverPolicyMessage =
      'Monthly allowance does not roll over; Logic Pack balances persist month-to-month.';

  // ============================================================================
  // PRODUCT DESCRIPTIONS FOR UI
  // ============================================================================

  // Subscription descriptions
  static const String subscriptionDescription =
      'Unlock unlimited learning with monthly MindLoad Tokens and Ultra Mode access.';

  // Logic Pack descriptions
  static const String logicPackDescription =
      'One-time purchases that add MindLoad Tokens to your account. Tokens never expire and are used after your monthly allowance.';

  // ============================================================================
  // PRICING DISPLAY FORMATS
  // ============================================================================

  // Price formatting helpers
  static String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';
  static String formatMonthlyPrice(double price) =>
      '\$${price.toStringAsFixed(2)}/month';
  static String formatAnnualPrice(double price) =>
      '\$${price.toStringAsFixed(2)}/year';

  // ============================================================================
  // FEATURE DESCRIPTIONS
  // ============================================================================

  // Ultra Mode
  static const String ultraModeFeature =
      'Ultra Mode access for advanced learning';

  // YouTube Ingests
  static const String youtubeIngestFeature =
      'YouTube video processing for study materials';

  // Priority Processing
  static const String priorityProcessingFeature =
      'Priority AI processing for faster results';

  // ============================================================================
  // EMPTY STATE MESSAGES
  // ============================================================================

  static const String noTokensMessage =
      'You\'ve used all your MindLoad Tokens this month.';
  static const String getMoreTokensMessage =
      'Get more MindLoad Tokens with a Logic Pack or upgrade to Axon Monthly for 120 tokens/month.';

  // ============================================================================
  // SETTINGS & ACCOUNT MESSAGES
  // ============================================================================

  static const String currentPlanLabel = 'Current Plan';
  static const String remainingTokensLabel = 'Remaining MindLoad Tokens';
  static const String nextResetLabel = 'Next Reset';
  static const String subscriptionStatusLabel = 'Subscription Status';

  // ============================================================================
  // RECEIPT & BILLING MESSAGES
  // ============================================================================

  static const String receiptTitle = 'MindLoad Purchase Receipt';
  static const String subscriptionReceiptTitle =
      'MindLoad Subscription Receipt';
  static const String logicPackReceiptTitle = 'MindLoad Logic Pack Receipt';

  // ============================================================================
  // FAQ & HELP MESSAGES
  // ============================================================================

  static const String whatAreTokensFaq = 'What are MindLoad Tokens?';
  static const String whatAreTokensAnswer =
      'MindLoad Tokens are the currency that powers AI-powered learning features. Each token allows you to generate study materials, process documents, or use advanced features.';

  static const String howTokensWorkFaq = 'How do MindLoad Tokens work?';
  static const String howTokensWorkAnswer =
      'Tokens are consumed in this order: 1) Your 20-Token monthly allowance, 2) Any Logic Pack balances you\'ve purchased, 3) Subscription bonuses if applicable. Monthly allowance resets each month and doesn\'t roll over.';

  static const String logicPackFaq = 'What are Logic Packs?';
  static const String logicPackAnswer =
      'Logic Packs are one-time purchases that add MindLoad Tokens to your account. These tokens never expire and are used after your monthly allowance is consumed.';

  // ============================================================================
  // NOTIFICATION & EMAIL MESSAGES
  // ============================================================================

  static const String lowTokensNotificationTitle =
      'Running low on MindLoad Tokens';
  static const String lowTokensNotificationBody =
      'You have MindLoad Tokens remaining this month. Consider a Logic Pack for immediate access or upgrade to Axon Monthly for 120 tokens/month.';

  static const String tokensResetNotificationTitle =
      'Your MindLoad Tokens have reset!';
  static const String tokensResetNotificationBody =
      'You now have 20 MindLoad Tokens available for this month.';

  // ============================================================================
  // DIALOG MESSAGES
  // ============================================================================

  static const String confirmPurchaseTitle = 'Confirm Purchase';
  static const String confirmLogicPackMessage =
      'Purchase Logic Pack? This will add MindLoad Tokens to your account.';
  static const String confirmSubscriptionMessage =
      'Subscribe to plan? You\'ll get MindLoad Tokens each month plus Ultra Mode access.';

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================

  static const String insufficientTokensError =
      'Insufficient MindLoad Tokens. You need more tokens than you have available.';
  static const String purchaseFailedError =
      'Purchase failed. Please try again or contact support if the problem persists.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================

  static const String purchaseSuccessMessage =
      'Purchase successful! MindLoad Tokens have been added to your account.';
  static const String subscriptionSuccessMessage =
      'Subscription activated! You now have access to MindLoad Tokens each month plus Ultra Mode.';
}
