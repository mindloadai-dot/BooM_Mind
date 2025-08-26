import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';

/// Enhanced design system for Mindload app
/// Provides improved visual hierarchy, spacing, and user experience
/// while maintaining the app's sci-fi aesthetic

/// Enhanced spacing system with better visual rhythm
class EnhancedSpacing {
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 40.0; // 5x
  static const double xxxl = 48.0; // 6x
  static const double hero = 64.0; // 8x - for hero sections
  static const double section = 80.0; // 10x - for major sections
}

/// Enhanced card variants for different content types
enum CardVariant {
  default_, // Standard content
  premium, // Premium features
  success, // Success states
  warning, // Warning states
  error, // Error states
  featured, // Featured content
  interactive, // Interactive elements
}

/// Enhanced card with improved visual design
class EnhancedCard extends StatefulWidget {
  const EnhancedCard({
    super.key,
    required this.child,
    this.variant = CardVariant.default_,
    this.isInteractive = false,
    this.onTap,
    this.padding = const EdgeInsets.all(EnhancedSpacing.md),
    this.margin = const EdgeInsets.all(EnhancedSpacing.sm),
    this.elevation = 2.0,
    this.selected = false,
    this.semanticLabel,
    this.heroTag,
    this.animate = true,
  });

  final Widget child;
  final CardVariant variant;
  final bool isInteractive;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double elevation;
  final bool selected;
  final String? semanticLabel;
  final Object? heroTag;
  final bool animate;

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (widget.isInteractive && widget.animate) {
      setState(() => _isHovered = isHovered);
      if (isHovered) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    // Define card styling based on variant
    final cardStyle = _getCardStyle(tokens);

    Widget card = Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: cardStyle.backgroundColor,
              elevation: _elevationAnimation.value,
              shadowColor: cardStyle.shadowColor,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: widget.onTap != null
                    ? () {
                        HapticFeedback.selectionClick();
                        widget.onTap!();
                      }
                    : null,
                onHover: widget.isInteractive ? _onHover : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cardStyle.borderColor,
                      width: cardStyle.borderWidth,
                    ),
                    gradient: cardStyle.gradient,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );

    // Add hero animation if specified
    if (widget.heroTag != null) {
      card = Hero(
        tag: widget.heroTag!,
        child: card,
      );
    }

    // Add semantic label if provided
    if (widget.semanticLabel != null) {
      card = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        selected: widget.selected,
        child: card,
      );
    }

    return card;
  }

  _CardStyle _getCardStyle(SemanticTokens tokens) {
    switch (widget.variant) {
      case CardVariant.default_:
        return _CardStyle(
          backgroundColor: tokens.elevatedSurface,
          borderColor: tokens.borderDefault,
          borderWidth: 1.5,
          shadowColor: tokens.overlayDim,
          gradient: null,
        );
      case CardVariant.premium:
        return _CardStyle(
          backgroundColor: tokens.primary.withValues(alpha: 0.1),
          borderColor: tokens.primary,
          borderWidth: 2.0,
          shadowColor: tokens.primary.withValues(alpha: 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.primary.withValues(alpha: 0.05),
              tokens.primary.withValues(alpha: 0.1),
            ],
          ),
        );
      case CardVariant.success:
        return _CardStyle(
          backgroundColor: tokens.success.withValues(alpha: 0.1),
          borderColor: tokens.success,
          borderWidth: 2.0,
          shadowColor: tokens.success.withValues(alpha: 0.3),
          gradient: null,
        );
      case CardVariant.warning:
        return _CardStyle(
          backgroundColor: tokens.warning.withValues(alpha: 0.1),
          borderColor: tokens.warning,
          borderWidth: 2.0,
          shadowColor: tokens.warning.withValues(alpha: 0.3),
          gradient: null,
        );
      case CardVariant.error:
        return _CardStyle(
          backgroundColor: tokens.error.withValues(alpha: 0.1),
          borderColor: tokens.error,
          borderWidth: 2.0,
          shadowColor: tokens.error.withValues(alpha: 0.3),
          gradient: null,
        );
      case CardVariant.featured:
        return _CardStyle(
          backgroundColor: tokens.secondary.withValues(alpha: 0.1),
          borderColor: tokens.secondary,
          borderWidth: 2.0,
          shadowColor: tokens.secondary.withValues(alpha: 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.secondary.withValues(alpha: 0.05),
              tokens.secondary.withValues(alpha: 0.15),
            ],
          ),
        );
      case CardVariant.interactive:
        return _CardStyle(
          backgroundColor: _isHovered
              ? tokens.primary.withValues(alpha: 0.15)
              : tokens.elevatedSurface,
          borderColor: _isHovered ? tokens.primary : tokens.borderDefault,
          borderWidth: _isHovered ? 2.0 : 1.5,
          shadowColor: tokens.overlayDim,
          gradient: null,
        );
    }
  }
}

