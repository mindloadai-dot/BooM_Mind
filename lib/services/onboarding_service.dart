import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/config/pricing_config.dart';
import 'package:mindload/theme.dart';

/// Onboarding Service
/// Handles first-run onboarding for new users
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _onboardingKey = 'onboarding_completed';
  static const String _welcomeTokensKey = 'welcome_tokens_claimed';

  /// Check if onboarding has been completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Check if welcome tokens have been claimed
  Future<bool> areWelcomeTokensClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeTokensKey) ?? false;
  }

  /// Mark welcome tokens as claimed
  Future<void> claimWelcomeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeTokensKey, true);
  }

  /// Reset onboarding (for testing or user request)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_welcomeTokensKey);
  }

  /// Get welcome tokens amount for free tier
  int getWelcomeTokens() {
    return PLAN_DEFS[PlanId.free]!.welcomeTokens;
  }

  /// Show onboarding if needed
  Future<void> showOnboardingIfNeeded(BuildContext context) async {
    if (!await isOnboardingCompleted()) {
      if (context.mounted) {
        await showOnboardingModal(context);
      }
    }
  }

  /// Show the onboarding modal
  Future<void> showOnboardingModal(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OnboardingModal(),
    );
  }
}

/// Onboarding Modal
/// 3-screen modal explaining Mindload, MindLoad Tokens, and Ultra Mode
class OnboardingModal extends StatefulWidget {
  const OnboardingModal({super.key});

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'How Mindload Works',
      description: 'Paste text or a YouTube link, and AI generates comprehensive study materials for you.',
      icon: Icons.auto_awesome,
      color: Colors.blue,
      image: 'assets/images/onboarding_1.png', // Add your image assets
    ),
    OnboardingPage(
      title: 'MindLoad Tokens',
      description: 'We always estimate first, then you must long-press to confirm and run. Your tokens are your currency for all operations.',
      icon: Icons.token,
      color: Colors.green,
      image: 'assets/images/onboarding_2.png',
    ),
    OnboardingPage(
      title: 'Ultra Mode',
      description: 'Available on paid tiers only. Ultra Mode provides distraction-free, high-focus study sessions with advanced features.',
      icon: Icons.flash_on,
      color: Colors.orange,
      image: 'assets/images/onboarding_3.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await OnboardingService().completeOnboarding();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.maxFinite,
          height: 600,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: tokens.overlayDim,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with progress indicator
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_currentPage + 1} of ${_pages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildPage(page);
                  },
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox(width: 80),

                    // Next/Complete button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
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

  Widget _buildPage(OnboardingPage page) {
    final tokens = ThemeManager.instance.currentTokens;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 50,
              color: page.color,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textEmphasis,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: tokens.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Image placeholder (replace with actual assets)
          const SizedBox(height: 32),
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: page.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 40,
                color: page.color.withValues(alpha: 0.5),
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
  final String description;
  final IconData icon;
  final Color color;
  final String image;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.image,
  });
}
