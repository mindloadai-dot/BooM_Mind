import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/utils/accessibility_detector.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

/// Comprehensive set of accessible components that enforce WCAG 2.1 AA standards
/// and support RTL, Dynamic Type, and international conventions

/// 8-point grid spacing system
class Spacing {
  static const double xs = 4.0; // 0.5x
  static const double sm = 8.0; // 1x
  static const double md = 16.0; // 2x
  static const double lg = 24.0; // 3x
  static const double xl = 32.0; // 4x
  static const double xxl = 40.0; // 5x
  static const double xxxl = 48.0; // 6x
}

/// Minimum hit target sizes per platform guidelines
class HitTargets {
  static const double iOS = 44.0; // 44×44 pt iOS minimum
  static const double android = 48.0; // 48×48 dp Android minimum
  static const double touch = 48.0; // Touch padding minimum
}

/// Layout safety helper for runtime checks
class LayoutSafety {
  static void checkSafeArea(BuildContext context, String screenName) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return;

      final safeArea = mediaQuery.padding;

      if (safeArea.top > 0 || safeArea.bottom > 0) {
        // Check if content might be overlapping
        TelemetryService.instance.logEvent(
          TelemetryEvent.safeAreaViolationDetected.name,
          {
            'screen': screenName,
            'top_inset': safeArea.top,
            'bottom_inset': safeArea.bottom,
          },
        );
      }
    } catch (e) {
      developer.log('Error in checkSafeArea: $e', name: 'LayoutSafety');
    }
  }

  static void checkFontScaling(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) return;

      final textScaleFactor = mediaQuery.textScaler.scale(1.0);

      if (textScaleFactor > 1.2) {
        TelemetryService.instance.logEvent(
          TelemetryEvent.fontScale120Used.name,
          {'scale_factor': textScaleFactor},
        );
      }
    } catch (e) {
      developer.log('Error in checkFontScaling: $e', name: 'LayoutSafety');
    }
  }

  static void checkRTL(BuildContext context) {
    try {
      final isRTL = Directionality.of(context) == TextDirection.rtl;

      if (isRTL) {
        final locale = Localizations.maybeLocaleOf(context);
        TelemetryService.instance.logEvent(
          TelemetryEvent.rtlEnabled.name,
          {'locale': locale?.languageCode ?? 'unknown'},
        );
      }
    } catch (e) {
      developer.log('Error in checkRTL: $e', name: 'LayoutSafety');
    }
  }
}

/// Modern button system with consistent semantic theming
/// Replaces direct ElevatedButton/OutlinedButton/TextButton usage
class MindloadButton extends StatelessWidget {
  const MindloadButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.rounded = false,
    this.elevation = 0,
    this.borderRadius = 8.0,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;
  final IconData? icon;
  final IconPosition iconPosition;
  final bool loading;
  final bool rounded;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final isEnabled = onPressed != null && !disabled && !loading;

    // Define size properties
    final sizeConfig = switch (size) {
      ButtonSize.small => _ButtonSizeConfig(
          minHeight: HitTargets.iOS,
          minWidth: HitTargets.iOS,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: Theme.of(context).textTheme.labelMedium,
          iconSize: 16,
        ),
      ButtonSize.medium => _ButtonSizeConfig(
          minHeight: HitTargets.touch,
          minWidth: HitTargets.touch,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: Theme.of(context).textTheme.labelLarge,
          iconSize: 18,
        ),
      ButtonSize.large => _ButtonSizeConfig(
          minHeight: 56.0,
          minWidth: HitTargets.touch,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: Theme.of(context).textTheme.labelLarge,
          iconSize: 20,
        ),
    };

