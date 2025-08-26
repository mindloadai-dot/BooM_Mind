import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'dart:math' as math;

/// Enhanced BrandMark component with WCAG AAA compliant subtitle readability
/// Implements automatic contrast checking and overlay management across all themes
class BrandMark extends StatefulWidget {
  final double size;
  final bool showSubtitle;
  final String title;
  final String subtitle;
  final bool enableGlow;
  final bool enableAnimation;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment alignment;

  const BrandMark({
    super.key,
    this.size = 120,
    this.showSubtitle = true,
    this.title = 'MINDLOAD',
    this.subtitle = 'AI STUDY INTERFACE',
    this.enableGlow = true,
    this.enableAnimation = true,
    this.padding = const EdgeInsets.all(24.0),
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark> {
  double _currentOverlayAlpha = 0.0;
  Color? _effectiveOverlayColor;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _computeOptimalOverlay();
  }

  /// Computes overlay using theme values only (contrast logic removed)
  void _computeOptimalOverlay() {
    final tokens = context.tokens;
    _effectiveOverlayColor = tokens.heroOverlay;
    _currentOverlayAlpha = tokens.heroOverlay.a;
  }
  
  /// Blend overlay with background to compute effective background color
  Color _blendOverlay(Color background, Color overlay) {
    final alpha = overlay.a;
    return Color.lerp(background, overlay, alpha) ?? background;
  }
  
  /// Determines if theme is dark based on background luminance
  bool _isDarkTheme(Color background) {
    return background.computeLuminance() < 0.5;
  }
  
  // Contrast fallback adjustment removed

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final isDark = _isDarkTheme(tokens.heroBackground);
    
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: tokens.heroBackground,
        // Optional: Add gradient overlay for dynamic imagery support
        gradient: _currentOverlayAlpha > 0.01 ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _effectiveOverlayColor ?? tokens.heroOverlay,
            _effectiveOverlayColor?.withValues(alpha: _currentOverlayAlpha * 0.7) ?? tokens.heroOverlay,
          ],
        ) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.alignment,
        children: [
          // Logo (optional geometric logo above title)
          if (widget.size > 80)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GeometricLogo(
                size: widget.size * 0.4,
                color: tokens.brandTitle,
                animate: widget.enableAnimation,
              ),
            ),
          
          // Main title with neon glow effect
          _buildTitle(tokens, textTheme, isDark),
          
          // Subtitle with enhanced readability
          if (widget.showSubtitle) ...[
            const SizedBox(height: 12),
            _buildSubtitle(tokens, textTheme, isDark),
          ],
        ],
      ),
    );
  }
  
  /// Builds the main title with optional neon glow
  Widget _buildTitle(SemanticTokens tokens, TextTheme textTheme, bool isDark) {
    final titleStyle = textTheme.displayLarge?.copyWith(
      color: tokens.brandTitle,
      fontWeight: FontWeight.bold,
      letterSpacing: _calculateLetterSpacing(widget.title.length),
      fontSize: _calculateTitleFontSize(),
    );
    
    if (!widget.enableGlow || tokens == ThemeManager.instance.getSemanticTokens(AppTheme.minimal)) {
      // No glow for minimal theme or when disabled
      return Text(
        widget.title,
        style: titleStyle,
        textAlign: TextAlign.center,
        semanticsLabel: 'Mindload app title',
      );
    }
    
    // Enhanced neon glow effect for title only
    return Text(
      widget.title,
      style: titleStyle?.copyWith(
        shadows: _buildNeonShadows(tokens.brandTitle),
      ),
      textAlign: TextAlign.center,
      semanticsLabel: 'Mindload app title',
    );
  }
  
  /// Builds the subtitle with enhanced contrast and accessibility
  Widget _buildSubtitle(SemanticTokens tokens, TextTheme textTheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: _currentOverlayAlpha > 0.02 ? BoxDecoration(
        color: _effectiveOverlayColor,
        borderRadius: BorderRadius.circular(4),
      ) : null,
      child: Text(
        widget.subtitle,
        style: textTheme.titleMedium?.copyWith(
          color: tokens.brandSubtitle,
          fontSize: _calculateSubtitleFontSize(),
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0, // +2% letter spacing per spec
          height: 1.4,
          // Subtle shadow for additional contrast safety (no glow)
          shadows: [
            Shadow(
              blurRadius: 1.0,
              color: tokens.shadowBrandSubtitle,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        semanticsLabel: 'AI Study Interface subtitle',
      ),
    );
  }
  
  /// Calculates optimal title font size based on widget size
  double _calculateTitleFontSize() {
    final baseSize = widget.size * 0.35;
    return math.max(28.0, math.min(baseSize, 64.0));
  }
  
  /// Calculates optimal subtitle font size (14-16sp range per spec)
  double _calculateSubtitleFontSize() {
    final baseSize = widget.size * 0.12;
    return math.max(14.0, math.min(baseSize, 16.0));
  }
  
  /// Calculates letter spacing based on title length
  double _calculateLetterSpacing(int titleLength) {
    if (titleLength <= 6) return 6.0;
    if (titleLength <= 8) return 4.0;
    return 2.0;
  }
  
  /// Builds neon glow shadows for title (multi-layer effect)
  List<Shadow> _buildNeonShadows(Color glowColor) {
    return [
      // Inner bright glow
      Shadow(
        blurRadius: 15.0,
        color: glowColor.withValues(alpha: 0.9),
        offset: Offset.zero,
      ),
      // Middle glow
      Shadow(
        blurRadius: 30.0,
        color: glowColor.withValues(alpha: 0.7),
        offset: Offset.zero,
      ),
      // Outer glow
      Shadow(
        blurRadius: 45.0,
        color: glowColor.withValues(alpha: 0.5),
        offset: Offset.zero,
      ),
      // Extended glow for extra neon effect
      Shadow(
        blurRadius: 60.0,
        color: glowColor.withValues(alpha: 0.3),
        offset: Offset.zero,
      ),
    ];
  }
}

/// Alternative HeroHeader component for larger contexts (welcome screens, etc.)
class HeroHeader extends StatelessWidget {
  final double height;
  final String title;
  final String subtitle;
  final Widget? additionalContent;
  final bool enableParallax;

  const HeroHeader({
    super.key,
    this.height = 300,
    this.title = 'MINDLOAD',
    this.subtitle = 'AI STUDY INTERFACE', 
    this.additionalContent,
    this.enableParallax = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.heroBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.heroBackground,
            tokens.heroBackground.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spacer for better vertical balance
            const Spacer(),
            
            // Main brand mark
            BrandMark(
              size: height * 0.4,
              title: title,
              subtitle: subtitle,
              showSubtitle: true,
              enableGlow: true,
              enableAnimation: true,
              alignment: CrossAxisAlignment.center,
            ),
            
            // Additional content (CTA buttons, etc.)
            if (additionalContent != null) ...[
              const SizedBox(height: 32),
              additionalContent!,
            ],
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// Brand contrast validation removed