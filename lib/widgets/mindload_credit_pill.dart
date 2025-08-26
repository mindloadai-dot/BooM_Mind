import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/widgets/mindload_enforcement_dialog.dart';
import 'package:mindload/screens/paywall_screen.dart';
import 'package:mindload/theme.dart';

/// Mindload Credit Pill Widget
/// Displays current credit status with new economy system
class MindloadCreditPill extends StatefulWidget {
  const MindloadCreditPill({super.key});

  @override
  State<MindloadCreditPill> createState() => _MindloadCreditPillState();
}

class _MindloadCreditPillState extends State<MindloadCreditPill> {
  void _showEconomyDetails() {
    showDialog(
      context: context,
      builder: (context) => const _MindloadEconomyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        if (!economyService.isInitialized) {
          return const _LoadingPill();
        }

        final economy = economyService.userEconomy;
        if (economy == null) {
          return const _ErrorPill();
        }

        final isOutOfCredits = economy.creditsRemaining == 0;
        final isLowCredits = economy.creditsRemaining <= 2 && economy.creditsRemaining > 0;
        final budgetState = economyService.budgetState;

        Color pillColor;
        Color textColor;
        IconData icon;

        if (isOutOfCredits) {
          pillColor = Colors.red.withValues(alpha:  0.1);
          textColor = Colors.red;
          icon = Icons.flash_on; // Use lightning bolt consistently
        } else if (isLowCredits) {
          pillColor = Colors.orange.withValues(alpha:  0.1);
          textColor = Colors.orange;
          icon = Icons.flash_on; // Use lightning bolt consistently
        } else if (budgetState == BudgetState.paused) {
          pillColor = Colors.red.withValues(alpha:  0.1);
          textColor = Colors.red;
          icon = Icons.flash_on; // Use lightning bolt consistently
        } else if (budgetState == BudgetState.savingsMode) {
          pillColor = Colors.orange.withValues(alpha:  0.1);
          textColor = Colors.orange;
          icon = Icons.flash_on; // Use lightning bolt consistently
        } else {
          pillColor = economy.tier.color.withValues(alpha:  0.1);
          textColor = economy.tier.color;
          icon = Icons.flash_on; // Use lightning bolt consistently
        }

        return InkWell(
          onTap: _showEconomyDetails,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: textColor.withValues(alpha:  0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  economy.creditsRemaining.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (budgetState != BudgetState.normal) ...[
                  const SizedBox(width: 4),
                  Icon(
                    budgetState == BudgetState.paused 
                        ? Icons.pause_circle_filled 
                        : Icons.battery_saver,
                    size: 12,
                    color: textColor,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.textSecondary.withValues(alpha:  0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              valueColor: AlwaysStoppedAnimation(tokens.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '...',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha:  0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            'Error',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MindloadEconomyDialog extends StatelessWidget {
  const _MindloadEconomyDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final economy = economyService.userEconomy;
        final budgetState = economyService.budgetState;
        
        if (economy == null) {
          return const AlertDialog(
            title: Text('Economy Error'),
            content: Text('Failed to load economy data.'),
          );
        }

        final outputCounts = economyService.getOutputCounts();
        final limits = economyService.getCurrentLimits();

        final tokens = context.tokens;
        
        return AlertDialog(
          backgroundColor: MindloadTier.axon.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.analytics, color: economy.tier.color),
              const SizedBox(width: 8),
              Text(
                'Mindload Economy',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Credit Status
              MindloadCreditStatus(
                economy: economy,
                budgetState: budgetState,
              ),
              
              const SizedBox(height: 16),
              
              // Current Limits
              _buildLimitsSection(context, limits, economy),
              
              const SizedBox(height: 16),
              
              // Per-Credit Output
              _buildOutputSection(context, outputCounts, budgetState),
              
              const SizedBox(height: 16),
              
              // Next Reset
              _buildResetInfo(context, economy),
            ],
          ),
          actions: [
            if (!economy.isPaidTier)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaywallScreen(trigger: 'credit_pill'),
                      fullscreenDialog: true,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: MindloadTier.axon.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('UPGRADE'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLimitsSection(BuildContext context, Map<String, dynamic> limits, MindloadUserEconomy economy) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.surface.withValues(alpha:  0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Limits',
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          _buildLimitRow(context, 'Paste Limit', '${(limits['pasteCharLimit'] / 1000).round()}K chars', Icons.text_snippet_outlined),
          _buildLimitRow(context, 'PDF Limit', '${limits['pdfPageLimit']} pages', Icons.picture_as_pdf_outlined),
          _buildLimitRow(context, 'Active Sets', '${limits['activeSetCount']}/${limits['activeSetLimit']}', Icons.folder_outlined),
          _buildLimitRow(context, 'Queue', limits['queuePriority'].toString().split('.').last, Icons.priority_high_outlined),
        ],
      ),
    );
  }

  Widget _buildLimitRow(BuildContext context, String label, String value, IconData icon) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection(BuildContext context, Map<String, int> outputCounts, BudgetState budgetState) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha:  0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: tokens.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Per-Credit Output (Dual Batch)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildOutputBadge(context, '${outputCounts['flashcards']} flashcards', Icons.style_outlined),
              const SizedBox(width: 8),
              Text('+', style: TextStyle(color: tokens.textSecondary)),
              const SizedBox(width: 8),
              _buildOutputBadge(context, '${outputCounts['quiz']} quiz', Icons.quiz_outlined),
            ],
          ),
          
          if (budgetState == BudgetState.savingsMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha:  0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.battery_saver, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Efficient mode active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputBadge(BuildContext context, String text, IconData icon) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha:  0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tokens.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetInfo(BuildContext context, MindloadUserEconomy economy) {
    final now = DateTime.now();
    final resetDate = economy.nextResetDate;
    final tokens = context.tokens;
    final difference = resetDate.difference(now);
    
    String resetText;
    if (difference.inDays > 0) {
      resetText = '${difference.inDays}d ${difference.inHours % 24}h';
    } else {
      resetText = '${difference.inHours}h ${difference.inMinutes % 60}m';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: tokens.textSecondary),
          const SizedBox(width: 6),
          Text(
            'ML Tokens reset in $resetText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}