    // Define colors based on variant
    final colorConfig = switch (variant) {
      ButtonVariant.primary => _ButtonColorConfig(
          backgroundColor: isEnabled ? tokens.primary : tokens.muted,
          foregroundColor: isEnabled ? tokens.onPrimary : tokens.textTertiary,
          borderColor: isEnabled ? tokens.primary : tokens.outline,
          hoverColor: tokens.primary.withValues(alpha: 0.9),
          pressedColor: tokens.primary.withValues(alpha: 0.8),
        ),
      ButtonVariant.secondary => _ButtonColorConfig(
          backgroundColor: isEnabled ? tokens.secondary : tokens.muted,
          foregroundColor: isEnabled ? tokens.onSecondary : tokens.textTertiary,
          borderColor: isEnabled ? tokens.secondary : tokens.outline,
          hoverColor: tokens.secondary.withValues(alpha: 0.9),
          pressedColor: tokens.secondary.withValues(alpha: 0.8),
        ),
      ButtonVariant.outline => _ButtonColorConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: isEnabled ? tokens.textPrimary : tokens.textTertiary,
          borderColor: isEnabled
              ? tokens.outline
              : tokens.outline.withValues(alpha: 0.5),
          hoverColor: tokens.surface.withValues(alpha: 0.1),
          pressedColor: tokens.surface.withValues(alpha: 0.2),
        ),
      ButtonVariant.text => _ButtonColorConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: isEnabled ? tokens.primary : tokens.textTertiary,
          borderColor: Colors.transparent,
          hoverColor: tokens.primary.withValues(alpha: 0.1),
          pressedColor: tokens.primary.withValues(alpha: 0.2),
        ),
      ButtonVariant.success => _ButtonColorConfig(
          backgroundColor: isEnabled ? tokens.success : tokens.muted,
          foregroundColor: isEnabled ? tokens.onPrimary : tokens.textTertiary,
          borderColor: isEnabled ? tokens.success : tokens.outline,
          hoverColor: tokens.success.withValues(alpha: 0.9),
          pressedColor: tokens.success.withValues(alpha: 0.8),
        ),
      ButtonVariant.error => _ButtonColorConfig(
          backgroundColor: isEnabled ? tokens.error : tokens.muted,
          foregroundColor: isEnabled ? tokens.onPrimary : tokens.textTertiary,
          borderColor: isEnabled ? tokens.error : tokens.outline,
          hoverColor: tokens.error.withValues(alpha: 0.9),
          pressedColor: tokens.error.withValues(alpha: 0.8),
        ),
      ButtonVariant.warning => _ButtonColorConfig(
          backgroundColor: isEnabled ? tokens.warning : tokens.muted,
          foregroundColor: isEnabled ? tokens.onPrimary : tokens.textTertiary,
          borderColor: isEnabled ? tokens.warning : tokens.outline,
          hoverColor: tokens.warning.withValues(alpha: 0.9),
          pressedColor: tokens.warning.withValues(alpha: 0.8),
        ),
    };

    // Validate contrast
    if (isEnabled) {
      AccessibilityDetector.validateTextContrast(
        textColor: colorConfig.foregroundColor,
        backgroundColor: colorConfig.backgroundColor,
        fontSize: sizeConfig.textStyle?.fontSize ?? 16,
      );
    }

    // Build button content
    Widget buttonContent = _buildButtonContent(sizeConfig, colorConfig);

    // Apply Material design
    Widget button = Material(
      color: colorConfig.backgroundColor,
      elevation: elevation,
      shadowColor: colorConfig.borderColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            rounded ? sizeConfig.minHeight / 2 : borderRadius),
        side: BorderSide(
          color: colorConfig.borderColor,
          width: variant == ButtonVariant.outline ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(
            rounded ? sizeConfig.minHeight / 2 : borderRadius),
        child: Container(
          constraints: BoxConstraints(
            minHeight: sizeConfig.minHeight,
            minWidth: fullWidth ? double.infinity : sizeConfig.minWidth,
          ),
          padding: sizeConfig.padding,
          child: buttonContent,
        ),
      ),
    );

    // Add focus support for keyboard navigation
    button = Focus(
      child: button,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          // Visual focus indicator handled by InkWell
        }
      },
    );

    // Add semantic label and tooltip if provided
    if (semanticLabel != null || tooltip != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: isEnabled,
        child: tooltip != null
            ? Tooltip(
                message: tooltip!,
                child: button,
              )
            : button,
      );
    }

    return button;
  }

  Widget _buildButtonContent(
      _ButtonSizeConfig sizeConfig, _ButtonColorConfig colorConfig) {
    if (loading) {
      return SizedBox(
        width: sizeConfig.iconSize,
        height: sizeConfig.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor:
              AlwaysStoppedAnimation<Color>(colorConfig.foregroundColor),
        ),
      );
    }

    if (icon != null) {
      final iconWidget = Icon(
        icon,
        size: sizeConfig.iconSize,
        color: colorConfig.foregroundColor,
      );

      if (iconPosition == IconPosition.start) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            DefaultTextStyle(
              style: sizeConfig.textStyle?.copyWith(
                    color: colorConfig.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(color: colorConfig.foregroundColor),
              child: child,
            ),
          ],
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle(
              style: sizeConfig.textStyle?.copyWith(
                    color: colorConfig.foregroundColor,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(color: colorConfig.foregroundColor),
              child: child,
            ),
            const SizedBox(width: 8),
            iconWidget,
          ],
        );
      }
    }

    return DefaultTextStyle(
      style: sizeConfig.textStyle?.copyWith(
            color: colorConfig.foregroundColor,
            fontWeight: FontWeight.w600,
          ) ??
          TextStyle(color: colorConfig.foregroundColor),
      child: Center(child: child),
    );
  }
}

