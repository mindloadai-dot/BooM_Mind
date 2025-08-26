import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mindload/screens/paywall_screen.dart';
import 'package:mindload/theme.dart';

// Widget that shows 40% of content with blur overlay and paywall CTA
class BlurredContentPreview extends StatelessWidget {
  final Widget content;
  final double previewPercentage;
  final String ctaText;
  final String trigger;

  const BlurredContentPreview({
    super.key,
    required this.content,
    this.previewPercentage = 0.4,
    this.ctaText = 'Unlock for \$2.99 (first month)',
    this.trigger = 'content_preview',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = constraints.maxHeight * previewPercentage;
        
        return Stack(
          children: [
            // Full content (will be partially hidden)
            content,
            
            // Blur overlay for the bottom part
            Positioned(
              top: previewHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.surface.withValues(alpha: 0.1),
                          tokens.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lock icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: tokens.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 32,
                              color: tokens.primary,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // CTA Text
                          Text(
                            'Preview Complete',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: tokens.textEmphasis,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Get full access to all your study materials',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // CTA Button
                          SizedBox(
                            width: 280,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _showPaywall(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.primary,
                                foregroundColor: tokens.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ctaText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(trigger: trigger),
        fullscreenDialog: true,
      ),
    );
  }
}

// Specialized widget for study set content preview
class StudySetPreview extends StatelessWidget {
  final List<Widget> items;
  final String title;
  final String trigger;

  const StudySetPreview({
    super.key,
    required this.items,
    required this.title,
    this.trigger = 'study_set_preview',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final previewCount = (items.length * 0.4).ceil().clamp(1, items.length);
    final previewItems = items.take(previewCount).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview items
        ...previewItems,
        
        // Blur overlay for remaining content
        if (previewCount < items.length) ...[
          const SizedBox(height: 16),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Faded content preview
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          tokens.surface.withValues(alpha: 0.3),
                          tokens.surface.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off,
                              size: 32,
                              color: tokens.textTertiary,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Text(
                              '${items.length - previewCount} more ${title.toLowerCase()} locked',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: tokens.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            ElevatedButton(
                              onPressed: () => _showPaywall(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.primary,
                                foregroundColor: tokens.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Unlock All • \$2.99',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(trigger: trigger),
        fullscreenDialog: true,
      ),
    );
  }
}

// Generic widget for any list content with paywall
class PaywalledList extends StatelessWidget {
  final List<Widget> items;
  final double previewRatio;
  final String unlockText;
  final String trigger;

  const PaywalledList({
    super.key,
    required this.items,
    this.previewRatio = 0.4,
    this.unlockText = 'Unlock All',
    this.trigger = 'list_preview',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    if (items.isEmpty) return const SizedBox.shrink();
    
    final previewCount = (items.length * previewRatio).ceil().clamp(1, items.length);
    final showPaywall = previewCount < items.length;
    
    return Column(
      children: [
        // Show preview items
        ...items.take(previewCount),
        
        // Show paywall overlay if there are more items
        if (showPaywall) ...[
          const SizedBox(height: 8),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tokens.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: tokens.primary,
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '${items.length - previewCount} more items available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.textEmphasis,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () => _showPaywall(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '$unlockText • \$2.99',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaywallScreen(trigger: trigger),
        fullscreenDialog: true,
      ),
    );
  }
}