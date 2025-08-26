import 'package:flutter/material.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/widgets/achievement_badge.dart';
import 'package:mindload/theme.dart';

/// Achievement Card Widget - Full card display with badge and details
/// Implements Neon Cortex visual style with accessibility
class AchievementCard extends StatelessWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showDescription;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.showProgress = true,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    
    return Semantics(
      button: onTap != null,
      label: _buildAccessibilityLabel(),
      child: Card(
        color: tokens.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: achievement.isEarned ? tokens.primary.withValues(alpha: 0.8) : tokens.borderDefault.withValues(alpha: 0.3),
            width: achievement.isEarned ? 2.0 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // Subtle glow effect for earned achievements
              boxShadow: achievement.isEarned
                  ? [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.1),
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Achievement badge
                AchievementBadge(
                  achievement: achievement,
                  onTap: onTap,
                  showProgress: showProgress,
                  size: 60.0,
                ),
                
                const SizedBox(width: 16),
                
                // Achievement details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with tier
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.catalog.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: achievement.isEarned ? tokens.textPrimary : tokens.textPrimary.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Tier badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTierColor(tokens, achievement.catalog.tier).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTierColor(tokens, achievement.catalog.tier).withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              achievement.catalog.tier.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getTierColor(tokens, achievement.catalog.tier),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Description
                      if (showDescription)
                        Text(
                          achievement.catalog.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Progress section
                      if (showProgress) _buildProgressSection(context, tokens, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build progress section
  Widget _buildProgressSection(BuildContext context, SemanticTokens tokens, ThemeData theme) {
    if (achievement.isEarned) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: _getIconColor(tokens, achievement),
          ),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: theme.textTheme.labelMedium?.copyWith(
              color: _getIconColor(tokens, achievement),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (achievement.userState.earnedAt != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatEarnedDate(achievement.userState.earnedAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textMuted,
              ),
            ),
          ],
        ],
      );
    }
    
    if (achievement.isInProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.borderDefault.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: achievement.progressPercent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getIconColor(tokens, achievement),
                        borderRadius: BorderRadius.circular(3),
                        // Neon glow effect for progress
                        boxShadow: [
                          BoxShadow(
                            color: _getIconColor(tokens, achievement).withValues(alpha: 0.4),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                achievement.progressText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getIconColor(tokens, achievement),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Remaining progress
          if (achievement.remainingProgress > 0)
            Text(
              '${achievement.remainingProgress} more to unlock',
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textMuted,
              ),
            ),
        ],
      );
    }
    
    // Locked state
    return Row(
      children: [
        Icon(
          Icons.lock_outline,
          size: 16,
          color: _getIconColor(tokens, achievement),
        ),
        const SizedBox(width: 4),
        Text(
          'Locked',
          style: theme.textTheme.labelMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Get tier-specific color using semantic tokens
  Color _getTierColor(SemanticTokens tokens, AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return tokens.success; // Use success color for bronze
      case AchievementTier.silver:
        return tokens.secondary; // Use secondary color for silver
      case AchievementTier.gold:
        return tokens.warning; // Use warning color for gold
      case AchievementTier.platinum:
        return tokens.accent; // Use accent color for platinum
      case AchievementTier.legendary:
        return tokens.primary; // Primary color for legendary
    }
  }

  /// Get icon color based on achievement status and tier
  Color _getIconColor(SemanticTokens tokens, AchievementDisplay achievement) {
    if (achievement.isEarned) {
      return _getTierColor(tokens, achievement.catalog.tier);
    } else if (achievement.isInProgress) {
      return tokens.primary;
    } else {
      return tokens.textEmphasis.withValues(alpha: 0.7); // Better visibility for locked
    }
  }

  /// Static method to get icon color (accessible to other classes)
  static Color getIconColor(SemanticTokens tokens, AchievementDisplay achievement) {
    if (achievement.isEarned) {
      return _getTierColorStatic(tokens, achievement.catalog.tier);
    } else if (achievement.isInProgress) {
      return tokens.primary;
    } else {
      return tokens.textEmphasis.withValues(alpha: 0.2);
    }
  }

  /// Static method to get tier color (accessible to other classes)
  static Color _getTierColorStatic(SemanticTokens tokens, AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return tokens.success; // Use success color for bronze
      case AchievementTier.silver:
        return tokens.secondary; // Use secondary color for silver
      case AchievementTier.gold:
        return tokens.warning; // Use warning color for gold
      case AchievementTier.platinum:
        return tokens.accent; // Use accent color for platinum
      case AchievementTier.legendary:
        return tokens.primary; // Primary color for legendary
    }
  }

  /// Format earned date
  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  /// Build accessibility label
  String _buildAccessibilityLabel() {
    final status = achievement.isEarned
        ? 'Earned'
        : achievement.isInProgress
            ? 'In progress'
            : 'Locked';
    
    final progress = showProgress && achievement.isInProgress
        ? '. Progress: ${achievement.progressText}'
        : '';
    
    final description = showDescription
        ? '. ${achievement.catalog.description}'
        : '';
    
    return '${achievement.catalog.title}. ${achievement.catalog.tier.displayName} tier. $status$progress$description';
  }
}

/// Compact Achievement Card for lists
class AchievementCardCompact extends StatelessWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onTap;

  const AchievementCardCompact({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    
    return Semantics(
      button: onTap != null,
      label: '${achievement.catalog.title}. ${achievement.catalog.tier.displayName} tier. ${achievement.isEarned ? 'Earned' : achievement.isInProgress ? 'In progress' : 'Locked'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tokens.borderDefault.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Compact badge
              AchievementBadge(
                achievement: achievement,
                onTap: onTap,
                showProgress: false,
                size: 32.0,
              ),
              
              const SizedBox(width: 8),
              
              // Title and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.catalog.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: achievement.isEarned ? tokens.textPrimary : tokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (achievement.isInProgress)
                      Text(
                        achievement.progressText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.primary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Status icon
              Icon(
                achievement.isEarned 
                    ? Icons.check_circle 
                    : achievement.isInProgress 
                        ? Icons.radio_button_unchecked 
                        : Icons.lock_outline,
                size: 16,
                color: AchievementCard.getIconColor(tokens, achievement),
              ),
            ],
          ),
        ),
      ),
    );
  }
}