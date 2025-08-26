import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/accessible_back_button.dart';
import 'package:mindload/widgets/credits_token_chip.dart';

/// Animated MINDLOAD title widget with glowing effect
class AnimatedMindloadTitle extends StatefulWidget {
  final double fontSize;
  final Color? color;
  final bool showSubtitle;
  
  const AnimatedMindloadTitle({
    super.key,
    this.fontSize = 18,
    this.color,
    this.showSubtitle = false,
  });
  
  @override
  State<AnimatedMindloadTitle> createState() => _AnimatedMindloadTitleState();
}

class _AnimatedMindloadTitleState extends State<AnimatedMindloadTitle> 
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MINDLOAD',
            style: TextStyle(
              fontSize: widget.fontSize,
              color: effectiveColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 15.0 * _glowAnimation.value,
                  color: effectiveColor.withValues(alpha: 0.8 * _glowAnimation.value),
                  offset: const Offset(0.0, 0.0),
                ),
                Shadow(
                  blurRadius: 30.0 * _glowAnimation.value,
                  color: effectiveColor.withValues(alpha: 0.6 * _glowAnimation.value),
                  offset: const Offset(0.0, 0.0),
                ),
              ],
            ),
          ),
          if (widget.showSubtitle)
            Text(
              'AI STUDY INTERFACE',
              style: TextStyle(
                fontSize: widget.fontSize * 0.4,
                color: Theme.of(context).colorScheme.secondary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w300,
              ),
            ),
        ],
      ),
    );
  }
}

class MindloadAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final bool showCreditsChip;
  final VoidCallback? onBuyCredits;
  final VoidCallback? onViewLedger;
  final VoidCallback? onUpgrade;

  const MindloadAppBar({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.showCreditsChip = true,
    this.onBuyCredits,
    this.onViewLedger,
    this.onUpgrade,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppBar(
      foregroundColor: tokens.navText,
      elevation: elevation,
      centerTitle: centerTitle,
      scrolledUnderElevation: 1,
      surfaceTintColor: tokens.primary,
      
      // Leading widget (back button or custom)
      leading: leading ?? (showBackButton ? _buildLeading(context, tokens) : null),
      automaticallyImplyLeading: false,
      leadingWidth: showBackButton ? 64 : null, // Constrained width to prevent overflow
      
      // Title with modern styling - use animated MINDLOAD title if title is 'MINDLOAD'
      title: title != null
          ? (title == 'MINDLOAD'
              ? AnimatedMindloadTitle(
                  fontSize: 18, // Reduced from 20
                  color: tokens.navText,
                )
              : FittedBox( // Added FittedBox to prevent overflow
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.navText,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 18, // Reduced from 20
                    ),
                    maxLines: 1, // Ensure single line
                    overflow: TextOverflow.ellipsis, // Fallback overflow handling
                  ),
                ))
          : null,
      
      // Actions with credits chip
      actions: _buildActions(context, tokens),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: tokens.navIcon,
        size: 24,
      ),
      
      // Action icon theme
      actionsIconTheme: IconThemeData(
        color: tokens.navIcon,
        size: 24,
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context, SemanticTokens tokens) {
    final actionWidgets = <Widget>[];

    // Add credits chip first if enabled
    if (showCreditsChip) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: CreditsTokenChip(
            onBuyCreditsPressed: onBuyCredits,
            onViewLedgerPressed: onViewLedger,
            onUpgradePressed: onUpgrade,
          ),
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(
        actions!.map((action) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: action,
        )),
      );
    }

    return actionWidgets.isNotEmpty ? actionWidgets : null;
  }

  Widget? _buildLeading(BuildContext context, SemanticTokens tokens) {
    if (!Navigator.of(context).canPop() && onBackPressed == null) {
      return null;
    }

    return Container(
      alignment: Alignment.centerLeft,
      constraints: const BoxConstraints(maxWidth: 64, maxHeight: 56),
      child: AccessibleBackButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        iconColor: tokens.navIcon,
        textColor: tokens.navText,
        showText: false, // Prevent text overflow on mobile
      ),
    );
  }
}

/// Factory methods for common app bar configurations
extension MindloadAppBarFactory on MindloadAppBar {
  /// Standard app bar with back button
  static MindloadAppBar standard({
    required String title,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
    bool showCreditsChip = true,
    VoidCallback? onBuyCredits,
    VoidCallback? onViewLedger,
    VoidCallback? onUpgrade,
  }) {
    return MindloadAppBar(
      title: title,
      actions: actions,
      onBackPressed: onBackPressed,
      showCreditsChip: showCreditsChip,
      onBuyCredits: onBuyCredits,
      onViewLedger: onViewLedger,
      onUpgrade: onUpgrade,
    );
  }

  /// App bar without back button (for main screens)
  static MindloadAppBar main({
    required String title,
    List<Widget>? actions,
    bool showCreditsChip = true,
    VoidCallback? onBuyCredits,
    VoidCallback? onViewLedger,
    VoidCallback? onUpgrade,
  }) {
    return MindloadAppBar(
      title: title,
      actions: actions,
      showBackButton: false,
      centerTitle: false, // Left align title for modern look
      showCreditsChip: showCreditsChip,
      onBuyCredits: onBuyCredits,
      onViewLedger: onViewLedger,
      onUpgrade: onUpgrade,
    );
  }

  /// Secondary app bar (for achievements, etc.)
  static MindloadAppBar secondary({
    required String title,
    List<Widget>? actions,
    VoidCallback? onBackPressed,
    bool showCreditsChip = true,
    VoidCallback? onBuyCredits,
    VoidCallback? onViewLedger,
    VoidCallback? onUpgrade,
  }) {
    return MindloadAppBar(
      title: title,
      actions: actions,
      onBackPressed: onBackPressed,
      showCreditsChip: showCreditsChip,
      onBuyCredits: onBuyCredits,
      onViewLedger: onViewLedger,
      onUpgrade: onUpgrade,
      centerTitle: false,
      elevation: 0.5,
    );
  }

  /// Minimal app bar (no title, just actions)
  static MindloadAppBar minimal({
    List<Widget>? actions,
    VoidCallback? onBackPressed,
    bool showCreditsChip = true,
    VoidCallback? onBuyCredits,
    VoidCallback? onViewLedger,
    VoidCallback? onUpgrade,
  }) {
    return MindloadAppBar(
      actions: actions,
      onBackPressed: onBackPressed,
      showCreditsChip: showCreditsChip,
      onBuyCredits: onBuyCredits,
      onViewLedger: onViewLedger,
      onUpgrade: onUpgrade,
    );
  }

  /// Profile app bar with custom styling
  static MindloadAppBar profile({
    List<Widget>? actions,
    bool showCreditsChip = true,
    VoidCallback? onBuyCredits,
    VoidCallback? onViewLedger,
    VoidCallback? onUpgrade,
  }) {
    return MindloadAppBar(
      title: 'Profile',
      actions: actions,
      centerTitle: false,
      elevation: 0.5,
      showCreditsChip: showCreditsChip,
      onBuyCredits: onBuyCredits,
      onViewLedger: onViewLedger,
      onUpgrade: onUpgrade,
    );
  }
}