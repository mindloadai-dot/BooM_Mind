import 'package:flutter/material.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

class AnimatedStudySetCard extends StatefulWidget {
  final StudySet studySet;
  final VoidCallback onTap;
  final Function(String, StudySet) onAction;
  final int index;
  final bool isVisible;

  const AnimatedStudySetCard({
    super.key,
    required this.studySet,
    required this.onTap,
    required this.onAction,
    required this.index,
    this.isVisible = true,
  });

  @override
  State<AnimatedStudySetCard> createState() => _AnimatedStudySetCardState();
}

class _AnimatedStudySetCardState extends State<AnimatedStudySetCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    if (widget.isVisible) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();

    // Start shimmer animation after a delay, but only if widget is still mounted
    Future.delayed(Duration(milliseconds: 200 + (widget.index * 50)), () {
      if (mounted && _shimmerController.isCompleted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedStudySetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedbackService().lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final daysSinceStudied =
        DateTime.now().difference(widget.studySet.lastStudied).inDays;
    final progressPercentage = _calculateProgress();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideAnimation,
        _scaleAnimation,
        _fadeAnimation,
        _shimmerAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildCard(tokens, daysSinceStudied, progressPercentage),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
      SemanticTokens tokens, int daysSinceStudied, double progressPercentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tokens.primary
                      .withValues(alpha: _isHovered ? 0.15 : 0.08),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Main card content
                  _buildCardContent(
                      tokens, daysSinceStudied, progressPercentage),

                  // Shimmer effect
                  if (_isHovered) _buildShimmerEffect(tokens),

                  // Progress indicator
                  _buildProgressIndicator(tokens, progressPercentage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
      SemanticTokens tokens, int daysSinceStudied, double progressPercentage) {
    final themeColor = _getThemeColor(tokens);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.surface,
            tokens.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: themeColor.withValues(alpha: _isHovered ? 0.3 : 0.1),
          width: _isHovered ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(tokens),
            const SizedBox(height: Spacing.md),
            _buildStats(tokens),
            const SizedBox(height: Spacing.md),
            _buildProgressBar(tokens, progressPercentage),
            const SizedBox(height: Spacing.sm),
            _buildFooter(tokens, daysSinceStudied),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    final themeColor = _getThemeColor(tokens);
    
    return Row(
      children: [
        // Study set icon with animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.school,
            color: themeColor,
            size: 20,
          ),
        ),
        const SizedBox(width: Spacing.md),

        // Title
        Expanded(
          child: Text(
            widget.studySet.title.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Menu button
        _buildMenuButton(tokens),
      ],
    );
  }

  Widget _buildMenuButton(SemanticTokens tokens) {
    return PopupMenuButton<String>(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isHovered
              ? tokens.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert,
          color: tokens.textPrimary,
          size: 20,
        ),
      ),
      color: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => widget.onAction(value, widget.studySet),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              Icon(
                widget.studySet.notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: tokens.primary,
                size: 20,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Notifications',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, color: tokens.primary, size: 20),
              const SizedBox(width: Spacing.sm),
              Text(
                'Rename Set',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, color: tokens.primary, size: 20),
              const SizedBox(width: Spacing.sm),
              Text(
                'Refresh Content',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_flashcards',
          child: Row(
            children: [
              Icon(Icons.download, color: tokens.primary, size: 20),
              const SizedBox(width: Spacing.sm),
              Text(
                'Export Flashcards',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_quizzes',
          child: Row(
            children: [
              Icon(Icons.quiz, color: tokens.primary, size: 20),
              const SizedBox(width: Spacing.sm),
              Text(
                'Export Quizzes',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: tokens.error, size: 20),
              const SizedBox(width: Spacing.sm),
              Text(
                'Delete',
                style: TextStyle(color: tokens.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(SemanticTokens tokens) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        _buildStatChip(
          icon: Icons.quiz,
          label: '${widget.studySet.flashcards.length} Cards',
          color: tokens.primary,
        ),
        _buildStatChip(
          icon: Icons.assignment,
          label:
              '${widget.studySet.quizzes.length} Quiz${widget.studySet.quizzes.length != 1 ? 'es' : ''}',
          color: tokens.secondary,
        ),
        if (widget.studySet.notificationsEnabled)
          _buildStatChip(
            icon: Icons.notifications_active,
            label: 'Notifications On',
            color: tokens.secondary,
          ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(SemanticTokens tokens, double progressPercentage) {
    final themeColor = _getThemeColor(tokens);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progressPercentage * 100).round()}%',
              style: TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: tokens.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * progressPercentage,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(SemanticTokens tokens, int daysSinceStudied) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          daysSinceStudied == 0
              ? 'Studied today'
              : daysSinceStudied == 1
                  ? 'Studied yesterday'
                  : 'Studied $daysSinceStudied days ago',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 12,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered
                ? tokens.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: tokens.textSecondary,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerEffect(SemanticTokens tokens) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  _shimmerAnimation.value - 0.3,
                  _shimmerAnimation.value,
                  _shimmerAnimation.value + 0.3,
                ],
                colors: [
                  Colors.transparent,
                  tokens.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(
      SemanticTokens tokens, double progressPercentage) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        height: 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: progressPercentage > 0.7
                ? [tokens.success, tokens.primary]
                : progressPercentage > 0.3
                    ? [tokens.warning, tokens.primary]
                    : [tokens.error, tokens.primary],
          ),
        ),
      ),
    );
  }

  double _calculateProgress() {
    final totalItems =
        widget.studySet.flashcards.length + widget.studySet.quizzes.length;
    if (totalItems == 0) return 0.0;

    // Simple progress calculation based on study frequency
    final daysSinceStudied =
        DateTime.now().difference(widget.studySet.lastStudied).inDays;
    if (daysSinceStudied == 0) return 1.0;
    if (daysSinceStudied <= 3) return 0.8;
    if (daysSinceStudied <= 7) return 0.6;
    if (daysSinceStudied <= 14) return 0.4;
    if (daysSinceStudied <= 30) return 0.2;
    return 0.0;
  }

  /// Get the theme color for this study set based on the selected semantic color
  Color _getThemeColor(SemanticTokens tokens) {
    if (widget.studySet.themeColor == null) {
      return tokens.primary; // Default to primary theme color
    }

    // Map semantic token names to actual colors
    switch (widget.studySet.themeColor) {
      case 'primary':
        return tokens.primary;
      case 'secondary':
        return tokens.secondary;
      case 'accent':
        return tokens.accent;
      case 'success':
        return tokens.success;
      case 'warning':
        return tokens.warning;
      case 'brandTitle':
        return tokens.brandTitle;
      case 'surface':
        return tokens.surface;
      case 'muted':
        return tokens.muted;
      default:
        return tokens.primary; // Fallback to primary
    }
  }
}
