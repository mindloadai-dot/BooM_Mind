import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/onboarding_service.dart';
import 'package:mindload/theme.dart';

/// Enhanced Onboarding Service
/// Provides welcoming onboarding for new users with persistence and user control
class EnhancedOnboardingService {
  static final EnhancedOnboardingService _instance = EnhancedOnboardingService._internal();
  factory EnhancedOnboardingService() => _instance;
  EnhancedOnboardingService._internal();

  // SharedPreferences keys
  static const String _welcomeDialogShownKey = 'welcome_dialog_shown';
  static const String _welcomeDialogNeverShowKey = 'welcome_dialog_never_show';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _firstLaunchDateKey = 'first_launch_date';
  static const String _lastWelcomeDialogDateKey = 'last_welcome_dialog_date';

  /// Check if this is the first time the app is launched
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_firstLaunchDateKey);
  }

  /// Check if welcome dialog should be shown
  Future<bool> shouldShowWelcomeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Never show if user explicitly chose to never see again
    if (prefs.getBool(_welcomeDialogNeverShowKey) ?? false) {
      return false;
    }
    
    // Show if never shown before
    if (!(prefs.getBool(_welcomeDialogShownKey) ?? false)) {
      return true;
    }
    
    // Show if it's been more than 7 days since last shown (for returning users)
    final lastShown = prefs.getString(_lastWelcomeDialogDateKey);
    if (lastShown != null) {
      try {
        final lastDate = DateTime.parse(lastShown);
        final daysSinceLastShown = DateTime.now().difference(lastDate).inDays;
        return daysSinceLastShown >= 7;
      } catch (e) {
        // If date parsing fails, show the dialog
        return true;
      }
    }
    
    return false;
  }

  /// Mark welcome dialog as shown
  Future<void> markWelcomeDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeDialogShownKey, true);
    await prefs.setString(_lastWelcomeDialogDateKey, DateTime.now().toIso8601String());
    
    // Set first launch date if not already set
    if (!prefs.containsKey(_firstLaunchDateKey)) {
      await prefs.setString(_firstLaunchDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Mark welcome dialog to never show again
  Future<void> markWelcomeDialogNeverShow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeDialogNeverShowKey, true);
    await prefs.setBool(_welcomeDialogShownKey, true);
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    
    // Also mark the welcome dialog as shown
    await markWelcomeDialogShown();
  }

  /// Reset all onboarding preferences (for testing or user request)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeDialogShownKey);
    await prefs.remove(_welcomeDialogNeverShowKey);
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_lastWelcomeDialogDateKey);
    // Don't remove first launch date as it's useful for analytics
  }

  /// Get first launch date
  Future<DateTime?> getFirstLaunchDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_firstLaunchDateKey);
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get days since first launch
  Future<int> getDaysSinceFirstLaunch() async {
    final firstLaunch = await getFirstLaunchDate();
    if (firstLaunch != null) {
      return DateTime.now().difference(firstLaunch).inDays;
    }
    return 0;
  }

  /// Show welcome dialog if needed
  Future<void> showWelcomeDialogIfNeeded(BuildContext context) async {
    if (await shouldShowWelcomeDialog()) {
      if (context.mounted) {
        await showWelcomeDialog(context);
      }
    }
  }

  /// Show the welcome dialog
  Future<void> showWelcomeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WelcomeDialog(),
    );
  }

  /// Show onboarding if needed (integrates with existing OnboardingService)
  Future<void> showOnboardingIfNeeded(BuildContext context) async {
    // First check if we should show the welcome dialog
    if (await shouldShowWelcomeDialog()) {
      if (context.mounted) {
        await showWelcomeDialog(context);
      }
    }
    
    // Then check if we should show the full onboarding
    if (!await isOnboardingCompleted()) {
      if (context.mounted) {
        await OnboardingService().showOnboardingModal(context);
      }
    }
  }

  // Static method to initialize the service
  static Future<void> initialize() async {
    // Perform any necessary initialization
    // For now, this is a no-op method
    return Future.value();
  }
}

