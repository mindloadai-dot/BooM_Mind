import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(
        title: 'My Plan & Tokens',
      ),
      body: Consumer<MindloadEconomyService>(
        builder: (context, economyService, child) {
          final userEconomy = economyService.userEconomy;
          if (userEconomy == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _refreshData(economyService),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UnifiedSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Overview
                  _buildCurrentPlanCard(userEconomy),
                  SizedBox(height: UnifiedSpacing.lg),

                  // MindLoad Tokens Status
                  _buildTokensStatusCard(userEconomy),
                  SizedBox(height: UnifiedSpacing.lg),

                  // Available Plans Section
                  _buildAvailablePlansSection(userEconomy),
                  SizedBox(height: UnifiedSpacing.lg),

                  // Logic Packs Section
                  _buildLogicPacksSection(),
                  SizedBox(height: UnifiedSpacing.lg),

                  // Account Information
                  _buildAccountInformationCard(userEconomy),
                  SizedBox(height: UnifiedSpacing.xxxl), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlanCard(MindloadUserEconomy userEconomy) {
    final tokens = context.tokens;
    final tierConfig = MindloadEconomyConfig.tierConfigs[userEconomy.tier];

    return UnifiedCard(
      elevation: 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UnifiedIcon(
                  Icons.workspace_premium,
                  color: userEconomy.tier.color,
                  size: 32,
                ),
                SizedBox(width: UnifiedSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnifiedText(
                        '${userEconomy.tier.displayName} Plan',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textPrimary,
                                ),
                      ),
                      UnifiedText(
                        userEconomy.tier.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: UnifiedSpacing.md),

            // Plan Features
            _buildFeatureRow('Monthly Tokens',
                '${tierConfig?.monthlyTokens ?? 0} MindLoad Tokens'),
            _buildFeatureRow(
                'PDF Pages', 'Up to ${tierConfig?.pdfPageCaps ?? 0} pages'),
            _buildFeatureRow(
                'YouTube Videos',
                tierConfig?.monthlyYoutubeIngests == 0
                    ? 'Not available'
                    : 'Up to ${tierConfig?.monthlyYoutubeIngests} videos/month'),
            _buildFeatureRow(
                'Ultra Mode',
                tierConfig?.hasUltraAccess == true
                    ? 'Available'
                    : 'Not available'),

            if (userEconomy.tier != MindloadTier.free) ...[
              SizedBox(height: UnifiedSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tokens.success.withValues(alpha: 0.3)),
                ),
                child: UnifiedText(
                  'Active until ${_formatDate(userEconomy.nextResetDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokensStatusCard(MindloadUserEconomy userEconomy) {
    final tokens = context.tokens;
    final tierConfig = MindloadEconomyConfig.tierConfigs[userEconomy.tier];
    final monthlyQuota = tierConfig?.monthlyTokens ?? 0;
    final used = monthlyQuota - userEconomy.creditsRemaining;
    final percentage = monthlyQuota > 0 ? (used / monthlyQuota) : 0.0;

    return UnifiedCard(
      elevation: 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UnifiedIcon(Icons.token, color: tokens.primary, size: 28),
                SizedBox(width: UnifiedSpacing.sm),
                UnifiedText(
                  'MindLoad Tokens',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: UnifiedSpacing.sm),

            // Token Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnifiedText(
                        '${userEconomy.creditsRemaining}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                      ),
                      UnifiedText(
                        'remaining',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    UnifiedText(
                      '/ $monthlyQuota',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                    UnifiedText(
                      'monthly',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: UnifiedSpacing.sm),

            // Progress Bar
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: tokens.muted,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8 ? tokens.warning : tokens.primary,
              ),
            ),
            SizedBox(height: UnifiedSpacing.xs),

            UnifiedText(
              '$used tokens used this month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),

            if (userEconomy.rolloverCredits > 0) ...[
              SizedBox(height: UnifiedSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                ),
                child: UnifiedText(
                  '${userEconomy.rolloverCredits} rollover tokens available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlansSection(MindloadUserEconomy userEconomy) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedText(
          'Available Plans',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.sm),

        // Plan Cards
        ...MindloadTier.values
            .where((tier) =>
                tier !=
                MindloadTier.free) // Don't show free tier as upgrade option
            .map((tier) => _buildPlanCard(tier, userEconomy.tier)),
      ],
    );
  }

  Widget _buildPlanCard(MindloadTier tier, MindloadTier currentTier) {
    final tokens = context.tokens;
    final tierConfig = MindloadEconomyConfig.tierConfigs[tier];
    final isCurrentTier = tier == currentTier;
    final isUpgrade = tier.index > currentTier.index;

    return UnifiedCard(
      margin: EdgeInsets.only(bottom: UnifiedSpacing.sm),
      elevation: isCurrentTier ? 4 : 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
             border: isCurrentTier
           ? Border.all(color: tier.color, width: 2)
           : null,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UnifiedIcon(
                  Icons.workspace_premium,
                  color: tier.color,
                  size: 28,
                ),
                SizedBox(width: UnifiedSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnifiedText(
                        tier.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                      ),
                      UnifiedText(
                        tier.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentTier)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tier.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: UnifiedText(
                      'Current',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tier.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: UnifiedSpacing.sm),

            // Plan Features
            _buildFeatureRow('Monthly Tokens',
                '${tierConfig?.monthlyTokens ?? 0} MindLoad Tokens'),
            _buildFeatureRow(
                'PDF Pages', 'Up to ${tierConfig?.pdfPageCaps ?? 0} pages'),
            _buildFeatureRow(
                'YouTube Videos',
                tierConfig?.monthlyYoutubeIngests == 0
                    ? 'Not available'
                    : 'Up to ${tierConfig?.monthlyYoutubeIngests} videos/month'),
            _buildFeatureRow(
                'Ultra Mode',
                tierConfig?.hasUltraAccess == true
                    ? 'Available'
                    : 'Not available'),

            if (tierConfig?.tierPrice != null && tierConfig!.tierPrice > 0) ...[
              SizedBox(height: UnifiedSpacing.sm),
              Row(
                children: [
                  UnifiedText(
                    '\$${tierConfig.tierPrice.toStringAsFixed(2)}/month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.primary,
                        ),
                  ),
                  const Spacer(),
                  if (!isCurrentTier)
                    ElevatedButton(
                      onPressed: isUpgrade ? () => _handleUpgrade(tier) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isUpgrade ? tokens.primary : tokens.muted,
                        foregroundColor:
                            isUpgrade ? tokens.onPrimary : tokens.onMuted,
                      ),
                      child: UnifiedText(isUpgrade ? 'Upgrade' : 'Downgrade'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogicPacksSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedText(
          'Logic Packs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.xs),
        UnifiedText(
          'One-time purchases for additional MindLoad tokens',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.sm),

        // Logic Pack Cards
        _buildLogicPackCard(
            'Spark Pack', '50 MindLoad Tokens', 4.99, Icons.flash_on),
        _buildLogicPackCard(
            'Neuro Pack', '150 MindLoad Tokens', 12.99, Icons.psychology),
        _buildLogicPackCard(
            'Cortex Pack', '500 MindLoad Tokens', 39.99, Icons.memory),
        _buildLogicPackCard('Singularity Pack', '1500 MindLoad Tokens', 99.99,
            Icons.rocket_launch),
      ],
    );
  }

  Widget _buildLogicPackCard(
      String name, String description, double price, IconData icon) {
    final tokens = context.tokens;

    return UnifiedCard(
      margin: EdgeInsets.only(bottom: UnifiedSpacing.sm),
      elevation: 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Row(
          children: [
            UnifiedIcon(icon, color: tokens.primary, size: 32),
            SizedBox(width: UnifiedSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UnifiedText(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                  ),
                  UnifiedText(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UnifiedText(
                  '\$${price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.primary,
                      ),
                ),
                ElevatedButton(
                  onPressed: () => _handleLogicPackPurchase(name, price),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                  ),
                  child: UnifiedText('Buy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInformationCard(MindloadUserEconomy userEconomy) {
    final tokens = context.tokens;

    return UnifiedCard(
      elevation: 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UnifiedText(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
            ),
            SizedBox(height: UnifiedSpacing.sm),
            _buildInfoRow('User ID', userEconomy.userId),
            _buildInfoRow(
                'Plan Status', userEconomy.isActive ? 'Active' : 'Inactive'),
            _buildInfoRow('Last Credit Refill',
                _formatDate(userEconomy.lastCreditRefill)),
            _buildInfoRow(
                'Next Reset Date', _formatDate(userEconomy.nextResetDate)),
            if (userEconomy.subscriptionExpiry != null)
              _buildInfoRow('Subscription Expiry',
                  _formatDate(userEconomy.subscriptionExpiry!)),
            _buildInfoRow('Active Study Sets', '${userEconomy.activeSetCount}'),
            _buildInfoRow(
                'Exports Remaining', '${userEconomy.exportsRemaining}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String value) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: UnifiedSpacing.sm),
      child: Row(
        children: [
          UnifiedIcon(Icons.check_circle, color: tokens.success, size: 16),
          SizedBox(width: UnifiedSpacing.xs),
          UnifiedText(
            feature,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
          ),
          const Spacer(),
          UnifiedText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: UnifiedSpacing.sm),
      child: Row(
        children: [
          UnifiedText(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          const Spacer(),
          UnifiedText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _refreshData(MindloadEconomyService economyService) async {
    HapticFeedbackService().lightImpact();
    try {
      await economyService.initialize();
      HapticFeedbackService().success();
    } catch (e) {
      // Handle error silently for pull-to-refresh
    }
  }

  Future<void> _handleUpgrade(MindloadTier tier) async {
    HapticFeedbackService().mediumImpact();
    // Navigate to MyPlanScreen for upgrade options
    Navigator.pushNamed(context, '/my-plan');
  }

  Future<void> _handleLogicPackPurchase(String packName, double price) async {
    HapticFeedbackService().mediumImpact();
    // Navigate to logic pack purchase screen
    Navigator.pushNamed(context, '/logic-packs');
  }
}
