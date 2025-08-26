import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/screens/paywall_screen.dart';

class CreditPill extends StatefulWidget {
  const CreditPill({super.key});

  @override
  State<CreditPill> createState() => _CreditPillState();
}

class _CreditPillState extends State<CreditPill> {
  void _showUsageDetails() {
    showDialog(
      context: context,
      builder: (context) => const _UsageDetailsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final userEconomy = economyService.userEconomy;
        if (userEconomy == null) {
          return const SizedBox.shrink();
        }
        
        final creditsRemaining = userEconomy.creditsRemaining;
        final isUnlimited = userEconomy.tier == MindloadTier.singularity;
        
        final isLowCredits = !isUnlimited && creditsRemaining <= 5;
        final isOutOfCredits = !isUnlimited && creditsRemaining == 0;
    
        return InkWell(
          onTap: _showUsageDetails,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOutOfCredits 
                ? Theme.of(context).colorScheme.errorContainer
                : isLowCredits
                  ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.7)
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOutOfCredits 
                  ? Theme.of(context).colorScheme.error
                  : isLowCredits
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flash_on, // Use lightning bolt consistently
                  size: 16,
                  color: isOutOfCredits 
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : isLowCredits
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  isUnlimited ? '∞' : creditsRemaining.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isOutOfCredits 
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : isLowCredits
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: isUnlimited ? 18 : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsageDetailsDialog extends StatelessWidget {
  const _UsageDetailsDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final userEconomy = economyService.userEconomy;
        if (userEconomy == null) {
          return const SizedBox.shrink();
        }
        
        final tier = userEconomy.tier;
        final creditsRemaining = userEconomy.creditsRemaining;
        final monthlyQuota = userEconomy.monthlyQuota;
        final isUnlimited = tier == MindloadTier.singularity;
        
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Usage Details',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Plan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_membership, color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${tier.name.toUpperCase()} Plan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // System Status
              if (economyService.budgetState != BudgetState.normal) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: economyService.budgetState == BudgetState.paused 
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        economyService.budgetState == BudgetState.paused ? Icons.pause_circle : Icons.warning,
                        color: economyService.budgetState == BudgetState.paused ? Colors.red : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          economyService.budgetState == BudgetState.paused 
                            ? 'System paused due to high demand'
                            : 'System in savings mode',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: economyService.budgetState == BudgetState.paused ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Credit System Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Study Set Credits',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUnlimited
                        ? 'Unlimited quiz and flashcard generation'
                        : 'Remaining: $creditsRemaining/$monthlyQuota credits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isUnlimited) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: monthlyQuota > 0 
                          ? (monthlyQuota - creditsRemaining) / monthlyQuota 
                          : 0.0,
                        backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          creditsRemaining <= 5 ? Colors.orange : Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Binaural Beats (Always Unlimited)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Binaural Beats - Unlimited',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Current Month Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Used: ${userEconomy.creditsUsedThisMonth} credits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (userEconomy.rolloverCredits > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rollover: ${userEconomy.rolloverCredits} credits',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                isUnlimited
                  ? 'Singularity plan: Unlimited credits every month'
                  : 'Credits refill on ${_formatDate(userEconomy.nextResetDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            if (!isUnlimited)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PaywallScreen(trigger: 'credit_pill'),
                    fullscreenDialog: true,
                  ));
                },
                child: Text(
                  'UPGRADE',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsageRow(BuildContext context, String label, int used, int limit, IconData icon) {
    final percentage = limit > 0 ? used / limit : 0.0;
    
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '$used/$limit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              used >= limit ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month;
    final day = date.day;
    final year = date.year;
    
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${monthNames[month - 1]} $day, $year';
  }

  String _formatTimeUntilReset(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}