import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:intl/intl.dart';
import 'package:mindload/screens/enhanced_subscription_screen.dart'; // Added import for EnhancedSubscriptionScreen
import 'package:mindload/screens/tiers_benefits_screen.dart'; // Added import for TiersBenefitsScreen
import 'package:mindload/screens/subscription_settings_screen.dart'; // Added import for SubscriptionSettingsScreen

/// TokenChip - Always visible credits display with budget state indicators
/// 
/// Features:
/// - Shows current credit balance
/// - Budget state icon (normal/savings/paused) with glow animation
/// - Tap opens Credits Drawer
/// - Long press opens Buy Credits sheet
/// - Full accessibility support
class CreditsTokenChip extends StatefulWidget {
  final VoidCallback? onBuyCreditsPressed;
  final VoidCallback? onViewLedgerPressed;
  final VoidCallback? onUpgradePressed;

  const CreditsTokenChip({
    super.key,
    this.onBuyCreditsPressed,
    this.onViewLedgerPressed,
    this.onUpgradePressed,
  });

  @override
  State<CreditsTokenChip> createState() => _CreditsTokenChipState();
}

class _CreditsTokenChipState extends State<CreditsTokenChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // Start the glow animation and repeat
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        if (!economy.isInitialized) {
          return _buildLoadingSkeleton(tokens);
        }

        return Semantics(
          label: buildCreditsAccessibilityLabel(
            economy.creditsRemaining,
            economy.budgetState,
            economy.userEconomy?.nextResetDate ?? DateTime.now(),
          ),
          button: true,
          child: GestureDetector(
            onTap: () => _openCreditsDrawer(context),
            onLongPress: () => _openBuyCreditsSheet(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha:  0.8),
                border: Border.all(
                  color: tokens.borderDefault.withValues(alpha:  0.6),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: tokens.overlayDim.withValues(alpha:  0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lightning bolt icon with glow animation
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _getBudgetStateColor(economy.budgetState, tokens)
                                  .withValues(alpha:  _glowAnimation.value * 0.6),
                              blurRadius: 8 * _glowAnimation.value,
                              spreadRadius: 2 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flash_on,
                          size: 16,
                          color: _getBudgetStateColor(economy.budgetState, tokens)
                              .withValues(alpha:  0.7 + (_glowAnimation.value * 0.3)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // Credits number only
                  Text(
                    '${economy.creditsRemaining}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBudgetStateColor(BudgetState state, SemanticTokens tokens) {
    switch (state) {
      case BudgetState.normal:
        return tokens.success;
      case BudgetState.savingsMode:
        return tokens.warning;
      case BudgetState.paused:
        return tokens.error;
    }
  }

  Widget _buildLoadingSkeleton(SemanticTokens tokens) {
    return Container(
      height: 36,
      width: 64, // Smaller horizontal format
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha:  0.4),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha:  0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: tokens.textTertiary.withValues(alpha:  0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 12,
            decoration: BoxDecoration(
              color: tokens.textTertiary.withValues(alpha:  0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreditsDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreditsDrawer(
        onBuyCreditsPressed: widget.onBuyCreditsPressed,
        onViewLedgerPressed: widget.onViewLedgerPressed,
        onUpgradePressed: widget.onUpgradePressed,
      ),
    );
  }

  void _openBuyCreditsSheet(BuildContext context) {
    if (widget.onBuyCreditsPressed != null) {
      widget.onBuyCreditsPressed!();
    } else {
      // Default buy credits sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const BuyCreditsSheet(),
      );
    }
  }
}

/// Helper function to build accessibility label for credits chip
String buildCreditsAccessibilityLabel(
  int creditsRemaining,
  BudgetState budgetState,
  DateTime nextResetDate,
) {
  final formatter = DateFormat('MMM d, yyyy h:mm a');
  final resetFormatted = formatter.format(nextResetDate);
  
  String budgetStateText;
  switch (budgetState) {
    case BudgetState.normal:
      budgetStateText = 'Normal';
      break;
    case BudgetState.savingsMode:
      budgetStateText = 'Savings';
      break;
    case BudgetState.paused:
      budgetStateText = 'Paused';
      break;
  }
  
  return '$creditsRemaining tokens available. Budget: $budgetStateText. Resets $resetFormatted America/Chicago.';
}

/// Credits Drawer - Detailed credits information and actions
class CreditsDrawer extends StatelessWidget {
  final VoidCallback? onBuyCreditsPressed;
  final VoidCallback? onViewLedgerPressed;
  final VoidCallback? onUpgradePressed;

  const CreditsDrawer({
    super.key,
    this.onBuyCreditsPressed,
    this.onViewLedgerPressed,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 16,
        right: 16,
        top: 64,
      ),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(16),
        ),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Consumer<MindloadEconomyService>(
        builder: (context, economy, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Mindload Tokens',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Credits overview
              _buildCreditsOverview(context, economy, tokens),

              // Budget state info
              if (economy.budgetState != BudgetState.normal)
                _buildBudgetStateInfo(context, economy, tokens),

              // Mini explainer
              _buildMiniExplainer(context, economy, tokens),

              // Action buttons
              _buildActionButtons(context, economy, tokens),

              // Bottom safe area
              SizedBox(height: mediaQuery.padding.bottom + 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreditsOverview(BuildContext context, MindloadEconomyService economy, SemanticTokens tokens) {
    final resetDate = economy.userEconomy?.nextResetDate ?? DateTime.now();
    final resetDateFormatted = DateFormat('MMM d, h:mm a').format(resetDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              Text(
                '${economy.creditsRemaining}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Usage this month
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used / Granted this month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              Text(
                '${economy.userEconomy?.creditsUsedThisMonth ?? 0} / ${economy.userEconomy?.monthlyQuota ?? 0}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reset info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              Text(
                '$resetDateFormatted CT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStateInfo(BuildContext context, MindloadEconomyService economy, SemanticTokens tokens) {
    String message;
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (economy.budgetState) {
      case BudgetState.savingsMode:
        message = 'Savings Mode on: output reduced.';
        bgColor = tokens.warning.withValues(alpha:  0.1);
        textColor = tokens.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case BudgetState.paused:
        message = 'Budget met—new generations resume next month. Exports of existing content allowed.';
        bgColor = tokens.error.withValues(alpha:  0.1);
        textColor = tokens.error;
        icon = Icons.pause_circle_filled;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha:  0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniExplainer(BuildContext context, MindloadEconomyService economy, SemanticTokens tokens) {
    final outputCounts = economy.getOutputCounts();
    final flashcards = outputCounts['flashcards'] ?? 50;
    final quiz = outputCounts['quiz'] ?? 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha:  0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha:  0.3),
          width: 1,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Per token — ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            TextSpan(
              text: economy.currentTier.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: economy.currentTier.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ': $flashcards cards + $quiz quiz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MindloadEconomyService economy, SemanticTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary: Get ML Tokens
          ElevatedButton.icon(
            onPressed: onBuyCreditsPressed ?? () {
              // Default action: navigate to subscription screen
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const EnhancedSubscriptionScreen(),
              ));
            },
            icon: const Icon(Icons.subscriptions, size: 20),
            label: const Text('Get ML Tokens'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary actions row
          Row(
            children: [
              // Upgrade button (if not top tier)
              if (economy.currentTier != MindloadTier.cortex && 
                  economy.currentTier != MindloadTier.singularity)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onUpgradePressed ?? () {
                      // Default action: navigate to tiers and benefits screen
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const TiersBenefitsScreen(),
                      ));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: tokens.borderDefault,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Upgrade',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (economy.currentTier != MindloadTier.cortex && 
                  economy.currentTier != MindloadTier.singularity)
                const SizedBox(width: 12),

              // View Ledger
              Expanded(
                child: TextButton(
                  onPressed: onViewLedgerPressed ?? () {
                    // Default action: navigate to subscription settings for ledger
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const SubscriptionSettingsScreen(),
                    ));
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Ledger',
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Buy Credits Sheet - Direct purchase interface
class BuyCreditsSheet extends StatelessWidget {
  const BuyCreditsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 16,
        right: 16,
        top: 64,
      ),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(16),
        ),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Get ML Tokens',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Credit options
          _buildCreditOptions(context, tokens),

          // Bottom safe area
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCreditOptions(BuildContext context, SemanticTokens tokens) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Information about subscription-based tokens
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: tokens.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Get ML Tokens with Subscriptions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to get monthly ML Tokens for generating study materials. Higher tiers provide more tokens and better output quality.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Primary action button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close this sheet
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const EnhancedSubscriptionScreen(),
              ));
            },
            icon: const Icon(Icons.subscriptions, size: 20),
            label: const Text('View Subscription Plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Secondary action
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close this sheet
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const TiersBenefitsScreen(),
              ));
            },
            icon: const Icon(Icons.trending_up, size: 20),
            label: const Text('Compare Tiers & Benefits'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: tokens.borderDefault, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

