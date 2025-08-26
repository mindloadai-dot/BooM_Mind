import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/widgets/achievement_badge.dart';
import 'package:mindload/theme.dart';

/// Achievement Explainer Sheet - Modal bottom sheet with achievement details
/// What it is • How to earn • Your progress • Reward
class AchievementExplainerSheet extends StatelessWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onActionTap;

  const AchievementExplainerSheet({
    super.key,
    required this.achievement,
    this.onActionTap,
  });

  /// Show the explainer sheet with error handling
  static Future<void> show(
    BuildContext context, 
    AchievementDisplay achievement, {
    VoidCallback? onActionTap,
  }) {
    // Show the sheet even with minimal data to provide feedback
    try {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) => AchievementExplainerSheet(
          achievement: achievement,
          onActionTap: onActionTap,
        ),
      );
    } catch (error) {
      // Fallback error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to show achievement details: ${error.toString()}',
            style: TextStyle(color: context.tokens.textInverse),
          ),
          backgroundColor: context.tokens.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return Future.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Calculate sheet height (max 80% of screen)
    final maxHeight = mediaQuery.size.height * 0.8;
    
    // Provide fallback data if necessary
    String title = achievement.catalog.title;
    String description = achievement.catalog.description;
    String howTo = achievement.catalog.howTo;
    
    // Use fallbacks for missing data rather than showing error
    if (title.isEmpty) title = 'Achievement';
    if (description.isEmpty) description = 'This achievement tracks your progress in the app.';
    if (howTo.isEmpty) howTo = 'Continue using the app to make progress on this achievement.';
    
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Achievement details for $title',
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: tokens.bg, // match app background
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: tokens.borderDefault.withValues(alpha: 0.3),
              width: 1.0,
            ),
            // Neon glow for earned achievements
            boxShadow: achievement.isEarned
                ? [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha: 0.25),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      // Header with badge
                      _buildHeader(context, tokens, theme, title),
                      
                      const SizedBox(height: 32),
                      
                      // Sections
                      _buildSection('What it is', description, tokens, theme),
                      _buildHowToSection(howTo, tokens, theme),
                      _buildProgressSection(tokens, theme),
                      _buildRewardSection(tokens, theme),
                      
                      const SizedBox(height: 24),
                      
                      // Auto-tracking notice instead of action button
                      _buildAutoTrackingNotice(context, tokens, theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with achievement badge and title
  Widget _buildHeader(BuildContext context, SemanticTokens tokens, ThemeData theme, String title) {
    return Column(
      children: [
        // Large achievement badge
        AchievementBadge(
          achievement: achievement,
          size: 120.0,
          showProgress: true,
        ),
        
        const SizedBox(height: 16),
        
        // Title and tier
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Tier badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getTierColor(tokens, achievement.catalog.tier).withValues(alpha:  0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getTierColor(tokens, achievement.catalog.tier).withValues(alpha:  0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            '${achievement.catalog.tier.displayName} Tier',
            style: theme.textTheme.labelMedium?.copyWith(
              color: _getTierColor(tokens, achievement.catalog.tier),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Build a section with title and content
  Widget _buildSection(String title, String content, SemanticTokens tokens, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with neon accent
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha:  0.4),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Section content
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a richer How-To section with step bullets and tips (semantic tokens only)
  Widget _buildHowToSection(String howTo, SemanticTokens tokens, ThemeData theme) {
    final lines = howTo.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha: 0.4),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How to earn',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textEmphasis,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderDefault.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: tokens.badgeRing, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textEmphasis,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (lines.isEmpty)
                  Text(
                    howTo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textEmphasis,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: tokens.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Achievements track automatically while you study, create, and practice.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress section
  Widget _buildProgressSection(SemanticTokens tokens, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha:  0.4),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textEmphasis,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress content
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: _buildProgressContent(tokens, theme),
          ),
        ],
      ),
    );
  }

  /// Build progress content based on achievement status
  Widget _buildProgressContent(SemanticTokens tokens, ThemeData theme) {
    if (achievement.isEarned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: tokens.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievement completed!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (achievement.userState.earnedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Earned ${_formatEarnedDate(achievement.userState.earnedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
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
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha:  0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: achievement.progressPercent,
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha:  0.4),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress text
          Text(
            '${achievement.userState.progress} of ${achievement.catalog.threshold} completed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textEmphasis,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${achievement.remainingProgress} more to unlock',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textMuted,
            ),
          ),
        ],
      );
    }
    
    // Locked state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: tokens.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Not started yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Start the related activity and progress will be tracked automatically',
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textMuted,
          ),
        ),
      ],
    );
  }

  /// Build reward section
  Widget _buildRewardSection(SemanticTokens tokens, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha:  0.4),
                      blurRadius: 4.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Reward',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textEmphasis,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Reward content
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.borderDefault.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Progress +1 toward bonus credit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textEmphasis,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every ${AchievementConstants.rewardEveryN} achievements earned grants +1 free credit automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build auto-tracking notice
  Widget _buildAutoTrackingNotice(BuildContext context, SemanticTokens tokens, ThemeData theme) {
    String message;
    IconData icon;
    
    if (achievement.isEarned) {
      message = '🎉 Achievement earned! Your progress was tracked automatically.';
      icon = Icons.celebration;
    } else if (achievement.isInProgress) {
      message = '📈 Your progress is being tracked automatically as you use the app.';
      icon = Icons.trending_up;
    } else {
      message = '🤖 This achievement will be tracked automatically when you start the related activity.';
      icon = Icons.auto_mode;
    }
    
    return Semantics(
      label: 'Auto-Tracking status',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.borderDefault.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: tokens.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    achievement.isEarned ? 'Automatically Earned' : 'Auto-Tracking Active',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
            if (!achievement.isEarned) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Go to ${_getActivityName(achievement.catalog.category)}',
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                      if (onActionTap != null) {
                        onActionTap!.call();
                      } else {
                        _navigateToCategory(context, achievement.catalog.category);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Go to ${_getActivityName(achievement.catalog.category)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, AchievementCategory category) {
    String route;
    switch (category) {
      case AchievementCategory.streaks:
      case AchievementCategory.studyTime:
      case AchievementCategory.consistency:
      case AchievementCategory.cardsReviewed:
      case AchievementCategory.quizMastery:
        route = '/study';
        break;
      case AchievementCategory.cardsCreated:
      case AchievementCategory.creation:
        route = '/create';
        break;
      case AchievementCategory.ultraExports:
        route = '/ultra';
        break;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  /// Get activity name for navigation
  String _getActivityName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streaks:
      case AchievementCategory.studyTime:
        return 'Study';
      case AchievementCategory.cardsCreated:
      case AchievementCategory.creation:
        return 'Create';
      case AchievementCategory.cardsReviewed:
      case AchievementCategory.quizMastery:
        return 'Practice';
      case AchievementCategory.ultraExports:
        return 'Ultra Mode';
      case AchievementCategory.consistency:
        return 'Study';
    }
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
        return tokens.primary; // Use primary color for legendary
    }
  }

  /// Format earned date
  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
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
  
  /// Build error sheet when achievement data is invalid
  Widget _buildErrorSheet(BuildContext context, SemanticTokens tokens, ThemeData theme, String errorMessage) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.6,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: tokens.error.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Error content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: tokens.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to Load Achievement',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: tokens.textEmphasis,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: tokens.textInverse,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}