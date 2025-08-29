import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

import 'package:mindload/theme.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Overview
                  _buildCurrentPlanCard(userEconomy),
                  const SizedBox(height: 20),

                  // MindLoad Tokens Status
                  _buildTokensStatusCard(userEconomy),
                  const SizedBox(height: 20),

                  // Available Plans Section
                  _buildAvailablePlansSection(userEconomy),
                  const SizedBox(height: 24),

                  // Logic Packs Section
                  _buildLogicPacksSection(),
                  const SizedBox(height: 24),

                  // Account Information
                  _buildAccountInformationCard(userEconomy),
                  const SizedBox(height: 100), // Bottom padding
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: userEconomy.tier.color,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userEconomy.tier.displayName} Plan',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textPrimary,
                                ),
                      ),
                      Text(
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
            const SizedBox(height: 20),

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
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tokens.success.withValues(alpha: 0.3)),
                ),
                child: Text(
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.token, color: tokens.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'MindLoad Tokens',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Token Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userEconomy.creditsRemaining}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                      ),
                      Text(
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
                    Text(
                      '/ $monthlyQuota',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                    Text(
                      'monthly',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: tokens.muted,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8 ? tokens.warning : tokens.primary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '$used tokens used this month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),

            if (userEconomy.rolloverCredits > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
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
        Text(
          'Available Plans',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 16),

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentTier ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentTier
            ? BorderSide(color: tier.color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: tier.color,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                      ),
                      Text(
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
                    child: Text(
                      'Current',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tier.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
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
                      child: Text(isUpgrade ? 'Upgrade' : 'Downgrade'),
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
        Text(
          'Logic Packs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'One-time purchases for additional MindLoad tokens',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        const SizedBox(height: 16),

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: tokens.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                  ),
                  Text(
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
                Text(
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
                  child: const Text('Buy'),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: tokens.success, size: 16),
          const SizedBox(width: 8),
          Text(
            feature,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
          ),
          const Spacer(),
          Text(
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
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