class _CardStyle {
  const _CardStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.shadowColor,
    this.gradient,
  });

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color shadowColor;
  final Gradient? gradient;
}

/// Enhanced skeleton loading component
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({
    super.key,
    this.height = 120.0,
    this.width = double.infinity,
    this.borderRadius = 16.0,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: tokens.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value, 0),
                  colors: [
                    Colors.transparent,
                    tokens.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Enhanced progress indicator with animations
class EnhancedProgressIndicator extends StatefulWidget {
  const EnhancedProgressIndicator({
    super.key,
    required this.value,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius = 4.0,
    this.animate = true,
    this.showPercentage = false,
  });

  final double value; // 0.0 to 1.0
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final double borderRadius;
  final bool animate;
  final bool showPercentage;

  @override
  State<EnhancedProgressIndicator> createState() =>
      _EnhancedProgressIndicatorState();
}

class _EnhancedProgressIndicatorState extends State<EnhancedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _animationController.forward();
    } else {
      _progressAnimation = AlwaysStoppedAnimation(widget.value);
    }
  }

  @override
  void didUpdateWidget(EnhancedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.animate) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    tokens.muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.progressColor ?? tokens.primary,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showPercentage) ...[
          const SizedBox(height: EnhancedSpacing.xs),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Enhanced section header with better typography
class EnhancedSectionHeader extends StatelessWidget {
  const EnhancedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.variant = CardVariant.default_,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final CardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Container(
      padding: const EdgeInsets.all(EnhancedSpacing.md),
      decoration: BoxDecoration(
        color: _getHeaderColor(tokens),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getHeaderBorderColor(tokens),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: _getHeaderIconColor(tokens),
              size: 24,
            ),
            const SizedBox(width: EnhancedSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _getHeaderTextColor(tokens),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: EnhancedSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getHeaderSubtitleColor(tokens),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: EnhancedSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }

  Color _getHeaderColor(SemanticTokens tokens) {
    switch (variant) {
      case CardVariant.premium:
        return tokens.primary.withValues(alpha: 0.05);
      case CardVariant.success:
        return tokens.success.withValues(alpha: 0.05);
      case CardVariant.warning:
        return tokens.warning.withValues(alpha: 0.05);
      case CardVariant.error:
        return tokens.error.withValues(alpha: 0.05);
      case CardVariant.featured:
        return tokens.secondary.withValues(alpha: 0.05);
      default:
        return tokens.surface;
    }
  }

  Color _getHeaderBorderColor(SemanticTokens tokens) {
    switch (variant) {
      case CardVariant.premium:
        return tokens.primary.withValues(alpha: 0.3);
      case CardVariant.success:
        return tokens.success.withValues(alpha: 0.3);
      case CardVariant.warning:
        return tokens.warning.withValues(alpha: 0.3);
      case CardVariant.error:
        return tokens.error.withValues(alpha: 0.3);
      case CardVariant.featured:
        return tokens.secondary.withValues(alpha: 0.3);
      default:
        return tokens.borderDefault.withValues(alpha: 0.3);
    }
  }

  Color _getHeaderIconColor(SemanticTokens tokens) {
    switch (variant) {
      case CardVariant.premium:
        return tokens.primary;
      case CardVariant.success:
        return tokens.success;
      case CardVariant.warning:
        return tokens.warning;
      case CardVariant.error:
        return tokens.error;
      case CardVariant.featured:
        return tokens.secondary;
      default:
        return tokens.textSecondary;
    }
  }

  Color _getHeaderTextColor(SemanticTokens tokens) {
    switch (variant) {
      case CardVariant.premium:
        return tokens.primary;
      case CardVariant.success:
        return tokens.success;
      case CardVariant.warning:
        return tokens.warning;
      case CardVariant.error:
        return tokens.error;
      case CardVariant.featured:
        return tokens.secondary;
      default:
        return tokens.textPrimary;
    }
  }

  Color _getHeaderSubtitleColor(SemanticTokens tokens) {
    return tokens.textSecondary;
  }
}

/// Enhanced empty state component
class EnhancedEmptyState extends StatelessWidget {
  const EnhancedEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Container(
      padding: const EdgeInsets.all(EnhancedSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (illustration != null) ...[
            illustration!,
            const SizedBox(height: EnhancedSpacing.lg),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 64,
              color: tokens.textTertiary,
            ),
            const SizedBox(height: EnhancedSpacing.lg),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: EnhancedSpacing.md),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: EnhancedSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
