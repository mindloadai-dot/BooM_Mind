import 'package:flutter/material.dart';
import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/widgets/brand_mark.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class SimpleWelcomeScreen extends StatefulWidget {
  const SimpleWelcomeScreen({super.key});

  @override
  State<SimpleWelcomeScreen> createState() => _SimpleWelcomeScreenState();
}

class _SimpleWelcomeScreenState extends State<SimpleWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SocialAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildFeatureHighlights(BuildContext context) {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        children: [
          UnifiedText(
            'AI-POWERED STUDY ASSISTANT',
            style: UnifiedTypography.titleSmall.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: UnifiedSpacing.lg),
          _buildFeatureItem(
            context,
            Icons.description_rounded,
            'TEXT & PDF',
            'Convert documents into study materials',
          ),
          SizedBox(height: UnifiedSpacing.sm),
          _buildFeatureItem(
            context,
            Icons.play_circle_filled_rounded,
            'YOUTUBE VIDEOS',
            'Transform video content into quizzes',
          ),
          SizedBox(height: UnifiedSpacing.sm),
          _buildFeatureItem(
            context,
            Icons.psychology_rounded,
            'SMART AI',
            'Adaptive learning with GPT-4 technology',
          ),
          SizedBox(height: UnifiedSpacing.sm),
          _buildFeatureItem(
            context,
            Icons.lightbulb_outline_rounded,
            'STARTER PACKS',
            'Flexible Logic Packs from \$2.99 to \$49.99',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(UnifiedSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: UnifiedBorderRadius.smRadius,
          ),
          child: UnifiedIcon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: UnifiedSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnifiedText(
                title,
                style: UnifiedTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: UnifiedSpacing.xs),
              UnifiedText(
                description,
                style: UnifiedTypography.bodySmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Background handled by BrandMark component
        color: tokens.bg,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: UnifiedSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.vertical -
                          48)
                      .clamp(0.0, double.infinity),
                ),
                child: Column(
                  children: [
                    // Main content area - centered
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Enhanced BrandMark with WCAG AAA compliant subtitle
                              BrandMark(
                                size: 200,
                                title: 'MINDLOAD',
                                subtitle: 'AI STUDY INTERFACE',
                                showSubtitle: true,
                                enableGlow: true,
                                enableAnimation: true,
                                alignment: CrossAxisAlignment.center,
                                padding: EdgeInsets.zero,
                              ),

                              SizedBox(height: UnifiedSpacing.xxl),

                              // Feature highlights
                              _buildFeatureHighlights(context),

                              SizedBox(height: UnifiedSpacing.xxl),

                              // Get started button
                              UnifiedButton(
                                onPressed: _navigateToAuth,
                                fullWidth: true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    UnifiedIcon(Icons.rocket_launch, size: 24),
                                    SizedBox(width: UnifiedSpacing.md),
                                    UnifiedText(
                                      'LAUNCH APP',
                                      style: UnifiedTypography.titleMedium
                                          .copyWith(
                                        color: tokens.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom info
                    Padding(
                      padding: EdgeInsets.only(bottom: UnifiedSpacing.md),
                      child: Column(
                        children: [
                          UnifiedText(
                            'v1.0.0+23 • SECURE NEURAL NETWORK',
                            style: UnifiedTypography.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: UnifiedSpacing.sm),
                          UnifiedText(
                            'Powered by Advanced AI • Privacy First',
                            style: UnifiedTypography.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
