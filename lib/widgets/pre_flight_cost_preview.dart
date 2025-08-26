import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';

/// Pre-Flight Cost Preview - Shows cost before generation
/// 
/// Features:
/// - Compact cost bar showing credits needed and current balance
/// - Handles paste content that exceeds caps with split/trim/upgrade options
/// - Blocks generation if insufficient credits with buy credits CTA
/// - Provides clear upgrade paths for better tiers
class PreFlightCostPreview extends StatelessWidget {
  final int sourceCharCount;
  final int? pdfPageCount;
  final bool isRecreate;
  final bool lastAttemptFailed;
  final VoidCallback? onTrimContent;
  final VoidCallback? onAutoSplit;
  final VoidCallback? onBuyCredits;
  final VoidCallback? onUpgrade;
  final VoidCallback? onGenerate;

  const PreFlightCostPreview({
    super.key,
    required this.sourceCharCount,
    this.pdfPageCount,
    this.isRecreate = false,
    this.lastAttemptFailed = false,
    this.onTrimContent,
    this.onAutoSplit,
    this.onBuyCredits,
    this.onUpgrade,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        if (!economy.isInitialized) {
          return _buildLoadingSkeleton(tokens);
        }

        final request = GenerationRequest(
          sourceContent: 'dummy', // Not used for validation
          sourceCharCount: sourceCharCount,
          pdfPageCount: pdfPageCount,
          isRecreate: isRecreate,
          lastAttemptFailed: lastAttemptFailed,
        );

        final enforcement = economy.canGenerateContent(request);
        final creditsNeeded = isRecreate && lastAttemptFailed ? 0 : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact cost bar
            _buildCostBar(context, economy, creditsNeeded, tokens),

            // Error/warning states
            if (!enforcement.canProceed) ...[
              const SizedBox(height: 12),
              _buildEnforcementMessage(context, enforcement, tokens),
            ],

            // Action buttons based on state
            if (!enforcement.canProceed && enforcement.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildActionButtons(context, enforcement, tokens),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCostBar(BuildContext context, MindloadEconomyService economy, int creditsNeeded, SemanticTokens tokens) {
    final isRetry = isRecreate && lastAttemptFailed;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Cost icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isRetry ? tokens.success.withValues(alpha:  0.1) : tokens.primary.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isRetry ? Icons.replay : Icons.flash_on,
              size: 18,
              color: isRetry ? tokens.success : tokens.primary,
            ),
          ),

          const SizedBox(width: 12),

          // Cost text
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
                children: [
                  if (isRetry)
                    TextSpan(
                      text: 'Free retry • ',
                      style: TextStyle(
                        color: tokens.success,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    const TextSpan(text: 'This will use '),
                    TextSpan(
                      text: '$creditsNeeded ML Token${creditsNeeded == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' • '),
                  ],
                  const TextSpan(text: 'Balance: '),
                  TextSpan(
                    text: '${economy.creditsRemaining}',
                    style: TextStyle(
                      color: economy.hasCredits ? tokens.textPrimary : tokens.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Generate button (when can proceed)
          if (economy.canGenerate && 
              (isRetry || economy.creditsRemaining >= creditsNeeded))
            ElevatedButton(
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Generate'),
            ),
        ],
      ),
    );
  }

  Widget _buildEnforcementMessage(BuildContext context, EnforcementResult enforcement, SemanticTokens tokens) {
    Color bgColor;
    Color textColor;
    IconData icon;

    // Determine severity and styling
    if (enforcement.blockReason?.contains('credits') ?? false) {
      bgColor = tokens.error.withValues(alpha:  0.1);
      textColor = tokens.error;
      icon = Icons.account_balance_wallet_outlined;
    } else if ((enforcement.blockReason?.contains('too long') ?? false) ||
               (enforcement.blockReason?.contains('too large') ?? false)) {
      bgColor = tokens.warning.withValues(alpha:  0.1);
      textColor = tokens.warning;
      icon = Icons.content_cut;
    } else {
      bgColor = tokens.error.withValues(alpha:  0.1);
      textColor = tokens.error;
      icon = Icons.block;
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enforcement.blockReason ?? 'Cannot proceed',
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

  Widget _buildActionButtons(BuildContext context, EnforcementResult enforcement, SemanticTokens tokens) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: enforcement.suggestedActions.map((action) {
        return _buildActionButton(context, action, enforcement, tokens);
      }).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, String action, EnforcementResult enforcement, SemanticTokens tokens) {
    VoidCallback? onPressed;
    bool isPrimary = false;
    IconData? icon;

    switch (action.toLowerCase()) {
      case 'split content':
      case 'auto-split (uses k credits)':
        onPressed = onAutoSplit;
        icon = Icons.content_cut;
        break;
      case 'trim text':
      case 'trim':
        onPressed = onTrimContent;
        icon = Icons.content_cut;
        break;
      case 'upgrade tier':
      case 'upgrade':
        onPressed = onUpgrade;
        icon = Icons.arrow_upward;
        break;
      case 'split pdf':
      case 'extract key pages':
        // PDF-specific actions - can be handled by onTrimContent
        onPressed = onTrimContent;
        icon = Icons.picture_as_pdf;
        break;
      case 'archive sets':
        // This would need to be handled by parent
        icon = Icons.archive;
        break;
    }

    // Buy Credits is always primary when present
    if (enforcement.showBuyCredits && (action.toLowerCase().contains('buy') || action.toLowerCase().contains('add'))) {
      onPressed = onBuyCredits;
      isPrimary = true;
      icon = Icons.add_circle;
    }

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : null,
        label: Text(_formatActionLabel(action)),
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : null,
      label: Text(_formatActionLabel(action)),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        side: BorderSide(
          color: tokens.borderDefault,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha:  0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha:  0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.textTertiary.withValues(alpha:  0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: tokens.textTertiary.withValues(alpha:  0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionLabel(String action) {
    // Clean up action labels for display
    switch (action.toLowerCase()) {
      case 'split content':
        return 'Split Content';
      case 'trim text':
      case 'trim':
        return 'Trim Text';
      case 'upgrade tier':
      case 'upgrade':
        return 'Upgrade';
      case 'split pdf':
        return 'Split PDF';
      case 'extract key pages':
        return 'Extract Pages';
      case 'archive sets':
        return 'Archive Sets';
      default:
        return action;
    }
  }
}

/// Specific widget for paste content that exceeds character limits
class PasteExceedsCap extends StatelessWidget {
  final int currentCharCount;
  final int charLimit;
  final int creditsForSplit;
  final VoidCallback? onTrim;
  final VoidCallback? onAutoSplit;
  final VoidCallback? onUpgrade;
  final VoidCallback? onBuyCredits;

  const PasteExceedsCap({
    super.key,
    required this.currentCharCount,
    required this.charLimit,
    required this.creditsForSplit,
    this.onTrim,
    this.onAutoSplit,
    this.onUpgrade,
    this.onBuyCredits,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final excessChars = currentCharCount - charLimit;
    final approximateWords = (excessChars / 6).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.warning.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.warning.withValues(alpha:  0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning header
          Row(
            children: [
              Icon(
                Icons.content_cut,
                size: 20,
                color: tokens.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Content too long',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Details
          Text(
            'Your content has ${_formatNumber(currentCharCount)} characters (~${_formatNumber((currentCharCount / 6).ceil())} words). '
            'The limit is ${_formatNumber(charLimit)} characters (~${_formatNumber((charLimit / 6).ceil())} words).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Trim option
              OutlinedButton.icon(
                onPressed: onTrim,
                icon: const Icon(Icons.content_cut, size: 16),
                label: const Text('Trim Text'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textPrimary,
                  side: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
              ),

              // Auto-split option
              OutlinedButton.icon(
                onPressed: onAutoSplit,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: Text('Auto-Split ($creditsForSplit credits)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.textPrimary,
                  side: BorderSide(
                    color: tokens.borderDefault,
                    width: 1.5,
                  ),
                ),
              ),

              // Upgrade option
              ElevatedButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Upgrade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: tokens.onPrimary,
                ),
              ),

              // Buy Credits option (if auto-split selected)
              if (creditsForSplit > 0)
                ElevatedButton.icon(
                  onPressed: onBuyCredits,
                  icon: const Icon(Icons.add_circle, size: 16),
                  label: const Text('Buy Credits'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.onAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}