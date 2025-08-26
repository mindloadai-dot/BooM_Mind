import 'package:flutter/material.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/theme.dart';

/// Credit Enforcement Dialog
/// Shows blocking reasons and suggested actions when limits are reached
class MindloadEnforcementDialog extends StatelessWidget {
  final EnforcementResult result;
  final VoidCallback? onUpgrade;
  final VoidCallback? onBuyCredits;
  final VoidCallback? onArchiveSets;
  final VoidCallback? onTrimContent;

  const MindloadEnforcementDialog({
    super.key,
    required this.result,
    this.onUpgrade,
    this.onBuyCredits,
    this.onArchiveSets,
    this.onTrimContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    
    return Dialog(
      backgroundColor: tokens.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withValues(alpha:  0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha:  0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Action Blocked',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Block Reason
            if (result.blockReason != null) ...[
              Text(
                result.blockReason!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Suggested Actions
            if (result.suggestedActions.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested Actions:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action Buttons
              ...result.suggestedActions.map((action) => _buildActionButton(
                context,
                action,
              )),
              
              const SizedBox(height: 16),
            ],
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: tokens.surface.withValues(alpha:  0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Close',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String action) {
    final tokens = context.tokens;
    IconData icon;
    Color color;
    VoidCallback? onPressed;
    bool isPrimary = false;

    // Map actions to buttons
    switch (action.toLowerCase()) {
      case 'buy credits':
        icon = Icons.shopping_cart_outlined;
        color = tokens.primary;
        onPressed = onBuyCredits;
        isPrimary = result.showBuyCredits;
        break;
      case 'upgrade':
        icon = Icons.arrow_upward;
        color = MindloadTier.axon.color;
        onPressed = onUpgrade;
        isPrimary = result.showUpgrade;
        break;
      case 'upgrade tier':
        icon = Icons.arrow_upward;
        color = MindloadTier.cortex.color;
        onPressed = onUpgrade;
        isPrimary = result.showUpgrade;
        break;
      case 'archive sets':
      case 'archive/trim/split':
        icon = Icons.archive_outlined;
        color = Colors.orange;
        onPressed = onArchiveSets;
        break;
      case 'split content':
      case 'trim text':
      case 'split pdf':
      case 'extract key pages':
        icon = Icons.content_cut_outlined;
        color = Colors.blue;
        onPressed = onTrimContent;
        break;
      case 'try next cycle':
        icon = Icons.schedule_outlined;
        color = tokens.textSecondary;
        onPressed = () => Navigator.of(context).pop();
        break;
      default:
        icon = Icons.help_outline;
        color = tokens.textSecondary;
        onPressed = () => Navigator.of(context).pop();
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: isPrimary 
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18, color: color),
                label: Text(
                  action,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.centerLeft,
                  backgroundColor: color.withValues(alpha:  0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Credit Status Display Widget
/// Shows current limits and usage
class MindloadCreditStatus extends StatelessWidget {
  final MindloadUserEconomy economy;
  final BudgetState budgetState;

  const MindloadCreditStatus({
    super.key,
    required this.economy,
    required this.budgetState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final outputCounts = {
      'flashcards': economy.getFlashcardsPerCredit(budgetState),
      'quiz': economy.getQuizPerCredit(budgetState),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: economy.tier.color.withValues(alpha:  0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: economy.tier.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  economy.tier.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Text(
                economy.tier.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Credits
          Row(
            children: [
              _buildStatusItem(
                context,
                'Credits',
                '${economy.creditsRemaining}/${economy.monthlyQuota}',
                Icons.flash_on,
                economy.creditsRemaining > 0 ? Colors.green : Colors.red,
                tokens,
              ),
              
              const SizedBox(width: 16),
              
              _buildStatusItem(
                context,
                'Exports',
                '${economy.exportsRemaining}/${economy.monthlyExports}',
                Icons.file_download_outlined,
                economy.exportsRemaining > 0 ? Colors.blue : Colors.red,
                tokens,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Per-Credit Output
          Row(
            children: [
              _buildOutputItem(
                context,
                '${outputCounts['flashcards']} flashcards',
                Icons.style_outlined,
                tokens,
              ),
              
              const SizedBox(width: 4),
              
              Text(
                '+',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              
              const SizedBox(width: 4),
              
              _buildOutputItem(
                context,
                '${outputCounts['quiz']} quiz',
                Icons.quiz_outlined,
                tokens,
              ),
              
              const SizedBox(width: 8),
              
              Text(
                'per credit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
          
          // Budget Warning
          if (budgetState != BudgetState.normal) ...[
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: budgetState == BudgetState.paused 
                    ? Colors.red.withValues(alpha:  0.1)
                    : Colors.orange.withValues(alpha:  0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: budgetState == BudgetState.paused 
                      ? Colors.red.withValues(alpha:  0.3)
                      : Colors.orange.withValues(alpha:  0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    budgetState == BudgetState.paused 
                        ? Icons.pause_circle_outline
                        : Icons.warning_outlined,
                    size: 16,
                    color: budgetState == BudgetState.paused 
                        ? Colors.red
                        : Colors.orange,
                  ),
                  
                  const SizedBox(width: 4),
                  
                  Text(
                    budgetState == BudgetState.paused 
                        ? 'AI Paused'
                        : 'Efficient Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: budgetState == BudgetState.paused 
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    SemanticTokens tokens,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputItem(BuildContext context, String text, IconData icon, SemanticTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tokens.primary),
        const SizedBox(width: 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Helper function to show enforcement dialog
Future<void> showEnforcementDialog(
  BuildContext context,
  EnforcementResult result, {
  VoidCallback? onUpgrade,
  VoidCallback? onBuyCredits,
  VoidCallback? onArchiveSets,
  VoidCallback? onTrimContent,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MindloadEnforcementDialog(
      result: result,
      onUpgrade: onUpgrade,
      onBuyCredits: onBuyCredits,
      onArchiveSets: onArchiveSets,
      onTrimContent: onTrimContent,
    ),
  );
}