/// Legacy AccessibleButton for backward compatibility
/// @deprecated Use MindloadButton instead
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: variant,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      child: child,
    );
  }
}

/// Specialized button for destructive actions
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.error,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      loading: loading,
      child: child,
    );
  }
}

/// Specialized button for success/confirmation actions
class SuccessButton extends StatelessWidget {
  const SuccessButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.success,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      loading: loading,
      child: child,
    );
  }
}

/// Specialized button for secondary actions
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      loading: loading,
      child: child,
    );
  }
}

/// Specialized button for text-only actions
class MindloadTextButton extends StatelessWidget {
  const MindloadTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool fullWidth;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.text,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      loading: loading,
      child: child,
    );
  }
}

/// Specialized button for icon-only actions
class MindloadIconButton extends StatelessWidget {
  const MindloadIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.variant = ButtonVariant.outline,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final ButtonVariant variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: variant,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      loading: loading,
      child: const SizedBox.shrink(),
    );
  }
}

/// Button variants for different use cases
enum ButtonVariant {
  primary, // Main actions
  secondary, // Secondary actions
  outline, // Bordered actions
  text, // Text-only actions
  success, // Success/confirmation actions
  error, // Destructive actions
  warning // Warning actions
}

/// Button sizes for different contexts
enum ButtonSize {
  small, // Compact (44x44 iOS, 48x48 Android)
  medium, // Standard (48x48)
  large // Prominent (56x height)
}

/// Icon positioning within buttons
enum IconPosition {
  start, // Icon before text
  end // Icon after text
}

class _ButtonSizeConfig {
  const _ButtonSizeConfig({
    required this.minHeight,
    required this.minWidth,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
  });

  final double minHeight;
  final double minWidth;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final double iconSize;
}

class _ButtonColorConfig {
  const _ButtonColorConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.hoverColor,
    required this.pressedColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color hoverColor;
  final Color pressedColor;
}

/// Accessible text input with proper focus rings and error handling
class AccessibleTextInput extends StatefulWidget {
  const AccessibleTextInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final String? semanticLabel;

  @override
  State<AccessibleTextInput> createState() => _AccessibleTextInputState();
}

