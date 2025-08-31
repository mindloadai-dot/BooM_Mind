import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/widgets/achievement_unlock_animation.dart';

/// Enhanced achievement card with modern design patterns
/// Inspired by pub.dev's Flutter Favorites and Material Design 3
class EnhancedAchievementCard extends StatefulWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onTap;

  const EnhancedAchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  State<EnhancedAchievementCard> createState() =>
      _EnhancedAchievementCardState();
}

class _EnhancedAchievementCardState extends State<EnhancedAchievementCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _progressController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _progressAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.achievement.progressPercent / 100.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Start progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedbackService().lightImpact();
    
    // Show unlock animation for earned achievements
    if (widget.achievement.userState.status == AchievementStatus.earned) {
      _showUnlockAnimation();
    }
    
    widget.onTap?.call();
  }

  void _showUnlockAnimation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AchievementUnlockAnimation(
            achievement: widget.achievement,
            onAnimationComplete: () {
              Navigator.of(context).pop();
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _hoverAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovered = true);
              _hoverController.forward();
            },
            onExit: (_) {
              setState(() => _isHovered = false);
              _hoverController.reverse();
            },
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getBorderColor(tokens),
                    width: _isHovered ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getShadowColor(tokens),
                      blurRadius: _isHovered ? 12 : 8,
                      offset: Offset(0, _isHovered ? 6 : 4),
                      spreadRadius: _isHovered ? 1 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background gradient for earned achievements
                      if (widget.achievement.userState.status == AchievementStatus.earned)
                        _buildEarnedBackground(tokens),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(tokens, theme),
                            const SizedBox(height: 16),
                            _buildDescription(tokens, theme),
                            const SizedBox(height: 16),
                            _buildProgressSection(tokens, theme),
                          ],
                        ),
                      ),
                      
                      // Status indicator
                      _buildStatusIndicator(tokens),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarnedBackground(SemanticTokens tokens) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTierColor(tokens).withOpacity(0.05),
            _getTierColor(tokens).withOpacity(0.02),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens, ThemeData theme) {
    return Row(
      children: [
        // Achievement icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getTierColor(tokens).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getTierColor(tokens).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            _getAchievementIcon(),
            size: 30,
            color: _getTierColor(tokens),
          ),
        ),
        const SizedBox(width: 16),
        
        // Achievement info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement name
              Text(
                widget.achievement.catalog.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Tier badge
              _buildTierBadge(tokens),
            ],
          ),
        ),
        
        // Points display
        _buildPointsDisplay(tokens, theme),
      ],
    );
  }

  Widget _buildTierBadge(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTierColor(tokens).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTierColor(tokens).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        widget.achievement.catalog.tier.displayName,
        style: TextStyle(
          color: _getTierColor(tokens),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPointsDisplay(SemanticTokens tokens, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: tokens.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.achievement.catalog.threshold}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(SemanticTokens tokens, ThemeData theme) {
    return Text(
      widget.achievement.catalog.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.textSecondary,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressSection(SemanticTokens tokens, ThemeData theme) {
    final status = widget.achievement.userState.status;
    final progress = widget.achievement.progressPercent;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getProgressText(status),
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (status != AchievementStatus.locked)
              Text(
                '${progress.toInt()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getTierColor(tokens),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        if (status != AchievementStatus.locked)
          _buildProgressBar(tokens),
      ],
    );
  }

  Widget _buildProgressBar(SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: tokens.textMuted.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTierColor(tokens),
                    _getTierColor(tokens).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: _getTierColor(tokens).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(SemanticTokens tokens) {
    final status = widget.achievement.userState.status;
    
    if (status != AchievementStatus.earned) return const SizedBox.shrink();
    
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _getTierColor(tokens),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getTierColor(tokens).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.check,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getTierColor(SemanticTokens tokens) {
    switch (widget.achievement.catalog.tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.legendary:
        return tokens.primary;
    }
  }

  Color _getBorderColor(SemanticTokens tokens) {
    final status = widget.achievement.userState.status;
    
    switch (status) {
      case AchievementStatus.earned:
        return _getTierColor(tokens);
      case AchievementStatus.inProgress:
        return tokens.primary.withOpacity(0.5);
      case AchievementStatus.locked:
        return tokens.textMuted.withOpacity(0.3);
    }
  }

  Color _getShadowColor(SemanticTokens tokens) {
    final status = widget.achievement.userState.status;
    
    switch (status) {
      case AchievementStatus.earned:
        return _getTierColor(tokens).withOpacity(0.2);
      case AchievementStatus.inProgress:
        return tokens.primary.withOpacity(0.1);
      case AchievementStatus.locked:
        return Colors.black.withOpacity(0.05);
    }
  }

  IconData _getAchievementIcon() {
    // Map achievement categories to icons
    switch (widget.achievement.catalog.category) {
      case AchievementCategory.streaks:
        return Icons.local_fire_department;
      case AchievementCategory.studyTime:
        return Icons.access_time;
      case AchievementCategory.cardsCreated:
        return Icons.create;
      case AchievementCategory.cardsReviewed:
        return Icons.quiz;
      case AchievementCategory.quizMastery:
        return Icons.psychology;
      case AchievementCategory.consistency:
        return Icons.trending_up;
      case AchievementCategory.creation:
        return Icons.build;
      case AchievementCategory.ultraExports:
        return Icons.rocket_launch;
    }
  }

  String _getProgressText(AchievementStatus status) {
    switch (status) {
      case AchievementStatus.earned:
        return 'Completed';
      case AchievementStatus.inProgress:
        return 'In Progress';
      case AchievementStatus.locked:
        return 'Locked';
    }
  }
}
