import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'dart:math' as math;

/// Modern achievement unlock animation widget
/// Inspired by pub.dev's Flutter Favorites and trending packages
class AchievementUnlockAnimation extends StatefulWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onAnimationComplete;

  const AchievementUnlockAnimation({
    super.key,
    required this.achievement,
    this.onAnimationComplete,
  });

  @override
  State<AchievementUnlockAnimation> createState() =>
      _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Scale animation - bounce effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Rotation animation - subtle spin
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Slide animation
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeOut,
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Haptic feedback for achievement unlock
    HapticFeedbackService().success();

    // Start main animation
    _mainController.forward();

    // Start particle animation after a delay
    await Future.delayed(const Duration(milliseconds: 300));
    _particleController.forward();

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Complete callback
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: tokens.surface.withOpacity(0.95),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              tokens.primary.withOpacity(0.1),
              tokens.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background particles
            _buildParticleSystem(tokens),
            
            // Main achievement display
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * 0.1, // Subtle rotation
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildAchievementCard(tokens),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: IconButton(
                      onPressed: () {
                        HapticFeedbackService().lightImpact();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.close,
                        color: tokens.textPrimary,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticleSystem(SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            progress: _particleAnimation.value,
            color: tokens.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAchievementCard(SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getTierColor(tokens, widget.achievement.catalog.tier),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getTierColor(tokens, widget.achievement.catalog.tier)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Achievement unlocked text
                Text(
                  'ACHIEVEMENT UNLOCKED!',
                  style: TextStyle(
                    color: _getTierColor(tokens, widget.achievement.catalog.tier),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Achievement icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getTierColor(tokens, widget.achievement.catalog.tier)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getTierColor(tokens, widget.achievement.catalog.tier),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getTierIcon(widget.achievement.catalog.tier),
                    size: 40,
                    color: _getTierColor(tokens, widget.achievement.catalog.tier),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Achievement name
                Text(
                  widget.achievement.catalog.title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Achievement description
                Text(
                  widget.achievement.catalog.description,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getTierColor(tokens, widget.achievement.catalog.tier)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getTierColor(tokens, widget.achievement.catalog.tier),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.achievement.catalog.tier.displayName.toUpperCase(),
                    style: TextStyle(
                      color: _getTierColor(tokens, widget.achievement.catalog.tier),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getTierColor(SemanticTokens tokens, AchievementTier tier) {
    switch (tier) {
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

  IconData _getTierIcon(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Icons.military_tech;
      case AchievementTier.silver:
        return Icons.star;
      case AchievementTier.gold:
        return Icons.emoji_events;
      case AchievementTier.platinum:
        return Icons.diamond;
      case AchievementTier.legendary:
        return Icons.auto_awesome;
    }
  }
}

/// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Particle> particles = [];

  ParticlePainter({required this.progress, required this.color}) {
    // Generate particles if not already generated
    if (particles.isEmpty) {
      for (int i = 0; i < 50; i++) {
        particles.add(Particle());
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = size.width * 0.5 + 
          particle.offsetX * progress * 200 * math.cos(particle.angle);
      final y = size.height * 0.5 + 
          particle.offsetY * progress * 200 * math.sin(particle.angle);
      
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity * particle.opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Particle class for animation effects
class Particle {
  final double offsetX;
  final double offsetY;
  final double size;
  final double angle;
  final double opacity;

  Particle()
      : offsetX = (math.Random().nextDouble() - 0.5) * 2,
        offsetY = (math.Random().nextDouble() - 0.5) * 2,
        size = math.Random().nextDouble() * 4 + 1,
        angle = math.Random().nextDouble() * 2 * math.pi,
        opacity = math.Random().nextDouble() * 0.8 + 0.2;
}
