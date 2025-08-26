import 'package:flutter/material.dart';
import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/widgets/brand_mark.dart';
import 'package:mindload/theme.dart';

class SimpleWelcomeScreen extends StatefulWidget {
  const SimpleWelcomeScreen({super.key});

  @override
  State<SimpleWelcomeScreen> createState() => _SimpleWelcomeScreenState();
}

class _SimpleWelcomeScreenState extends State<SimpleWelcomeScreen> with TickerProviderStateMixin {
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
        pageBuilder: (context, animation, secondaryAnimation) => const SocialAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildFeatureHighlights(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'AI-POWERED STUDY ASSISTANT',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            context,
            Icons.description_rounded,
            'TEXT & PDF',
            'Convert documents into study materials',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            context,
            Icons.play_circle_filled_rounded,
            'YOUTUBE VIDEOS',
            'Transform video content into quizzes',
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            context,
            Icons.psychology_rounded,
            'SMART AI',
            'Adaptive learning with GPT-4 technology',
          ),
          const SizedBox(height: 12),
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

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 48).clamp(0.0, double.infinity),
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
                              
                              const SizedBox(height: 48),
                              
                              // Feature highlights
                              _buildFeatureHighlights(context),
                              
                              const SizedBox(height: 48),
                              
                              // Get started button
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _navigateToAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tokens.primary,
                                    foregroundColor: tokens.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 8,
                                    shadowColor: tokens.primary.withValues(alpha: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.rocket_launch, size: 24),
                                      const SizedBox(width: 16),
                                      Text(
                                        'LAUNCH APP',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: tokens.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottom info
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        children: [
                          Text(
                            'v1.0.0 • SECURE NEURAL NETWORK',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Powered by Advanced AI • Privacy First',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha:  0.7),
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