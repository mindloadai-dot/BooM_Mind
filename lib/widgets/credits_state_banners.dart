import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/screens/paywall_screen.dart';

/// Credits State Banners - Low and empty credit state indicators
///
/// Features:
/// - Low credits banner: compact, non-intrusive warning
/// - Empty credits banner: exciting, persistent strip with buy options
/// - Non-spammy: only shows when appropriate, dismissible
/// - Clear CTAs with specific pricing
/// - Respects user preferences for dismissal
/// - Fully integrated with semantic theme system
class CreditsStateBanners extends StatefulWidget {
  final VoidCallback? onBuyCredits;
  final VoidCallback? onBuyPack;
  final VoidCallback? onAddBrainpower;

  const CreditsStateBanners({
    super.key,
    this.onBuyCredits,
    this.onBuyPack,
    this.onAddBrainpower,
  });

  @override
  State<CreditsStateBanners> createState() => _CreditsStateBannersState();
}

class _CreditsStateBannersState extends State<CreditsStateBanners> {
  bool _lowCreditsDismissed = false;
  bool _emptyCreditsDismissed = false;
  DateTime? _lastLowCreditsShow;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        if (!economy.isInitialized) {
          return const SizedBox.shrink();
        }

        final creditsRemaining = economy.creditsRemaining;

        // Empty state (0 credits) - minimal, persistent strip
        if (creditsRemaining == 0 && !_emptyCreditsDismissed) {
          return _buildMinimalEmptyCreditsBanner(context);
        }

        // Low credits warning (≤ warn threshold, default 2)
        const warnThreshold = 2;
        if (creditsRemaining <= warnThreshold && !_lowCreditsDismissed) {
          // Throttle low credits banner to prevent spam
          final now = DateTime.now();
          if (_lastLowCreditsShow != null &&
              now.difference(_lastLowCreditsShow!).inMinutes < 30) {
            return const SizedBox.shrink();
          }

          return _buildLowCreditsCompactBanner(context, creditsRemaining);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMinimalEmptyCreditsBanner(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.error.withValues(alpha: 0.05),
            tokens.error.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.error.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.error.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Modern Icon with Background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: tokens.error,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Modern Text Layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Out of MindLoad Tokens',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Get tokens to unlock AI-powered learning',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),

          // Modern One-Click Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tokens.primary,
                  tokens.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToTokenPaymentScreen(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        color: tokens.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Get Tokens',
                        style: TextStyle(
                          color: tokens.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Close Button
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _emptyCreditsDismissed = true;
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color: tokens.textSecondary,
              size: 20,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildLowCreditsCompactBanner(
      BuildContext context, int creditsRemaining) {
    final tokens = context.tokens;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.warning.withValues(alpha: 0.05),
            tokens.warning.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.warning.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.warning.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Modern Icon with Background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tokens.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: tokens.warning,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Modern Text Layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low on MindLoad Tokens',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$creditsRemaining tokens remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),

          // Modern Action Button
          Container(
            decoration: BoxDecoration(
              color: tokens.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tokens.warning.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToTokenPaymentScreen(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_shopping_cart_rounded,
                        color: tokens.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Get More',
                        style: TextStyle(
                          color: tokens.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Close Button
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _lowCreditsDismissed = true;
                _lastLowCreditsShow = DateTime.now();
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color: tokens.textSecondary,
              size: 18,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  // Navigation method to token payment screen
  void _navigateToTokenPaymentScreen(BuildContext context) {
    // Navigate to the paywall screen where users can purchase tokens
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(trigger: 'out_of_tokens'),
      ),
    );
  }

  // Handler methods for Logic Pack purchases
  Future<void> _handleBuySparkLogic() async {
    try {
      final success = await InAppPurchaseService.instance.purchaseSparkLogic();
      if (success) {
        // Show success message or refresh credits
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Spark Pack purchased successfully! +50 tokens added.'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: context.tokens.error,
        ),
      );
    }
  }

  Future<void> _handleBuyNeuroLogic() async {
    try {
      final success = await InAppPurchaseService.instance.purchaseNeuroLogic();
      if (success) {
        // Show success message or refresh credits
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Neuro Pack purchased successfully! +100 tokens added.'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: context.tokens.error,
        ),
      );
    }
  }

  Future<void> _handleBuyCortexLogic() async {
    try {
      final success = await InAppPurchaseService.instance.purchaseCortexLogic();
      if (success) {
        // Show success message or refresh credits
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Cortex Pack purchased successfully! +250 tokens added.'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          backgroundColor: context.tokens.error,
        ),
      );
    }
  }
}
