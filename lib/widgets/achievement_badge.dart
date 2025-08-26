import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mindload/models/achievement_models.dart';
import 'package:mindload/theme.dart';

/// Achievement Badge Widget - Neuron nodes with synapse arcs
/// Implements Neon Cortex visual style with accessibility
class AchievementBadge extends StatelessWidget {
  final AchievementDisplay achievement;
  final VoidCallback? onTap;
  final bool showProgress;
  final double size;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
    this.showProgress = true,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    
    // Tier-specific styling
    final tierColor = _getTierColor(tokens, achievement.catalog.tier);
    final isEarned = achievement.isEarned;
    final progressPercent = achievement.progressPercent;
    
    return Semantics(
      button: true,
      label: _buildAccessibilityLabel(),
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // Soft layered background
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                tokens.bg,
                tokens.elevatedSurface,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isEarned ? tierColor : tokens.borderDefault.withValues(alpha: 0.3),
              width: 3.0,
            ),
            // Neuron node shadow effect
            boxShadow: isEarned
                ? [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.3),
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Background grid pattern (subtle brainwave)
              if (isEarned) _buildBrainwaveGrid(tokens),
              
              // Progress ring
              if (showProgress && !isEarned) _buildProgressRing(tokens, progressPercent),
              
              // Main content (tier chip only, no central icon to avoid overlap)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: size * 0.06),

                    // Tier indicator chip (single-line, no wrap)
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: size * 0.78,
                        minHeight: size * 0.22,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: isEarned ? 0.9 : 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            achievement.catalog.tier.displayName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textInverse,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: size * 0.14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Info button removed - achievements are now completely automatic
            ],
          ),
        ),
      ),
    );
  }

  /// Build brainwave grid pattern for earned achievements
  Widget _buildBrainwaveGrid(SemanticTokens tokens) {
    return CustomPaint(
      size: Size(size, size),
              painter: BrainwaveGridPainter(tokens.borderDefault.withValues(alpha: 0.2)),
    );
  }

  /// Build progress ring for in-progress achievements
  Widget _buildProgressRing(SemanticTokens tokens, double progress) {
    return CustomPaint(
      size: Size(size, size),
      painter: ProgressRingPainter(
        progress: progress,
                          color: tokens.primary,
                  backgroundColor: tokens.primary.withValues(alpha: 0.2),
      ),
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

  /// Map achievement category to a clear Material icon for visibility
  IconData _getBadgeIcon(AchievementDisplay achievement) {
    switch (achievement.catalog.category) {
      case AchievementCategory.streaks:
        return Icons.local_fire_department;
      case AchievementCategory.studyTime:
        return Icons.timer_outlined;
      case AchievementCategory.cardsCreated:
      case AchievementCategory.creation:
        return Icons.draw_rounded;
      case AchievementCategory.cardsReviewed:
        return Icons.fact_check_outlined;
      case AchievementCategory.quizMastery:
        return Icons.military_tech_outlined;
      case AchievementCategory.consistency:
        return Icons.track_changes_outlined;
      case AchievementCategory.ultraExports:
        return Icons.rocket_launch_outlined;
    }
  }

  /// Build accessibility label
  String _buildAccessibilityLabel() {
    final status = achievement.isEarned
        ? 'Earned'
        : achievement.isInProgress
            ? 'In progress'
            : 'Locked';
    
    final progress = showProgress && !achievement.isEarned
        ? '. Progress: ${achievement.progressText}'
        : '';
    
    return '${achievement.catalog.title}. ${achievement.catalog.tier.displayName} tier. $status$progress';
  }
}

/// Custom painter for brainwave grid pattern
class BrainwaveGridPainter extends CustomPainter {
  final Color color;

  BrainwaveGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw concentric circles (neuron connections)
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), paint);
    }

    // Draw radial lines (synapse arcs)
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180);
      final start = Offset(
        center.dx + (radius * 0.3) * math.cos(angle),
        center.dy + (radius * 0.3) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(BrainwaveGridPainter oldDelegate) => color != oldDelegate.color;
}

/// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final strokeWidth = 3.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

// Math import moved to top of file