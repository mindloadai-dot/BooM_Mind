import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/accessible_components.dart';

/// Unified Design System for MindLoad
/// This file ensures consistent UI patterns, spacing, typography, and component usage
/// throughout the entire application.

// MARK: - Spacing System
class UnifiedSpacing {
  // Base spacing unit (8px)
  static const double base = 8.0;

  // Spacing scale
  static const double xs = 4.0; // 0.5x base
  static const double sm = 8.0; // 1x base
  static const double md = 16.0; // 2x base
  static const double lg = 24.0; // 3x base
  static const double xl = 32.0; // 4x base
  static const double xxl = 40.0; // 5x base
  static const double xxxl = 48.0; // 6x base

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

// MARK: - Typography System
class UnifiedTypography {
  static TextStyle get displayLarge => const TextStyle(
        fontSize: 57.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.0,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontSize: 36.0,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.0,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.0,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.0,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.0,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.0,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      );
}

// MARK: - Border Radius System
class UnifiedBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(xxl));
}

// MARK: - Unified Card Widget
class UnifiedCard extends StatelessWidget {
  const UnifiedCard({
    super.key,
    required this.child,
    this.padding = UnifiedSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.elevation = 0,
    this.borderRadius = UnifiedBorderRadius.mdRadius,
    this.border,
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? tokens.cardBackground,
          borderRadius: borderRadius,
          border: border ??
              Border.all(
                color: tokens.cardBorder,
                width: 1.5,
              ),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: tokens.shadow,
                    blurRadius: elevation * 2,
                    offset: Offset(0, elevation),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// MARK: - Unified Button Widget
class UnifiedButton extends StatelessWidget {
  const UnifiedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.semanticLabel,
    this.tooltip,
    this.icon,
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.disabled = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final String? semanticLabel;
  final String? tooltip;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !disabled && !loading;

    // Use the existing MindloadButton for consistency
    return MindloadButton(
      onPressed: isEnabled ? onPressed : null,
      variant: variant,
      size: size,
      fullWidth: fullWidth,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      disabled: disabled,
      child: child,
    );
  }
}

// MARK: - Unified Text Widget
class UnifiedText extends StatelessWidget {
  const UnifiedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Text(
        text,
        style: style?.copyWith(color: style?.color ?? tokens.textPrimary) ??
            UnifiedTypography.bodyMedium.copyWith(color: tokens.textPrimary),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

// MARK: - Unified Icon Widget
class UnifiedIcon extends StatelessWidget {
  const UnifiedIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        size: size,
        color: color ?? tokens.navIcon,
      ),
    );
  }
}

// MARK: - Unified Chip Widget
class UnifiedChip extends StatelessWidget {
  const UnifiedChip({
    super.key,
    required this.label,
    this.icon,
    this.onDeleted,
    this.semanticLabel,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onDeleted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: UnifiedSpacing.sm, vertical: UnifiedSpacing.xs),
        decoration: BoxDecoration(
          color: tokens.chipBackground,
          borderRadius: UnifiedBorderRadius.smRadius,
          border: Border.all(color: tokens.chipBackground),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: UnifiedSpacing.xs),
            ],
            UnifiedText(
              label,
              style:
                  UnifiedTypography.labelSmall.copyWith(color: tokens.chipText),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: UnifiedSpacing.xs),
              GestureDetector(
                onTap: onDeleted,
                child: UnifiedIcon(
                  Icons.close,
                  size: 16,
                  color: tokens.chipText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MARK: - Unified Divider Widget
class UnifiedDivider extends StatelessWidget {
  const UnifiedDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  final double height;
  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: tokens.dividerColor,
    );
  }
}

// MARK: - Unified Loading Widget
class UnifiedLoading extends StatelessWidget {
  const UnifiedLoading({
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticLabel = 'Loading',
  });

  final double size;
  final Color? color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? tokens.primary),
        ),
      ),
    );
  }
}

// MARK: - Unified Empty State Widget
class UnifiedEmptyState extends StatelessWidget {
  const UnifiedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Center(
        child: Padding(
          padding: UnifiedSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UnifiedIcon(
                icon,
                size: 64,
                color: tokens.textSecondary,
              ),
              const SizedBox(height: UnifiedSpacing.lg),
              UnifiedText(
                title,
                style: UnifiedTypography.headlineSmall
                    .copyWith(color: tokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: UnifiedSpacing.sm),
                UnifiedText(
                  subtitle!,
                  style: UnifiedTypography.bodyMedium
                      .copyWith(color: tokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: UnifiedSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Unified Error State Widget
class UnifiedErrorState extends StatelessWidget {
  const UnifiedErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.semanticLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label: semanticLabel,
      child: Center(
        child: Padding(
          padding: UnifiedSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UnifiedIcon(
                Icons.error_outline,
                size: 64,
                color: tokens.error,
              ),
              const SizedBox(height: UnifiedSpacing.lg),
              UnifiedText(
                'Something went wrong',
                style: UnifiedTypography.headlineSmall
                    .copyWith(color: tokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UnifiedSpacing.sm),
              UnifiedText(
                message,
                style: UnifiedTypography.bodyMedium
                    .copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: UnifiedSpacing.xl),
                UnifiedButton(
                  onPressed: onRetry,
                  variant: ButtonVariant.outline,
                  child: const UnifiedText('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Extension Methods for Easy Access
extension UnifiedDesignContext on BuildContext {
  /// Get unified spacing values
  UnifiedSpacing get spacing => UnifiedSpacing();

  /// Get unified typography styles
  UnifiedTypography get typography => UnifiedTypography();

  /// Get unified border radius values
  UnifiedBorderRadius get borderRadius => UnifiedBorderRadius();
}
