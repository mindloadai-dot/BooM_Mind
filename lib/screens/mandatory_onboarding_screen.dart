import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mandatory_onboarding_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/theme.dart';

/// Mandatory onboarding screen that users MUST complete before using the app
/// This screen cannot be skipped and ensures users understand the app and set up their profile
class MandatoryOnboardingScreen extends StatefulWidget {
  const MandatoryOnboardingScreen({super.key});

  @override
  State<MandatoryOnboardingScreen> createState() =>
      _MandatoryOnboardingScreenState();
}

class _MandatoryOnboardingScreenState extends State<MandatoryOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  int _currentPage = 0;
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _nicknameFormKey = GlobalKey<FormState>();

  // Feature pages
  final List<FeaturePage> _featurePages = [
    FeaturePage(
      title: '🎯 Personalized Learning Experience',
      description:
          'Set up your nickname to get personalized notifications, study reminders, and AI interactions throughout the app.',
      icon: Icons.person_add,
      color: null,
      details: [
        'Personalized notifications with your chosen style',
        'Custom study reminders using your nickname',
        'AI interactions that know you by name',
        'Progress tracking personalized to you',
      ],
    ),
    FeaturePage(
      title: '🧠 AI-Powered Study Materials',
      description:
          'Transform any text, document, or YouTube video into comprehensive study materials with our advanced AI.',
      icon: Icons.auto_awesome,
      color: null,
      details: [
        'Upload text, PDFs, or Word documents',
        'Paste YouTube links for video analysis',
        'Generate study guides, flashcards, and quizzes',
        'AI-powered content summarization',
      ],
    ),
    FeaturePage(
      title: '⚡ MindLoad Tokens System',
      description:
          'Use tokens to access AI features. We always estimate first, then you confirm with a long-press to run.',
      icon: Icons.token,
      color: Colors.green,
      details: [
        'Free tokens for new users',
        'Pay-per-use token system',
        'Always see costs before confirming',
        'Long-press to confirm and run',
      ],
    ),
    FeaturePage(
      title: '🚀 Ultra Mode & Advanced Features',
      description:
          'Access distraction-free study sessions, advanced audio features, and premium learning tools.',
      icon: Icons.flash_on,
      color: Colors.orange,
      details: [
        'Distraction-free study environment',
        'Advanced audio and focus tools',
        'Premium study analytics',
        'Custom study session planning',
      ],
    ),
    FeaturePage(
      title: '🔔 Smart Notification System',
      description:
          'Choose your notification style: Mindful, Coach, Tough Love, or Cram - each with unique personality.',
      icon: Icons.notifications_active,
      color: Colors.red,
      details: [
        '4 distinct notification personalities',
        'Personalized with your nickname',
        'Smart quiet hours management',
        'Context-aware study reminders',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _pageController = PageController();

    // Pre-fill nickname if user already has one
    final currentNickname = UserProfileService.instance.nickname;
    if (currentNickname != null && currentNickname.isNotEmpty) {
      _nicknameController.text = currentNickname;
    }
  }

  void _initializeAnimations() {
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _featurePages.length - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // Mark features as explained when user moves to next page
      if (_currentPage == 1) {
        // First feature page - mark nickname as explained
        MandatoryOnboardingService.instance.markFeaturesExplained();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveNickname() async {
    if (!_nicknameFormKey.currentState!.validate()) return;

    try {
      final nickname = _nicknameController.text.trim();
      await UserProfileService.instance.updateNickname(nickname);
      await MandatoryOnboardingService.instance.markNicknameSet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $nickname! 🎉'),
            backgroundColor: context.tokens.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save nickname: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      await MandatoryOnboardingService.instance.completeOnboarding();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onboardingService = Provider.of<MandatoryOnboardingService>(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
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
                itemCount: _featurePages.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildNicknamePage(tokens);
                  } else {
                    return _buildFeaturePage(tokens, _featurePages[index - 1]);
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

  Widget _buildHeader(
      SemanticTokens tokens, MandatoryOnboardingService onboardingService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // App logo and title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Brain_logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                'MindLoad',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.brandTitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress indicator
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of ${_featurePages.length}',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${((_currentPage + 1) / _featurePages.length * 100).round()}%',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentPage + 1) / _featurePages.length,
                backgroundColor: tokens.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                minHeight: 6,
              ),
            ],
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
              // Icon and title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.person_add,
                  size: 40,
                  color: tokens.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Welcome to MindLoad! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Let\'s personalize your learning experience by setting up your nickname.',
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textSecondary,
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
                        labelText: 'Your Nickname',
                        hintText: 'Enter your preferred name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.person, color: tokens.primary),
                        filled: true,
                        fillColor: tokens.surface,
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
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    // Preview
                    if (_nicknameController.text.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.primary.withOpacity(0.1),
                          border: Border.all(color: tokens.primary),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.preview, color: tokens.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'ll be called "${_nicknameController.text.trim()}" throughout the app',
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nicknameController.text.trim().isNotEmpty
                            ? _saveNickname
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.primary,
                          foregroundColor: tokens.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Nickname',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildFeaturePage(SemanticTokens tokens, FeaturePage feature) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Feature icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (feature.color ?? tokens.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  feature.icon,
                  size: 40,
                  color: feature.color ?? tokens.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                feature.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                feature.description,
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature details
              Expanded(
                child: ListView.builder(
                  itemCount: feature.details.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: feature.color ?? tokens.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              feature.details[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
      SemanticTokens tokens, MandatoryOnboardingService onboardingService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Previous button
          if (_currentPage > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Next/Complete button
          Expanded(
            flex: _currentPage > 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _currentPage == _featurePages.length - 1
                  ? (onboardingService.canCompleteOnboarding
                      ? _completeOnboarding
                      : null)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentPage == _featurePages.length - 1
                    ? 'Get Started!'
                    : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature page data model
class FeaturePage {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final List<String> details;

  FeaturePage({
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    required this.details,
  });
}