class _AccessibleTextInputState extends State<AccessibleTextInput> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final hasError = widget.errorText != null;

    // Validate contrast for helper and error text
    if (widget.helperText != null) {
      AccessibilityDetector.validateTextContrast(
        textColor: tokens.textSecondary,
        backgroundColor: tokens.bg,
        fontSize: 12.0,
      );
    }

    if (widget.errorText != null) {
      AccessibilityDetector.validateTextContrast(
        textColor: tokens.error,
        backgroundColor: tokens.bg,
        fontSize: 12.0,
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? widget.labelText,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null) ...[
            Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: hasError ? tokens.error : tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: Spacing.xs),
          ],
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasError
                    ? tokens.error
                    : _hasFocus
                        ? tokens.primary
                        : tokens.outline,
                width: _hasFocus ? 2.0 : 1.5,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              validator: widget.validator,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: widget.enabled
                        ? tokens.textPrimary
                        : tokens.textTertiary,
                  ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: widget.enabled
                    ? tokens.surface
                    : tokens.muted.withValues(alpha: 0.1),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: tokens.textTertiary,
                    ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
            ),
          ),
          if (widget.helperText != null || widget.errorText != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              widget.errorText ?? widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasError ? tokens.error : tokens.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Accessible card with proper elevation and content spacing
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.margin = const EdgeInsets.all(Spacing.sm),
    this.elevation = 2.0,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double elevation;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    Widget card = Container(
      margin: margin,
      child: Material(
        color: selected
            ? tokens.primary.withValues(alpha: 0.1)
            : tokens.elevatedSurface,
        elevation: elevation,
        shadowColor: tokens.overlayDim,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? tokens.primary
                    : tokens.outline.withValues(alpha: 0.2),
                width: selected ? 2.0 : 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        selected: selected,
        child: card,
      );
    }

    return card;
  }
}

/// Accessible list tile with proper selection indicators
class AccessibleListTile extends StatelessWidget {
  const AccessibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      enabled: enabled,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? tokens.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && onTap != null
                ? () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: HitTargets.touch),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        color: enabled
                            ? (selected ? tokens.primary : tokens.textSecondary)
                            : tokens.textTertiary,
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: Spacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          DefaultTextStyle(
                            style: theme.textTheme.bodyLarge?.copyWith(
                                  color: enabled
                                      ? tokens.textPrimary
                                      : tokens.textTertiary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ) ??
                                const TextStyle(),
                            child: title!,
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          DefaultTextStyle(
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: enabled
                                      ? tokens.textSecondary
                                      : tokens.textTertiary,
                                ) ??
                                const TextStyle(),
                            child: subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: Spacing.md),
                    // Show selection indicator when selected (not color-only)
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        color: tokens.primary,
                        size: 20,
                        semanticLabel: 'Selected',
                      )
                    else
                      IconTheme(
                        data: IconThemeData(
                          color: enabled
                              ? tokens.textSecondary
                              : tokens.textTertiary,
                        ),
                        child: trailing!,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Safe area wrapper that respects system UI overlaps
class SafeAreaWrapper extends StatelessWidget {
  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.screenName,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final String? screenName;

  @override
  Widget build(BuildContext context) {
    // Perform safety checks with error handling
    if (screenName != null) {
      try {
        LayoutSafety.checkSafeArea(context, screenName!);
        LayoutSafety.checkFontScaling(context);
        LayoutSafety.checkRTL(context);
      } catch (e) {
        developer.log('Error in SafeAreaWrapper safety checks: $e',
            name: 'SafeAreaWrapper');
      }
    }

    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );
  }
}

/// Scrollable content wrapper that handles keyboard insets
class KeyboardAwareScrollView extends StatelessWidget {
  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final Widget child;
  final EdgeInsets padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          final mediaQuery = MediaQuery.maybeOf(context);
          if (mediaQuery == null) {
            developer.log(
                'MediaQuery not found, using fallback SingleChildScrollView',
                name: 'KeyboardAwareScrollView');
            return SingleChildScrollView(
              physics: physics,
              padding: padding,
              child: child,
            );
          }

          final keyboardHeight = mediaQuery.viewInsets.bottom;

          if (keyboardHeight > 0) {
            // Log keyboard interaction with error handling
            try {
              TelemetryService.instance.logEvent(
                TelemetryEvent.keyboardInteractionDetected.name,
                {'keyboard_height': keyboardHeight},
              );
            } catch (e) {
              developer.log('Error logging keyboard event: $e',
                  name: 'KeyboardAwareScrollView');
            }
          }

