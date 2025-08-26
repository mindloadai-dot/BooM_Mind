import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/widgets/achievement_badge.dart';
import 'package:mindload/theme.dart';

/// Achievement Celebration Widget
/// Shows micro-confetti, haptic feedback, and snackbar
class AchievementCelebration {
  /// Show achievement earned celebration
  static void showEarned(BuildContext context, AchievementDisplay achievement) {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show snackbar celebration
    _showCelebrationSnackbar(context, achievement, false);
  }
  
  /// Show bonus credit celebration
  static void showBonusCredit(BuildContext context, AchievementDisplay achievement) {
    // Stronger haptic feedback for bonus
    HapticFeedback.heavyImpact();
    
    // Show bonus snackbar
    _showCelebrationSnackbar(context, achievement, true);
  }

  /// Show celebration snackbar with animation
  static void _showCelebrationSnackbar(BuildContext context, AchievementDisplay achievement, bool isBonus) {
    final tokens = context.tokens;
    
    final message = isBonus
        ? 'Bonus +1 Credit! (every ${AchievementConstants.rewardEveryN} achievements)'
        : 'Unlocked ${achievement.catalog.title}! Progress +1 toward a bonus credit.';
    
    final snackBar = SnackBar(
      content: _CelebrationSnackbarContent(
        achievement: achievement,
        message: message,
        isBonus: isBonus,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 150,
        left: 16,
        right: 16,
      ),
    );
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Celebration Snackbar Content with animations
class _CelebrationSnackbarContent extends StatefulWidget {
  final AchievementDisplay achievement;
  final String message;
  final bool isBonus;

  const _CelebrationSnackbarContent({
    required this.achievement,
    required this.message,
    required this.isBonus,
  });

  @override
  State<_CelebrationSnackbarContent> createState() => _CelebrationSnackbarContentState();
}

class _CelebrationSnackbarContentState extends State<_CelebrationSnackbarContent>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _confettiController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Confetti animation (brief)
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _slideController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Confetti particles (respects reduced motion)
        if (MediaQuery.of(context).accessibleNavigation == false)
          ..._buildConfettiParticles(tokens),
        
        // Main content
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isBonus 
                    ? tokens.primary.withValues(alpha: 0.95)
                    : tokens.bg.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isBonus 
                      ? tokens.primary
                      : tokens.borderDefault,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isBonus ? tokens.primary : tokens.primary).withValues(alpha: 0.3),
                    blurRadius: 16.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Achievement badge (small)
                  AchievementBadge(
                    achievement: widget.achievement,
                    size: 40.0,
                    showProgress: false,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Message content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: widget.isBonus 
                                ? tokens.textInverse
                                : tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        if (!widget.isBonus) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.achievement.catalog.title,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: tokens.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Icon
                  Icon(
                    widget.isBonus ? Icons.star : Icons.emoji_events,
                    color: widget.isBonus 
                        ? tokens.textInverse
                        : tokens.achieveNeon,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build confetti particles
  List<Widget> _buildConfettiParticles(SemanticTokens tokens) {
    final particles = <Widget>[];
    
    // Create 8 confetti particles
    for (int i = 0; i < 8; i++) {
      particles.add(
        Positioned(
          left: 20.0 + (i * 25.0),
          top: -10.0,
          child: AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              final progress = _confettiController.value;
              final delay = i * 0.1;
              final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(
                  0,
                  adjustedProgress * 60 + (adjustedProgress * adjustedProgress * 20), // Gravity effect
                ),
                child: Transform.rotate(
                  angle: adjustedProgress * 6.28 * 2, // 2 full rotations
                  child: Opacity(
                    opacity: (1.0 - adjustedProgress).clamp(0.0, 1.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getConfettiColor(tokens, i),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return particles;
  }

  /// Get confetti particle color using semantic tokens
  Color _getConfettiColor(SemanticTokens tokens, int index) {
    final colors = [
      tokens.primary,
      tokens.accent,
      tokens.success,
      tokens.warning,
      tokens.secondary,
    ];
    
    return colors[index % colors.length];
  }
}

/// Reduced motion alternative
class _ReducedMotionCelebration extends StatelessWidget {
  final AchievementDisplay achievement;
  final String message;
  final bool isBonus;

  const _ReducedMotionCelebration({
    required this.achievement,
    required this.message,
    required this.isBonus,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBonus 
            ? tokens.primary.withValues(alpha: 0.9)
            : tokens.bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBonus ? tokens.primary : tokens.borderDefault,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          // Achievement badge
          AchievementBadge(
            achievement: achievement,
            size: 40.0,
            showProgress: false,
          ),
          
          const SizedBox(width: 12),
          
          // Message
          Expanded(
                          child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isBonus ? tokens.textInverse : tokens.textEmphasis,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ),
          
          // Icon
          Icon(
            isBonus ? Icons.star : Icons.emoji_events,
            color: isBonus ? tokens.textInverse : tokens.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}