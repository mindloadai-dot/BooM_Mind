import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/enhanced_design_system.dart';

/// Enhanced bottom navigation bar with better visual feedback
class EnhancedBottomNavigationBar extends StatefulWidget {
  const EnhancedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
    this.type = BottomNavigationBarType.fixed,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<EnhancedBottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final BottomNavigationBarType type;

  @override
  State<EnhancedBottomNavigationBar> createState() =>
      _EnhancedBottomNavigationBarState();
}

class _EnhancedBottomNavigationBarState
    extends State<EnhancedBottomNavigationBar> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != widget.currentIndex) {
      _animationControllers[index].forward().then((_) {
        _animationControllers[index].reverse();
      });
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? tokens.elevatedSurface,
        border: Border(
          top: BorderSide(
            color: tokens.borderDefault.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(
              horizontal: EnhancedSpacing.md, vertical: EnhancedSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavigationItem(index, tokens),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(int index, SemanticTokens tokens) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    final color = isSelected
        ? (widget.selectedItemColor ?? tokens.primary)
        : (widget.unselectedItemColor ?? tokens.textSecondary);

    return Expanded(
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: InkWell(
              onTap: () => _onItemTapped(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: EnhancedSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: EnhancedSpacing.xs),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ) ??
                          const TextStyle(),
                      child: Text(item.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced bottom navigation bar item
class EnhancedBottomNavigationBarItem {
  const EnhancedBottomNavigationBarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final Widget? badge;
  final String? semanticLabel;
}

/// Enhanced app bar with better visual design
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EnhancedAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.flexibleSpace,
    this.bottom,
    this.shape,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth = 56.0,
    this.titleSpacing = 16.0,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.surfaceTintColor,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.excludeHeaderSemantics = false,
    this.titleTextStyle,
    this.toolbarTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior = Clip.none,
    this.scrolledUnderColor,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double elevation;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final ShapeBorder? shape;
  final double toolbarHeight;
  final double leadingWidth;
  final double titleSpacing;
  final double toolbarOpacity;
  final double bottomOpacity;
  final Color? surfaceTintColor;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool excludeHeaderSemantics;
  final TextStyle? titleTextStyle;
  final TextStyle? toolbarTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool forceMaterialTransparency;
  final Clip clipBehavior;
  final Color? scrolledUnderColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return AppBar(
      title: title != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                title!,
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w400,
                            ) ??
                        const TextStyle(),
                    child: subtitle!,
                  ),
                ],
              ],
            )
          : null,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? tokens.elevatedSurface,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
      toolbarHeight: toolbarHeight,
      leadingWidth: leadingWidth,
      titleSpacing: titleSpacing,
      toolbarOpacity: toolbarOpacity,
      bottomOpacity: bottomOpacity,
      surfaceTintColor: surfaceTintColor,
      scrolledUnderElevation: scrolledUnderElevation,
      shadowColor: shadowColor ?? tokens.overlayDim,
      foregroundColor: foregroundColor ?? tokens.textPrimary,
      iconTheme: iconTheme ??
          IconThemeData(
            color: tokens.textPrimary,
            size: 24,
          ),
      actionsIconTheme: actionsIconTheme ??
          IconThemeData(
            color: tokens.textPrimary,
            size: 24,
          ),
      primary: primary,
      excludeHeaderSemantics: excludeHeaderSemantics,
      titleTextStyle: titleTextStyle ??
          Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
      toolbarTextStyle: toolbarTextStyle,
      systemOverlayStyle: systemOverlayStyle,
      forceMaterialTransparency: forceMaterialTransparency,
      clipBehavior: clipBehavior,
    );
  }
}

/// Enhanced breadcrumb navigation
class EnhancedBreadcrumbs extends StatelessWidget {
  const EnhancedBreadcrumbs({
    super.key,
    required this.items,
    this.onItemTap,
    this.separator = Icons.chevron_right,
    this.separatorColor,
    this.textStyle,
    this.activeTextStyle,
  });

  final List<BreadcrumbItem> items;
  final ValueChanged<int>? onItemTap;
  final IconData separator;
  final Color? separatorColor;
  final TextStyle? textStyle;
  final TextStyle? activeTextStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EnhancedSpacing.md,
        vertical: EnhancedSpacing.sm,
      ),
      child: Row(
        children: List.generate(
          items.length * 2 - 1,
          (index) {
            if (index.isOdd) {
              // Separator
              return Icon(
                separator,
                size: 16,
                color: separatorColor ?? tokens.textTertiary,
              );
            } else {
              // Item
              final itemIndex = index ~/ 2;
              final item = items[itemIndex];
              final isActive = itemIndex == items.length - 1;
              final isClickable = onItemTap != null && !isActive;

              return Expanded(
                child: InkWell(
                  onTap: isClickable ? () => onItemTap!(itemIndex) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EnhancedSpacing.sm,
                      vertical: EnhancedSpacing.xs,
                    ),
                    child: Text(
                      item.label,
                      style: (isActive ? activeTextStyle : textStyle)?.copyWith(
                            color: isActive
                                ? tokens.primary
                                : (isClickable
                                    ? tokens.textSecondary
                                    : tokens.textTertiary),
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ) ??
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isActive
                                    ? tokens.primary
                                    : (isClickable
                                        ? tokens.textSecondary
                                        : tokens.textTertiary),
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Breadcrumb item
class BreadcrumbItem {
  const BreadcrumbItem({
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final String? semanticLabel;
}

/// Enhanced floating action button with animations
class EnhancedFAB extends StatefulWidget {
  const EnhancedFAB({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 6.0,
    this.heroTag,
    this.tooltip,
    this.semanticLabel,
    this.animate = true,
  });

  final VoidCallback? onPressed;
  final Widget? icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Object? heroTag;
  final String? tooltip;
  final String? semanticLabel;
  final bool animate;

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
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

  void _onPressed() {
    if (widget.animate) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;

    Widget fab = FloatingActionButton(
      onPressed: _onPressed,
      backgroundColor: widget.backgroundColor ?? tokens.primary,
      foregroundColor: widget.foregroundColor ?? tokens.onPrimary,
      elevation: widget.elevation,
      heroTag: widget.heroTag,
      tooltip: widget.tooltip,
      child: widget.icon ?? const Icon(Icons.add),
    );

    if (widget.animate) {
      fab = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: child,
            ),
          );
        },
        child: fab,
      );
    }

    if (widget.semanticLabel != null) {
      fab = Semantics(
        label: widget.semanticLabel,
        button: true,
        child: fab,
      );
    }

    return fab;
  }
}