          // Ensure minHeight is never negative to prevent layout crashes
          final minHeight =
              math.max(0.0, constraints.maxHeight - keyboardHeight);

          return SingleChildScrollView(
            physics: physics,
            padding: padding.add(EdgeInsets.only(bottom: keyboardHeight)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight,
              ),
              child: child,
            ),
          );
        } catch (e) {
          developer.log('Error in KeyboardAwareScrollView: $e',
              name: 'KeyboardAwareScrollView');
          // Fallback to simple SingleChildScrollView if anything fails
          return SingleChildScrollView(
            physics: physics,
            padding: padding,
            child: child,
          );
        }
      },
    );
  }
}

/// Enhanced chip with proper hit targets and accessibility
class AccessibleChip extends StatelessWidget {
  const AccessibleChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.avatar,
    this.deleteIcon,
    this.onDeleted,
    this.semanticLabel,
  });

  final Widget label;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final Widget? avatar;
  final Widget? deleteIcon;
  final VoidCallback? onDeleted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected
            ? tokens.primary.withValues(alpha: 0.2)
            : tokens.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (avatar != null) ...[
                  avatar!,
                  const SizedBox(width: 4),
                ],
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? (selected
                                    ? tokens.primary
                                    : tokens.textPrimary)
                                : tokens.textTertiary,
                            fontWeight: FontWeight.w500,
                          ) ??
                      const TextStyle(),
                  child: label,
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: enabled ? onDeleted : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: deleteIcon ??
                            Icon(
                              Icons.close,
                              size: 16,
                              color: enabled
                                  ? tokens.textSecondary
                                  : tokens.textTertiary,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessibility helper for runtime diagnostics
class AccessibilityDiagnostics extends StatelessWidget {
  const AccessibilityDiagnostics({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ThemeManager.instance.isDiagnosticsModeEnabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeManager.instance.currentTokens.overlayDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Theme: ${ThemeManager.instance.getThemeDisplayName(ThemeManager.instance.currentTheme)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'Font Scale: ${MediaQuery.of(context).textScaler.scale(1.0).toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'RTL: ${Directionality.of(context) == TextDirection.rtl}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'Fallback: ${ThemeManager.instance.isInFallbackMode}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Inspector overlay for theme diagnostics during development
class ThemeInspectorOverlay extends StatelessWidget {
  const ThemeInspectorOverlay({
    super.key,
    required this.child,
    this.showInspector = false,
  });

  final Widget child;
  final bool showInspector;

  @override
  Widget build(BuildContext context) {
    if (!showInspector) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Material(
            color: ThemeManager.instance.currentTokens.overlayDim,
            borderRadius: BorderRadius.circular(8),
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Theme Diagnostics',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _DiagnosticRow(
                      'Theme',
                      ThemeManager.instance.getThemeDisplayName(
                          ThemeManager.instance.currentTheme)),
                  _DiagnosticRow('Font Scale',
                      '${MediaQuery.of(context).textScaler.scale(16).toStringAsFixed(1)}x'),
                  _DiagnosticRow(
                      'RTL',
                      Directionality.of(context) == TextDirection.rtl
                          ? 'Yes'
                          : 'No'),
                  _DiagnosticRow('High Contrast',
                      MediaQuery.highContrastOf(context) ? 'Yes' : 'No'),
                  _DiagnosticRow('Bold Text',
                      MediaQuery.boldTextOf(context) ? 'Yes' : 'No'),
                  _DiagnosticRow('Reduce Motion',
                      MediaQuery.disableAnimationsOf(context) ? 'Yes' : 'No'),
                  if (ThemeManager.instance.isInFallbackMode)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FALLBACK MODE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Toggle button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: Material(
            color: ThemeManager.instance.currentTokens.primary,
            borderRadius: BorderRadius.circular(8),
            elevation: 4,
            child: InkWell(
              onTap: () => ThemeManager.instance.toggleDiagnosticsMode(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.bug_report,
                  size: 20,
                  color: ThemeManager.instance.currentTokens.onPrimary,
                  semanticLabel: 'Toggle theme diagnostics',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
