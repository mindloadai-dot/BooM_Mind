import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';

/// ML Tokens Feedback Snackbar - Post-action feedback with token deduction info
/// 
/// Features:
/// - Shows tokens used and remaining balance
/// - Quick actions: Add Brainpower / View Ledger
/// - Success/failure states with appropriate styling
/// - Handles free retries and zero-output auto-retries
class CreditsFeedbackSnackbar {
  static void showSuccess({
    required BuildContext context,
    required int creditsUsed,
    required int creditsRemaining,
    VoidCallback? onAddBrainpower,
    VoidCallback? onViewLedger,
    bool isRetry = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SuccessSnackbarContent(
          creditsUsed: creditsUsed,
          creditsRemaining: creditsRemaining,
          onAddBrainpower: onAddBrainpower,
          onViewLedger: onViewLedger,
          isRetry: isRetry,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showFailure({
    required BuildContext context,
    required String errorMessage,
    VoidCallback? onRetry,
    VoidCallback? onAddBrainpower,
    bool canRetryFree = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _FailureSnackbarContent(
          errorMessage: errorMessage,
          onRetry: onRetry,
          onAddBrainpower: onAddBrainpower,
          canRetryFree: canRetryFree,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showAutoRetry({
    required BuildContext context,
    required String reason,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _AutoRetrySnackbarContent(reason: reason),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showLowCredits({
    required BuildContext context,
    required int creditsRemaining,
    required int warnThreshold,
    VoidCallback? onAddBrainpower,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _LowCreditsSnackbarContent(
          creditsRemaining: creditsRemaining,
          onAddBrainpower: onAddBrainpower,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SuccessSnackbarContent extends StatelessWidget {
  final int creditsUsed;
  final int creditsRemaining;
  final VoidCallback? onAddBrainpower;
  final VoidCallback? onViewLedger;
  final bool isRetry;

  const _SuccessSnackbarContent({
    required this.creditsUsed,
    required this.creditsRemaining,
    this.onAddBrainpower,
    this.onViewLedger,
    this.isRetry = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.success.withValues(alpha:  0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success message
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha:  0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: tokens.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Generated! ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isRetry && creditsUsed == 0)
                        TextSpan(
                          text: 'Free retry • ',
                          style: TextStyle(
                            color: tokens.success,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (creditsUsed > 0) ...[
                        TextSpan(
                          text: '−$creditsUsed ML Token${creditsUsed == 1 ? '' : 's'} • ',
                          style: TextStyle(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                      TextSpan(
                        text: '$creditsRemaining ML Tokens left',
                        style: TextStyle(
                          color: creditsRemaining > 0 ? tokens.textPrimary : tokens.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action buttons
          if (onAddBrainpower != null || onViewLedger != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onViewLedger != null)
                  TextButton(
                    onPressed: onViewLedger,
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('View Ledger'),
                  ),
                if (onAddBrainpower != null) ...[
                  if (onViewLedger != null) const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAddBrainpower,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Add Brainpower'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FailureSnackbarContent extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onAddBrainpower;
  final bool canRetryFree;

  const _FailureSnackbarContent({
    required this.errorMessage,
    this.onRetry,
    this.onAddBrainpower,
    this.canRetryFree = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.error.withValues(alpha:  0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.error.withValues(alpha:  0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.error,
                  size: 16,
                  color: tokens.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generation failed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    if (canRetryFree) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next retry is free',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Action buttons
          if (onRetry != null || onAddBrainpower != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRetry != null)
                  OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.textPrimary,
                      side: BorderSide(
                        color: tokens.borderDefault,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(canRetryFree ? 'Retry (Free)' : 'Retry'),
                  ),
                if (onAddBrainpower != null) ...[
                  if (onRetry != null) const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAddBrainpower,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Add Brainpower'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoRetrySnackbarContent extends StatelessWidget {
  final String reason;

  const _AutoRetrySnackbarContent({required this.reason});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.primary.withValues(alpha:  0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.refresh,
              size: 16,
              color: tokens.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-retrying...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowCreditsSnackbarContent extends StatelessWidget {
  final int creditsRemaining;
  final VoidCallback? onAddBrainpower;

  const _LowCreditsSnackbarContent({
    required this.creditsRemaining,
    this.onAddBrainpower,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.warning.withValues(alpha:  0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha:  0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: tokens.warning.withValues(alpha:  0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: tokens.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Low on ML Tokens ($creditsRemaining remaining)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onAddBrainpower != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onAddBrainpower,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Add Brainpower'),
            ),
          ],
        ],
      ),
    );
  }
}