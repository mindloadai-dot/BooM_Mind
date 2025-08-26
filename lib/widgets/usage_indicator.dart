import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/theme.dart';

class UsageIndicator extends StatelessWidget {
  final String type; // 'quiz', 'flashcard', or 'upload'
  final bool showLabel;

  const UsageIndicator({
    super.key,
    required this.type,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final userEconomy = economyService.userEconomy;
        if (userEconomy == null) {
          return const SizedBox.shrink(); // User not initialized
        }
        
        int remaining;
        int total;
        String label;
        IconData icon;
        Color color;
        bool canGenerate;

        switch (type) {
          case 'quiz':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            label = 'Quiz Questions';
            icon = Icons.quiz;
            color = context.tokens.primary;
            canGenerate = economyService.canGenerate;
            break;
          case 'flashcard':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            label = 'Flashcards';
            icon = Icons.style;
            color = context.tokens.success;
            canGenerate = economyService.canGenerate;
            break;
          case 'upload':
            remaining = userEconomy.creditsRemaining;
            total = userEconomy.monthlyQuota;
            label = 'Uploads';
            icon = Icons.upload;
            color = context.tokens.warning;
            canGenerate = economyService.canGenerate;
            break;
          default:
            return const SizedBox.shrink();
        }

        final isAtLimit = remaining <= 0;
        final isLow = remaining <= (total * 0.2);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 8,
            vertical: showLabel ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: isAtLimit 
              ? context.tokens.error.withValues(alpha: 0.1)
              : isLow
                ? context.tokens.warning.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(showLabel ? 12 : 20),
            border: Border.all(
              color: isAtLimit 
                ? context.tokens.error.withValues(alpha: 0.3)
                : isLow
                  ? context.tokens.warning.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAtLimit ? Icons.block : icon,
                size: showLabel ? 16 : 14,
                color: isAtLimit 
                  ? context.tokens.error
                  : isLow
                    ? context.tokens.warning
                    : color,
              ),
              const SizedBox(width: 6),
              Text(
                '$remaining',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isAtLimit 
                    ? context.tokens.error
                    : isLow
                      ? context.tokens.warning
                      : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  '/$total',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class GeneratorBlockedOverlay extends StatelessWidget {
  final String type;
  final VoidCallback? onUpgrade;

  const GeneratorBlockedOverlay({
    super.key,
    required this.type,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final userEconomy = economyService.userEconomy;
        if (userEconomy == null) {
          return const SizedBox.shrink(); // User not initialized
        }
        
        bool shouldBlock = false;
        String message = '';
        Color overlayColor = context.tokens.muted;
        IconData icon = Icons.block;

        if (!economyService.canGenerate) {
          shouldBlock = true;
          message = 'No credits remaining.\nResets monthly.';
          overlayColor = context.tokens.error;
          icon = Icons.block;
        } else if (userEconomy.tier == MindloadTier.free && type == 'upload') {
          shouldBlock = true;
          message = 'Uploads not available on free tier.\nUpgrade to upload documents.';
          overlayColor = context.tokens.warning;
          icon = Icons.lock;
        }

        if (!shouldBlock) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: overlayColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: context.tokens.textInverse, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.tokens.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onUpgrade != null && userEconomy.tier == MindloadTier.free) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.tokens.textInverse,
                      foregroundColor: overlayColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'UPGRADE PLAN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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