/// Welcome Dialog
/// A welcoming dialog for new users with options to close or never show again
class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({super.key});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _iconController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Staggered animation start
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _iconController.forward();
        // Start continuous glow animation
        _glowController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _closeDialog() async {
    await EnhancedOnboardingService().markWelcomeDialogShown();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _neverShowAgain() async {
    await EnhancedOnboardingService().markWelcomeDialogNeverShow();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;
    
    return Material(
      color: tokens.overlayDim,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 16 : 20,
                  vertical: isVerySmallScreen ? 20 : (isSmallScreen ? 40 : 60),
                ),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: isVerySmallScreen 
                      ? screenSize.height * 0.9 
                      : (isSmallScreen ? screenSize.height * 0.85 : 650),
                  minHeight: isVerySmallScreen ? 400 : 500,
                ),
                                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: tokens.overlayDim.withValues(alpha: 0.5),
                      blurRadius: 60,
                      offset: const Offset(0, 30),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Header with gradient
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 28)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              tokens.primary,
                              tokens.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Animated MindLoad logo with glow effect
                            ScaleTransition(
                              scale: _iconAnimation,
                              child: AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: isVerySmallScreen ? 80 : (isSmallScreen ? 90 : 110),
                                    height: isVerySmallScreen ? 80 : (isSmallScreen ? 90 : 110),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        // Outer glow effect
                                        BoxShadow(
                                          color: tokens.primary.withValues(alpha: 0.4 * _glowAnimation.value),
                                          blurRadius: 30 * _glowAnimation.value,
                                          spreadRadius: 8 * _glowAnimation.value,
                                        ),
                                        // Inner glow effect
                                        BoxShadow(
                                          color: tokens.textInverse.withValues(alpha: 0.3 * _glowAnimation.value),
                                          blurRadius: 15 * _glowAnimation.value,
                                          spreadRadius: 2 * _glowAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/Brain_logo.png',
                                          width: isVerySmallScreen ? 50 : (isSmallScreen ? 60 : 75),
                                          height: isVerySmallScreen ? 50 : (isSmallScreen ? 60 : 75),
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback to brain icon if logo fails to load
                                            return Icon(
                                              Icons.psychology_rounded,
                                              size: isVerySmallScreen ? 35 : (isSmallScreen ? 42 : 50),
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
                            Flexible(
                              child: Text(
                                'Welcome to MindLoad!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            SizedBox(height: isVerySmallScreen ? 4 : (isSmallScreen ? 6 : 8)),
                            Flexible(
                              child: Text(
                                'Your AI Study Companion',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 14 : 16),
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content with better spacing and overflow handling
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  'Transform your learning with powerful AI features:',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 16),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                  maxLines: null,
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
                              
                              // Enhanced feature highlights with animations
                              ..._buildAnimatedFeatures(isVerySmallScreen, isSmallScreen),
                            ],
                          ),
                        ),
                      ),

                      // Enhanced action buttons
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
                          isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20),
                          isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
                          isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Primary action button with animation
                            SizedBox(
                              width: double.infinity,
                              height: isVerySmallScreen ? 44 : (isSmallScreen ? 50 : 56),
                              child: ElevatedButton(
                                onPressed: _closeDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.rocket_launch_rounded,
                                      size: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Get Started',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 16),
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),
                            
                            // Secondary action button
                            SizedBox(
                              width: double.infinity,
                              height: isVerySmallScreen ? 40 : (isSmallScreen ? 44 : 48),
                              child: TextButton(
                                onPressed: _neverShowAgain,
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Flexible(
                                  child: Text(
                                    'Never show again',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.underline,
                                      fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
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
      ),
    );
  }

  List<Widget> _buildAnimatedFeatures(bool isVerySmallScreen, bool isSmallScreen) {
    final features = [
      _FeatureData(
        icon: Icons.picture_as_pdf_rounded,
        title: 'PDF Upload & Processing',
        description: isVerySmallScreen 
            ? 'Upload PDFs and transform them into study materials'
            : 'Upload PDFs and transform them into interactive study materials instantly',
        color: Colors.red.shade400,
        delay: 0,
      ),
      _FeatureData(
        icon: Icons.play_circle_filled_rounded,
        title: 'YouTube Integration',
        description: isVerySmallScreen
            ? 'Convert YouTube videos into flashcards automatically'
            : 'Convert YouTube videos into flashcards and quizzes automatically',
        color: Colors.blue.shade400,
        delay: 200,
      ),
      _FeatureData(
        icon: Icons.auto_awesome_rounded,
        title: 'AI-Powered Learning',
        description: isVerySmallScreen
            ? 'Smart content generation with GPT-4 technology'
            : 'Smart content generation with advanced GPT-4 technology',
        color: Colors.purple.shade400,
        delay: 400,
      ),
      _FeatureData(
        icon: Icons.psychology_rounded,
        title: 'Smart Flashcards',
        description: isVerySmallScreen
            ? 'Adaptive learning with spaced repetition'
            : 'Adaptive learning with spaced repetition algorithms',
        color: Colors.green.shade400,
        delay: 600,
      ),
      _FeatureData(
        icon: Icons.flash_on_rounded,
        title: 'Ultra Mode',
        description: isVerySmallScreen
            ? 'Distraction-free study with focus tools'
            : 'Distraction-free study with binaural beats and focus tools',
        color: Colors.orange.shade400,
        delay: 800,
      ),
    ];

    return features.asMap().entries.map((entry) {
      final feature = entry.value;
      return AnimatedBuilder(
        animation: _slideController,
        builder: (context, child) {
          final animationValue = Curves.easeOutCubic.transform(
            (_slideController.value - (feature.delay / 1000)).clamp(0.0, 1.0),
          );
          return Transform.translate(
            offset: Offset(0, 30 * (1 - animationValue)),
            child: Opacity(
              opacity: animationValue,
              child: Padding(
                padding: EdgeInsets.only(bottom: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
                child: _buildEnhancedFeatureHighlight(
                  feature.icon,
                  feature.title,
                  feature.description,
                  feature.color,
                  isVerySmallScreen,
                  isSmallScreen,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildEnhancedFeatureHighlight(
    IconData icon,
    String title,
    String description,
    Color accentColor,
    bool isVerySmallScreen,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
            ),
          ),
          SizedBox(width: isVerySmallScreen ? 12 : (isSmallScreen ? 14 : 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isVerySmallScreen ? 13 : (isSmallScreen ? 14 : 15),
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6)),
                Flexible(
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3,
                      fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(IconData icon, String title, String description) {
    final tokens = ThemeManager.instance.currentTokens;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: tokens.primary,
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
                  fontWeight: FontWeight.bold,
                  color: tokens.textEmphasis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Feature data model for welcome dialog
class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final int delay;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delay,
  });
}
