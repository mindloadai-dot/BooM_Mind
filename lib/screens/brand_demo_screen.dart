import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/brand_mark.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BrandMark Theme Demo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This demo showcases the BrandMark component across different themes. '
                    'The subtitle readability is handled by the theme system.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Switch themes to see how BrandMark adapts.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current theme demo
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Current Theme: ${ThemeManager.instance.getThemeDisplayName(ThemeManager.instance.currentTheme)}',
                    style: Theme.of(context).textTheme.titleMedium,
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
                  padding: const EdgeInsets.all(16),
                  child: _buildThemeInfo(ThemeManager.instance.currentTheme),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // All themes preview
          Text(
            'All Themes Preview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 16),
          
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
        Icon(
          Icons.palette,
          color: tokens.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Theme: ${ThemeManager.instance.getThemeDisplayName(theme)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(ThemeManager.instance.getThemeIcon(theme)),
                const SizedBox(width: 12),
                Text(
                  ThemeManager.instance.getThemeDisplayName(theme),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(
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
                  Text(
                    'MINDLOAD',
                    style: TextStyle(
                      color: tokens.brandTitle,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle preview with overlay background if needed
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: (tokens.heroOverlay.a * 255.0).round() & 0xff > 10 ? BoxDecoration(
                      color: tokens.heroOverlay,
                      borderRadius: BorderRadius.circular(4),
                    ) : null,
                    child: Text(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background: ${tokens.heroBackground.toString()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtitle: ${tokens.brandSubtitle.toString()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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