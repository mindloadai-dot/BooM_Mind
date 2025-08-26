// Mindload Pack-A Pricing Configuration
// Tiers: free (dendrite), axon, neuron, cortex, singularity
// All plans include MindLoad Tokens as single currency

enum PlanId { free, axon, neuron, synapse, cortex, singularity }
enum SubscriptionType { monthly, annual }

class PlanDefinition {
  final double monthly;
  final double annual;
  final int tokens;
  final int ytIngests;
  final int welcomeTokens;
  final bool ytPreview;
  final bool ultra;
  final String name;
  final String description;

  const PlanDefinition({
    required this.monthly,
    required this.annual,
    required this.tokens,
    required this.ytIngests,
    required this.welcomeTokens,
    required this.ytPreview,
    required this.ultra,
    required this.name,
    required this.description,
  });
}

const Map<PlanId, PlanDefinition> PLAN_DEFS = {
  PlanId.free: PlanDefinition(
    monthly: 0,
    annual: 0,
    tokens: 0,
    ytIngests: 0,
    welcomeTokens: 40,
    ytPreview: true,
    ultra: false,
    name: 'Dendrite',
    description: 'Free tier with limited access',
  ),
  PlanId.axon: PlanDefinition(
    monthly: 4.99,
    annual: 54,
    tokens: 120,
    ytIngests: 1,
    welcomeTokens: 0,
    ytPreview: false,
    ultra: true,
    name: 'Axon',
    description: 'Essential plan with Ultra Mode',
  ),
  PlanId.neuron: PlanDefinition(
    monthly: 9.99,
    annual: 109,
    tokens: 320,
    ytIngests: 3,
    welcomeTokens: 0,
    ytPreview: false,
    ultra: true,
    name: 'Neuron',
    description: 'Popular plan with Ultra Mode',
  ),
  PlanId.synapse: PlanDefinition(
    monthly: 6.99,
    annual: 75,
    tokens: 200,
    ytIngests: 2,
    welcomeTokens: 0,
    ytPreview: false,
    ultra: true,
    name: 'Synapse',
    description: 'Advanced plan with Ultra Mode',
  ),
  PlanId.cortex: PlanDefinition(
    monthly: 14.99,
    annual: 159,
    tokens: 750,
    ytIngests: 5,
    welcomeTokens: 0,
    ytPreview: false,
    ultra: true,
    name: 'Cortex',
    description: 'Advanced plan with Ultra Mode',
  ),
  PlanId.singularity: PlanDefinition(
    monthly: 19.99,
    annual: 219,
    tokens: 1600,
    ytIngests: 10,
    welcomeTokens: 0,
    ytPreview: false,
    ultra: true,
    name: 'Singularity',
    description: 'Ultimate plan with Ultra Mode',
  ),
};

const Map<PlanId, Map<SubscriptionType, String>> SKU = {
  PlanId.axon: {
    SubscriptionType.monthly: 'axon_monthly',
    SubscriptionType.annual: 'axon_annual',
  },
  PlanId.neuron: {
    SubscriptionType.monthly: 'neuron_monthly',
    SubscriptionType.annual: 'neuron_annual',
  },
  PlanId.synapse: {
    SubscriptionType.monthly: 'synapse_monthly',
    SubscriptionType.annual: 'synapse_annual',
  },
  PlanId.cortex: {
    SubscriptionType.monthly: 'cortex_monthly',
    SubscriptionType.annual: 'cortex_annual',
  },
  PlanId.singularity: {
    SubscriptionType.monthly: 'singularity_monthly',
    SubscriptionType.annual: 'singularity_annual',
  },
};

const Map<String, String> ADDON_SKUS = {
  't250': 'tokens_250',
  't600': 'tokens_600',
};

bool hasUltraAccess(PlanId plan) => PLAN_DEFS[plan]!.ultra;

double getPlanPrice(PlanId planId, SubscriptionType type) {
  if (planId == PlanId.free) return 0;
  return type == SubscriptionType.monthly 
      ? PLAN_DEFS[planId]!.monthly 
      : PLAN_DEFS[planId]!.annual;
}

int getPlanTokens(PlanId planId) => PLAN_DEFS[planId]!.tokens;

int getPlanYtIngests(PlanId planId) => PLAN_DEFS[planId]!.ytIngests;

String getPlanName(PlanId planId) => PLAN_DEFS[planId]!.name;

String getPlanDescription(PlanId planId) => PLAN_DEFS[planId]!.description;

// Paywall configuration
class PaywallConfig {
  final String title;
  final String subtitle;
  final List<String> features;
  final String cta;

  const PaywallConfig({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.cta,
  });
}

const Map<String, PaywallConfig> PAYWALL_CONFIG = {
  'free': PaywallConfig(
    title: 'Preview Only',
    subtitle: 'No Ultra Mode Access',
    features: ['Limited preview of features'],
    cta: 'Upgrade to unlock Ultra Mode',
  ),
  'paid': PaywallConfig(
    title: 'Ultra Mode Access',
    subtitle: 'Unlock your full potential',
    features: ['Ultra Mode access', 'Priority processing', 'Advanced features'],
    cta: 'Start your journey',
  ),
};
