import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/theme.dart';

/// Unified Onboarding Screen
/// Beautiful, welcoming onboarding that users complete once and never see again
class UnifiedOnboardingScreen extends StatefulWidget {
  const UnifiedOnboardingScreen({super.key});

  @override
  State<UnifiedOnboardingScreen> createState() => _UnifiedOnboardingScreenState();
}

class _UnifiedOnboardingScreenState extends State<UnifiedOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;

  int _currentPage = 0;
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _nicknameFormKey = GlobalKey<FormState>();

  // Beautiful onboarding pages
  final List<OnboardingPage> _onboardingPages = [
    OnboardingPage(
      title: 'Welcome to MindLoad! 🧠✨',
      subtitle: 'Your AI-Powered Study Companion',
      description: 'Transform any text or YouTube video into comprehensive study materials. Let\'s get you started!',
      icon: Icons.auto_awesome,
      color: Colors.blue,
      gradient: [Colors.blue, Colors.blue.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
    OnboardingPage(
      title: 'Personalize Your Experience 🎯',
      subtitle: 'Set Your Nickname',
      description: 'Choose a nickname that will be used throughout the app for a personalized learning journey.',
      icon: Icons.person_add,
      color: Colors.purple,
      gradient: [Colors.purple, Colors.purple.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
    OnboardingPage(
      title: 'AI-Powered Learning 🚀',
      subtitle: 'Smart Study Materials',
      description: 'Upload documents, paste text, or analyze YouTube videos. Our AI creates flashcards, quizzes, and summaries.',
      icon: Icons.psychology,
      color: Colors.green,
      gradient: [Colors.green, Colors.green.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
    OnboardingPage(
      title: 'MindLoad Tokens 💎',
      subtitle: 'Fair & Transparent Pricing',
      description: 'Start with free tokens! We always estimate first, then you confirm with a long-press. No surprises.',
      icon: Icons.token,
      color: Colors.orange,
      gradient: [Colors.orange, Colors.orange.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
    OnboardingPage(
      title: 'Ultra Mode & Premium Features ⚡',
      subtitle: 'Advanced Learning Tools',
      description: 'Unlock distraction-free study sessions, audio tools, and advanced analytics with premium plans.',
      icon: Icons.flash_on,
      color: Colors.red,
      gradient: [Colors.red, Colors.red.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
    OnboardingPage(
      title: 'Smart Notifications 🔔',
      subtitle: 'Stay on Track',
      description: 'Personalized reminders, progress tracking, and quiet hours to optimize your study sessions.',
      icon: Icons.notifications_active,
      color: Colors.teal,
      gradient: [Colors.teal, Colors.teal.shade700],
      image: 'assets/images/Brain_logo.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _progressController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );

      // Mark features as explained when user moves to next page
      if (_currentPage == 2) {
        UnifiedOnboardingService().markFeaturesExplained();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _saveNickname() async {
    if (!_nicknameFormKey.currentState!.validate()) return;

    try {
      final nickname = _nicknameController.text.trim();
      await UserProfileService.instance.updateNickname(nickname);
      await UnifiedOnboardingService().markNicknameSet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $nickname! 🎉'),
            backgroundColor: context.tokens.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Navigate to the next page after saving nickname
        _nextPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save nickname: $e'),
            backgroundColor: context.tokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await UnifiedOnboardingService().completeOnboarding();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: context.tokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onboardingService = Provider.of<UnifiedOnboardingService>(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Beautiful header with progress
            _buildHeader(tokens, onboardingService),

            // Main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  if (index == 1) {
                    return _buildNicknamePage(tokens);
                  } else {
                    return _buildOnboardingPage(tokens, _onboardingPages[index]);
                  }
                },
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(tokens, onboardingService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens, UnifiedOnboardingService onboardingService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value * onboardingService.onboardingProgress,
                      backgroundColor: tokens.outline.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_currentPage / (_onboardingPages.length - 1) * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: tokens.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingPages.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPage ? tokens.primary : tokens.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknamePage(SemanticTokens tokens) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.primary.withOpacity(0.3),
                          blurRadius: 20 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/Brain_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Text(
                'Personalize Your Experience',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Choose a nickname that will be used throughout the app for a personalized learning journey.',
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Nickname form
              Form(
                key: _nicknameFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'Enter your preferred name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: tokens.surface,
                        prefixIcon: Icon(Icons.person, color: tokens.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a nickname';
                        }
                        if (value.trim().length < 2) {
                          return 'Nickname must be at least 2 characters';
                        }
                        if (value.trim().length > 20) {
                          return 'Nickname must be less than 20 characters';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveNickname(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveNickname,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.primary,
                          foregroundColor: tokens.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Save Nickname',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildOnboardingPage(SemanticTokens tokens, OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                page.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              if (page.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  page.subtitle,
                  style: TextStyle(
                    fontSize: 18,
                    color: tokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              Text(
                page.description,
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(SemanticTokens tokens, UnifiedOnboardingService onboardingService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.primary,
                  side: BorderSide(color: tokens.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: 16),

          // Next/Complete button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentPage == _onboardingPages.length - 1
                  ? (onboardingService.canCompleteOnboarding ? _completeOnboarding : null)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                _currentPage == _onboardingPages.length - 1 ? 'Get Started!' : 'Next',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Onboarding page model
class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String image;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.image,
  });
}
