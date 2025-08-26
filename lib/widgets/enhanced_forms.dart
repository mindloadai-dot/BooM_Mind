import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/enhanced_design_system.dart';

/// Enhanced text input field with better visual design
class EnhancedTextInput extends StatefulWidget {
  const EnhancedTextInput({
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
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.semanticLabel,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.expands = false,
    this.focusNode,
    this.variant = CardVariant.default_,
    this.animate = true,
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
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final String? semanticLabel;
  final bool autofocus;
  final bool readOnly;
  final bool showCursor;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool expands;
  final FocusNode? focusNode;
  final CardVariant variant;
  final bool animate;

  @override
  State<EnhancedTextInput> createState() => _EnhancedTextInputState();
}

class _EnhancedTextInputState extends State<EnhancedTextInput>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late Animation<double> _errorAnimation;
  bool _hasFocus = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(EnhancedTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      _hasError = widget.errorText != null;
      if (_hasError && widget.animate) {
        _errorAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ));
        _animationController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    if (widget.animate) {
      if (_hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: hasError
                          ? tokens.error
                          : (_hasFocus ? tokens.primary : tokens.textPrimary),
                      fontWeight: FontWeight.w600,
                    ) ??
                const TextStyle(),
            child: Text(widget.labelText!),
          ),
          const SizedBox(height: EnhancedSpacing.xs),
        ],
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? tokens.error
                      : (_hasFocus ? tokens.primary : tokens.borderDefault),
                  width: _hasFocus ? 2.0 : 1.5,
                ),
                boxShadow: _hasFocus
                    ? [
                        BoxShadow(
                          color: tokens.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                validator: widget.validator,
                autofocus: widget.autofocus,
                readOnly: widget.readOnly,
                showCursor: widget.showCursor,
                autocorrect: widget.autocorrect,
                enableSuggestions: widget.enableSuggestions,
                expands: widget.expands,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: widget.enabled
                          ? tokens.textPrimary
                          : tokens.textTertiary,
                    ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.all(EnhancedSpacing.sm),
                          child: widget.prefixIcon!,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.all(EnhancedSpacing.sm),
                          child: widget.suffixIcon!,
                        )
                      : null,
                  filled: true,
                  fillColor: widget.enabled
                      ? tokens.surface
                      : tokens.muted.withValues(alpha: 0.1),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: tokens.textTertiary,
                      ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: EnhancedSpacing.md,
                    vertical: EnhancedSpacing.md,
                  ),
                  counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ),
            );
          },
        ),
        if (widget.helperText != null || hasError) ...[
          const SizedBox(height: EnhancedSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasError
                ? AnimatedBuilder(
                    animation: _errorAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_errorAnimation.value * 4, 0),
                        child: Text(
                          widget.errorText!,
                          key: const ValueKey('error'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      );
                    },
                  )
                : Text(
                    widget.helperText!,
                    key: const ValueKey('helper'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Enhanced form with better layout and validation
class EnhancedForm extends StatelessWidget {
  const EnhancedForm({
    super.key,
    required this.child,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final Widget child;
  final VoidCallback? onChanged;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Form(
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      child: child,
    );
  }
}

/// Enhanced form section with header and content
class EnhancedFormSection extends StatelessWidget {
  const EnhancedFormSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.variant = CardVariant.default_,
    this.padding = const EdgeInsets.all(EnhancedSpacing.md),
    this.margin = const EdgeInsets.only(bottom: EnhancedSpacing.lg),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final CardVariant variant;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: EnhancedCard(
        variant: variant,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnhancedSectionHeader(
              title: title,
              subtitle: subtitle,
              icon: icon,
              variant: variant,
            ),
            const SizedBox(height: EnhancedSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Enhanced form actions with consistent button layout
class EnhancedFormActions extends StatelessWidget {
  const EnhancedFormActions({
    super.key,
    required this.primaryAction,
    this.secondaryAction,
    this.tertiaryAction,
    this.layout = FormActionLayout.horizontal,
    this.spacing = EnhancedSpacing.md,
    this.mainAxisAlignment = MainAxisAlignment.end,
  });

  final Widget primaryAction;
  final Widget? secondaryAction;
  final Widget? tertiaryAction;
  final FormActionLayout layout;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (tertiaryAction != null) {
      actions.add(tertiaryAction!);
    }
    if (secondaryAction != null) {
      actions.add(secondaryAction!);
    }
    actions.add(primaryAction);

    if (layout == FormActionLayout.horizontal) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        children: _buildActionsWithSpacing(actions, spacing),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildActionsWithSpacing(actions, spacing),
      );
    }
  }

  List<Widget> _buildActionsWithSpacing(List<Widget> actions, double spacing) {
    final List<Widget> result = [];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) {
        result.add(SizedBox(
          width: spacing,
          height: spacing,
        ));
      }
      result.add(actions[i]);
    }
    return result;
  }
}

/// Form action layout options
enum FormActionLayout {
  horizontal,
  vertical,
}

/// Enhanced form field group for related inputs
class EnhancedFormFieldGroup extends StatelessWidget {
  const EnhancedFormFieldGroup({
    super.key,
    required this.children,
    this.spacing = EnhancedSpacing.md,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: _buildChildrenWithSpacing(children, spacing),
    );
  }

  List<Widget> _buildChildrenWithSpacing(
      List<Widget> children, double spacing) {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(SizedBox(height: spacing));
      }
      result.add(children[i]);
    }
    return result;
  }
}

/// Enhanced form validation message
class EnhancedFormValidationMessage extends StatelessWidget {
  const EnhancedFormValidationMessage({
    super.key,
    required this.message,
    this.type = ValidationMessageType.error,
    this.icon,
    this.animate = true,
  });

  final String message;
  final ValidationMessageType type;
  final IconData? icon;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    final color = switch (type) {
      ValidationMessageType.error => tokens.error,
      ValidationMessageType.warning => tokens.warning,
      ValidationMessageType.success => tokens.success,
      ValidationMessageType.info => tokens.primary,
    };

    final defaultIcon = switch (type) {
      ValidationMessageType.error => Icons.error_outline,
      ValidationMessageType.warning => Icons.warning_amber_outlined,
      ValidationMessageType.success => Icons.check_circle_outline,
      ValidationMessageType.info => Icons.info_outline,
    };

    Widget messageWidget = Container(
      padding: const EdgeInsets.all(EnhancedSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? defaultIcon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: EnhancedSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );

    if (animate) {
      messageWidget = AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: messageWidget,
      );
    }

    return messageWidget;
  }
}

/// Validation message types
enum ValidationMessageType {
  error,
  warning,
  success,
  info,
}
