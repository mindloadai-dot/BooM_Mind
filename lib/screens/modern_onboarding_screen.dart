import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/theme.dart';
import 'dart:math' as math;

/// Modern Onboarding Screen with Enhanced UX
/// Features smooth animations, video backgrounds, and engaging interactions
class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen>
    with TickerProviderStateMixin {
  // Controllers
  late PageController _pageController;
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _backgroundAnimation;

  // State
  int _currentPage = 0;
  bool _videoInitialized = false;
  bool _isTransitioning = false;
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _nicknameValid = false;

  // Onboarding pages data
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Welcome to MindLoad',
      subtitle: 'Your AI-Powered Learning Companion',
      description:
          'Transform any content into personalized study materials with the power of AI',
      icon: Icons.rocket_launch_rounded,
      primaryColor: const Color(0xFF6366F1),
      secondaryColor: const Color(0xFF8B5CF6),
      features: [
        'Smart content analysis',
        'Personalized learning paths',
        'AI-generated study materials',
      ],
    ),
    OnboardingPageData(
      title: 'Personalize Your Journey',
      subtitle: 'Tell us about yourself',
      description:
          'Set your nickname and preferences for a tailored experience',
      icon: Icons.person_outline_rounded,
      primaryColor: const Color(0xFF8B5CF6),
      secondaryColor: const Color(0xFFEC4899),
      isInteractive: true,
    ),
    OnboardingPageData(
      title: 'Intelligent Study Tools',
      subtitle: 'Learn Smarter, Not Harder',
      description:
          'Generate flashcards, quizzes, and summaries from any text or video',
      icon: Icons.auto_awesome_rounded,
      primaryColor: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF14B8A6),
      features: [
        'YouTube video analysis',
        'PDF & document processing',
        'Interactive flashcards',
        'Adaptive quizzes',
      ],
    ),
    OnboardingPageData(
      title: 'Track Your Progress',
      subtitle: 'Achieve Your Goals',
      description:
          'Monitor your learning journey with detailed analytics and achievements',
      icon: Icons.insights_rounded,
      primaryColor: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFEF4444),
      features: [
        'Learning analytics',
        'Achievement system',
        'Progress tracking',
        'Study streaks',
      ],
    ),
    OnboardingPageData(
      title: 'Ready to Begin?',
      subtitle: 'Your Learning Adventure Awaits',
      description:
          'Join thousands of learners who are already transforming their study experience',
      icon: Icons.celebration_rounded,
      primaryColor: const Color(0xFF6366F1),
      secondaryColor: const Color(0xFF10B981),
      isFinal: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeControllers() {
    _pageController = PageController(viewportFraction: 1.0);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeAnimations() {
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotateController);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);

    // Start initial animations with proper sequencing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scaleController.forward();
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _slideController.forward();
              }
            });
          }
        });
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.asset('assets/images/logo.mp4.mp4');
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0);
      await _videoController.play();
      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  @override
  void dispose() {
    // Stop all animations before disposing
    _fadeController.stop();
    _scaleController.stop();
    _slideController.stop();
    _rotateController.stop();
    _pulseController.stop();
    _backgroundController.stop();

    // Dispose controllers
    _pageController.dispose();
    _videoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isTransitioning) return;

    if (_currentPage == 1) {
      // Validate nickname on page 2
      if (!_formKey.currentState!.validate()) {
        HapticFeedbackService().error();
        return;
      }
      _saveNickname();
    }

    if (_currentPage < _pages.length - 1) {
      _animatePageTransition(() {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_isTransitioning || _currentPage == 0) return;

    _animatePageTransition(() {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _animatePageTransition(VoidCallback transition) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    HapticFeedbackService().lightImpact();

    // Reset animations to prevent conflicts
    _fadeController.reset();
    _scaleController.reset();
    _slideController.reset();

    _fadeController.reverse().then((_) {
      if (mounted) {
        transition();
        // Ensure smooth forward animation
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _fadeController.forward();
            _scaleController.forward();
            _slideController.forward();
            setState(() => _isTransitioning = false);
          }
        });
      }
    });
  }

  Future<void> _saveNickname() async {
    final userProfile = Provider.of<UserProfileService>(context, listen: false);
    await userProfile.updateNickname(_nicknameController.text.trim());

    final onboardingService =
        Provider.of<UnifiedOnboardingService>(context, listen: false);
    await onboardingService.markNicknameSet();
  }

  Future<void> _completeOnboarding() async {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    HapticFeedbackService().success();

    try {
      final onboardingService =
          Provider.of<UnifiedOnboardingService>(context, listen: false);
      await onboardingService.markFeaturesExplained();
      await onboardingService.completeOnboarding();

      if (mounted) {
        // Add a small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Skip Onboarding?'),
        content: const Text(
            'You can always access these features from settings. Are you sure you want to skip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Tour'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        _pages[_currentPage].primaryColor,
                        _pages[_currentPage].secondaryColor,
                        _backgroundAnimation.value,
                      )!
                          .withOpacity(0.1),
                      tokens.bg,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating particles effect
          ...List.generate(5, (index) => _buildFloatingParticle(index, size)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with skip button
                _buildHeader(tokens),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (mounted && !_isTransitioning) {
                        setState(() => _currentPage = index);
                        // Only trigger animations if not already transitioning
                        if (!_fadeController.isAnimating &&
                            !_scaleController.isAnimating &&
                            !_slideController.isAnimating) {
                          _fadeController.forward(from: 0);
                          _scaleController.forward(from: 0.8);
                          _slideController.forward(from: 0);
                        }
                      }
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      if (page.isInteractive) {
                        return _buildInteractivePage(page, tokens);
                      }
                      return _buildContentPage(page, tokens, index);
                    },
                  ),
                ),

                // Bottom navigation
                _buildBottomNavigation(tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress indicator
          Expanded(
            child: Row(
              children: List.generate(
                _pages.length,
                (index) => Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: index <= _currentPage
                          ? _pages[_currentPage].primaryColor
                          : tokens.borderMuted.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Skip button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentPage(
      OnboardingPageData page, SemanticTokens tokens, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon or video
              if (index == 0 && _videoInitialized)
                _buildVideoWidget()
              else
                _buildAnimatedIcon(page),

              const SizedBox(height: 40),

              // Title
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  page.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                page.subtitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: page.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                page.description,
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Features list
              if (page.features != null) ...[
                const SizedBox(height: 32),
                ...page.features!
                    .map((feature) => _buildFeatureItem(feature, page, tokens)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractivePage(OnboardingPageData page, SemanticTokens tokens) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedIcon(page),
              const SizedBox(height: 40),

              Text(
                page.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                page.subtitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: page.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Nickname input form
              Form(
                key: _formKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextFormField(
                    controller: _nicknameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 18,
                      color: tokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Your Nickname',
                      hintText: 'Enter your preferred name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: page.primaryColor,
                      ),
                      filled: true,
                      fillColor: tokens.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: page.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: tokens.error,
                          width: 2,
                        ),
                      ),
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
                      setState(() {
                        _nicknameValid = value.trim().length >= 2 &&
                            value.trim().length <= 20;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Helper text
              Text(
                'This name will be used to personalize your experience',
                style: TextStyle(
                  fontSize: 14,
                  color: tokens.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _pages[_currentPage].primaryColor.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(OnboardingPageData page) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: page.isFinal ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.primaryColor,
                  page.secondaryColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(
      String feature, OnboardingPageData page, SemanticTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.primaryColor.withOpacity(0.8),
                  page.secondaryColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 16,
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(SemanticTokens tokens) {
    final isLastPage = _currentPage == _pages.length - 1;
    final canProceed = _currentPage != 1 || _nicknameValid;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          AnimatedOpacity(
            opacity: _currentPage > 0 ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: IconButton(
              onPressed: _currentPage > 0 ? _previousPage : null,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: tokens.textSecondary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: tokens.surface,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          // Page indicators
          Row(
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: index == _currentPage
                      ? _pages[_currentPage].primaryColor
                      : tokens.borderMuted.withOpacity(0.3),
                ),
              ),
            ),
          ),

          // Next/Complete button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isLastPage ? _pulseAnimation.value : 1.0,
                child: ElevatedButton(
                  onPressed: canProceed ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].primaryColor,
                    disabledBackgroundColor: tokens.borderMuted,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLastPage ? 32 : 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isLastPage ? 8 : 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLastPage) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index, Size size) {
    final random = math.Random(index);
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;

    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        final offsetX = math.sin(_rotateAnimation.value + index) * 20;
        final offsetY = math.cos(_rotateAnimation.value + index) * 20;

        return Positioned(
          left: startX + offsetX,
          top: startY + offsetY,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _pages[_currentPage].primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// Data model for onboarding pages
class OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String>? features;
  final bool isInteractive;
  final bool isFinal;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.features,
    this.isInteractive = false,
    this.isFinal = false,
  });
}
