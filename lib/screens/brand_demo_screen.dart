import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/brand_mark.dart';
import 'package:mindload/widgets/unified_design_system.dart';

/// Demo screen to showcase BrandMark component across all themes
/// Useful for validating subtitle readability and theme display
class BrandDemoScreen extends StatefulWidget {
  const BrandDemoScreen({super.key});

  @override
  State<BrandDemoScreen> createState() => _BrandDemoScreenState();
}

class _BrandDemoScreenState extends State<BrandDemoScreen> {
  @override
  void initState() {
    super.initState();
    // Screen loads without contrast validation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'Brand Mark Demo',
            style: TextStyle(fontSize: 18), // Reduced from default
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: UnifiedSpacing.screenPadding,
        children: [
          // Instructions
          UnifiedCard(
            padding: UnifiedSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  'BrandMark Theme Demo',
                  style: UnifiedTypography.titleLarge,
                ),
                SizedBox(height: UnifiedSpacing.sm),
                UnifiedText(
                  'This demo showcases the BrandMark component across different themes. '
                  'The subtitle readability is handled by the theme system.',
                  style: UnifiedTypography.bodyMedium,
                ),
                SizedBox(height: UnifiedSpacing.md),
                Row(
                  children: [
                    UnifiedIcon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: UnifiedSpacing.sm),
                    Expanded(
                      child: UnifiedText(
                        'Switch themes to see how BrandMark adapts.',
                        style: UnifiedTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: UnifiedSpacing.lg),
          
          // Current theme demo
          UnifiedCard(
            child: Column(
              children: [
                Padding(
                  padding: UnifiedSpacing.cardPadding,
                  child: UnifiedText(
                    'Current Theme: ${ThemeManager.instance.getThemeDisplayName(ThemeManager.instance.currentTheme)}',
                    style: UnifiedTypography.titleMedium,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: const BrandMark(
                    size: 160,
                    title: 'MINDLOAD',
                    subtitle: 'AI STUDY INTERFACE',
                    showSubtitle: true,
                    enableGlow: true,
                    enableAnimation: true,
                  ),
                ),
                Padding(
                  padding: UnifiedSpacing.cardPadding,
                  child: _buildThemeInfo(ThemeManager.instance.currentTheme),
                ),
              ],
            ),
          ),
          
          SizedBox(height: UnifiedSpacing.lg),
          
          // All themes preview
          UnifiedText(
            'All Themes Preview',
            style: UnifiedTypography.headlineSmall,
          ),
          
          SizedBox(height: UnifiedSpacing.md),
          
          ...AppTheme.values.map((theme) => _buildThemePreviewCard(theme)),
        ],
      ),
    );
  }
  
  /// Builds theme information for a theme
  Widget _buildThemeInfo(AppTheme theme) {
    final tokens = ThemeManager.instance.getSemanticTokens(theme);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UnifiedIcon(
          Icons.palette,
          color: tokens.primary,
          size: 20,
        ),
        SizedBox(width: UnifiedSpacing.sm),
        UnifiedText(
          'Theme: ${ThemeManager.instance.getThemeDisplayName(theme)}',
          style: UnifiedTypography.bodySmall.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  /// Builds a preview card for each theme
  Widget _buildThemePreviewCard(AppTheme theme) {
    final tokens = ThemeManager.instance.getSemanticTokens(theme);
    
    return UnifiedCard(
      margin: EdgeInsets.only(bottom: UnifiedSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: UnifiedSpacing.cardPadding,
            child: Row(
              children: [
                UnifiedIcon(ThemeManager.instance.getThemeIcon(theme)),
                SizedBox(width: UnifiedSpacing.sm),
                UnifiedText(
                  ThemeManager.instance.getThemeDisplayName(theme),
                  style: UnifiedTypography.titleMedium,
                ),
                const Spacer(),
                UnifiedIcon(
                  Icons.palette,
                  color: tokens.primary,
                  size: 20,
                ),
              ],
            ),
          ),
          
          // Theme preview container
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tokens.heroBackground,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title preview
                  UnifiedText(
                    'MINDLOAD',
                    style: TextStyle(
                      color: tokens.brandTitle,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: UnifiedSpacing.xs),
                  // Subtitle preview with overlay background if needed
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: UnifiedSpacing.sm, vertical: UnifiedSpacing.xs),
                    decoration: (tokens.heroOverlay.a * 255.0).round() & 0xff > 10 ? BoxDecoration(
                      color: tokens.heroOverlay,
                      borderRadius: UnifiedBorderRadius.xsRadius,
                    ) : null,
                    child: UnifiedText(
                      'AI STUDY INTERFACE',
                      style: TextStyle(
                        color: tokens.brandSubtitle,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Theme details
          Padding(
            padding: UnifiedSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  'Background: ${tokens.heroBackground.toString()}',
                  style: UnifiedTypography.bodySmall,
                ),
                SizedBox(height: UnifiedSpacing.xs),
                UnifiedText(
                  'Subtitle: ${tokens.brandSubtitle.toString()}',
                  style: UnifiedTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}