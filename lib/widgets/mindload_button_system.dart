import 'package:flutter/material.dart';
import 'package:mindload/widgets/accessible_components.dart';

/// Comprehensive button system for Mindload app
/// Provides consistent, semantic, and accessible buttons throughout the app
///
/// Usage examples:
/// ```dart
/// // Primary action button
/// MindloadButton.primary(
///   onPressed: () => print('Primary action'),
///   child: Text('Primary Action'),
/// )
///
/// // Secondary button with icon
/// MindloadButton.secondary(
///   onPressed: () => print('Secondary action'),
///   icon: Icons.info,
///   child: Text('Learn More'),
/// )
///
/// // Destructive action
/// MindloadButton.destructive(
///   onPressed: () => print('Delete'),
///   child: Text('Delete'),
/// )
///
/// // Loading state
/// MindloadButton.primary(
///   onPressed: null,
///   loading: true,
///   child: Text('Processing...'),
/// )
/// ```

/// Primary action button - main actions in the app
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.fullWidth = false,
    this.icon,
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.rounded = false,
    this.elevation = 2,
  });

  final VoidCallback? onPressed;
  final Widget child;
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

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}

/// Secondary action button - alternative actions
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
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.rounded = false,
    this.elevation = 0,
  });

  final VoidCallback? onPressed;
  final Widget child;
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
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}

/// Success button - confirmation actions
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
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.rounded = false,
    this.elevation = 1,
  });

  final VoidCallback? onPressed;
  final Widget child;
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
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}

/// Destructive button - dangerous actions
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
    this.iconPosition = IconPosition.start,
    this.loading = false,
    this.rounded = false,
    this.elevation = 0,
  });

  final VoidCallback? onPressed;
  final Widget child;
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
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}

/// Warning button - caution actions
class WarningButton extends StatelessWidget {
  const WarningButton({
    super.key,
    required this.onPressed,
    required this.child,
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
  });

  final VoidCallback? onPressed;
  final Widget child;
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

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.warning,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}

/// Text button - minimal emphasis actions
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
    this.iconPosition = IconPosition.start,
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
  final IconPosition iconPosition;
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
      iconPosition: iconPosition,
      loading: loading,
      child: child,
    );
  }
}

/// Icon-only button for compact actions
class IconOnlyButton extends StatelessWidget {
  const IconOnlyButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = ButtonSize.medium,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.variant = ButtonVariant.outline,
    this.loading = false,
    this.rounded = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final ButtonVariant variant;
  final bool loading;
  final bool rounded;

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
      rounded: rounded,
      child: const SizedBox.shrink(),
    );
  }
}

/// Floating action button with consistent theming
class MindloadFAB extends StatelessWidget {
  const MindloadFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = ButtonSize.large,
    this.disabled = false,
    this.semanticLabel,
    this.tooltip,
    this.loading = false,
    this.elevation = 6,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final ButtonSize size;
  final bool disabled;
  final String? semanticLabel;
  final String? tooltip;
  final bool loading;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      icon: icon,
      loading: loading,
      rounded: true,
      elevation: elevation,
      child: const SizedBox.shrink(),
    );
  }
}

/// Button group for related actions
class ButtonGroup extends StatelessWidget {
  const ButtonGroup({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.spacing = 12.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final Axis direction;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _buildChildrenWithSpacing(),
      );
    }
  }

  List<Widget> _buildChildrenWithSpacing() {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
      result.add(children[i]);
    }
    return result;
  }
}

/// Button row with equal width distribution
class ButtonRow extends StatelessWidget {
  const ButtonRow({
    super.key,
    required this.children,
    this.spacing = 12.0,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  });

  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: children.map((child) {
        if (child is MindloadButton) {
          return Expanded(child: child);
        }
        return child;
      }).toList(),
    );
  }
}

/// Button column with equal width distribution
class ButtonColumn extends StatelessWidget {
  const ButtonColumn({
    super.key,
    required this.children,
    this.spacing = 12.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        if (child is MindloadButton) {
          return SizedBox(
            width: double.infinity,
            child: child,
          );
        }
        return child;
      }).toList(),
    );
  }
}

/// Convenience methods for common button patterns
class ButtonHelpers {
  /// Create a full-width version of any button
  static MindloadButton makeFullWidth(MindloadButton button) {
    return MindloadButton(
      onPressed: button.onPressed,
      variant: button.variant,
      size: button.size,
      disabled: button.disabled,
      semanticLabel: button.semanticLabel,
      tooltip: button.tooltip,
      fullWidth: true,
      icon: button.icon,
      iconPosition: button.iconPosition,
      loading: button.loading,
      rounded: button.rounded,
      elevation: button.elevation,
      borderRadius: button.borderRadius,
      child: button.child,
    );
  }

  /// Create a rounded version of any button
  static MindloadButton makeRounded(MindloadButton button) {
    return MindloadButton(
      onPressed: button.onPressed,
      variant: button.variant,
      size: button.size,
      disabled: button.disabled,
      semanticLabel: button.semanticLabel,
      tooltip: button.tooltip,
      fullWidth: button.fullWidth,
      icon: button.icon,
      iconPosition: button.iconPosition,
      loading: button.loading,
      rounded: true,
      elevation: button.elevation,
      borderRadius: button.borderRadius,
      child: button.child,
    );
  }

  /// Create a loading version of any button
  static MindloadButton makeLoading(MindloadButton button) {
    return MindloadButton(
      onPressed: button.onPressed,
      variant: button.variant,
      size: button.size,
      disabled: button.disabled,
      semanticLabel: button.semanticLabel,
      tooltip: button.tooltip,
      fullWidth: button.fullWidth,
      icon: button.icon,
      iconPosition: button.iconPosition,
      loading: true,
      rounded: button.rounded,
      elevation: button.elevation,
      borderRadius: button.borderRadius,
      child: button.child,
    );
  }
}

/// Pre-configured button presets for common use cases
class ButtonPresets {
  /// Standard primary button for main actions
  static MindloadButton primary({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool disabled = false,
    String? semanticLabel,
    String? tooltip,
    bool fullWidth = false,
    IconData? icon,
    IconPosition iconPosition = IconPosition.start,
    bool loading = false,
    bool rounded = false,
    double elevation = 2,
  }) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }

  /// Standard secondary button for alternative actions
  static MindloadButton secondary({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool disabled = false,
    String? semanticLabel,
    String? tooltip,
    bool fullWidth = false,
    IconData? icon,
    IconPosition iconPosition = IconPosition.start,
    bool loading = false,
    bool rounded = false,
    double elevation = 0,
  }) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }

  /// Standard destructive button for dangerous actions
  static MindloadButton destructive({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool disabled = false,
    String? semanticLabel,
    String? tooltip,
    bool fullWidth = false,
    IconData? icon,
    IconPosition iconPosition = IconPosition.start,
    bool loading = false,
    bool rounded = false,
    double elevation = 0,
  }) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.error,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }

  /// Standard success button for confirmation actions
  static MindloadButton success({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonSize size = ButtonSize.medium,
    bool disabled = false,
    String? semanticLabel,
    String? tooltip,
    bool fullWidth = false,
    IconData? icon,
    IconPosition iconPosition = IconPosition.start,
    bool loading = false,
    bool rounded = false,
    double elevation = 1,
  }) {
    return MindloadButton(
      onPressed: onPressed,
      variant: ButtonVariant.success,
      size: size,
      disabled: disabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      fullWidth: fullWidth,
      icon: icon,
      iconPosition: iconPosition,
      loading: loading,
      rounded: rounded,
      elevation: elevation,
      child: child,
    );
  }
}
