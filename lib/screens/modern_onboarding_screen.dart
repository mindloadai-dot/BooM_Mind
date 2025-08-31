import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/services/auth_service.dart';
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

  // New enhanced animation controllers
  late AnimationController _bounceController;
  late AnimationController _flipController;
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late AnimationController _morphController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _backgroundAnimation;

  // Enhanced animations
  late Animation<double> _bounceAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _morphAnimation;

  // State
  int _currentPage = 0;
  int _lastPageIndex = 0;
  bool _videoInitialized = false;
  bool _isTransitioning = false;
  final TextEditingController _nicknameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _nicknameValid = false;
  AppTheme _selectedTheme = AppTheme.classic;

  // Transition direction tracking
  bool _isForwardTransition = true;

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
      transitionType: TransitionType.morph,
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
      transitionType: TransitionType.morph,
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
      transitionType: TransitionType.morph,
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
      transitionType: TransitionType.morph,
    ),
    OnboardingPageData(
      title: 'Choose Your Style',
      subtitle: 'Personalize Your Experience',
      description:
          'Select from multiple beautiful themes to match your mood and preferences',
      icon: Icons.palette_rounded,
      primaryColor: const Color(0xFF8B5CF6),
      secondaryColor: const Color(0xFFEC4899),
      features: [
        '7 unique themes available',
        'Classic, Matrix, Retro styles',
        'Cyber Neon & Purple Neon',
        'Dark Mode & Minimal options',
      ],
      isThemeShowcase: true,
      transitionType: TransitionType.morph,
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
      transitionType: TransitionType.morph,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // 🔐 CRITICAL: Authentication check FIRST - onboarding requires authenticated user
    _checkAuthentication();

    // 🎯 CRITICAL: Check if onboarding was already completed (safety check)
    _checkOnboardingStatus();

    _initializeControllers();
    _initializeAnimations();
    _initializeVideo();

    // Performance optimization: Reduce animation frequency on lower-end devices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _optimizeForPerformance();
      }
    });
  }

  void _checkAuthentication() {
    // 🔐 CRITICAL: Ensure user is authenticated before showing onboarding - NO EXCEPTIONS!
    final authService = AuthService.instance;
    if (!authService.isAuthenticated || authService.currentUser == null) {
      debugPrint(
          '🔐 OnboardingScreen: User not authenticated - redirecting to SocialAuthScreen');
      // Redirect to authentication screen immediately if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/social-auth');
      });
      return;
    }

    debugPrint(
        '🔐 OnboardingScreen: User authenticated: ${authService.currentUser!.email}');
  }

  void _checkOnboardingStatus() {
    // 🎯 SAFETY CHECK: If onboarding was already completed, redirect immediately
    // This prevents any potential bypass or duplicate showing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final onboardingService =
            Provider.of<UnifiedOnboardingService>(context, listen: false);
        await onboardingService.initialize();

        if (!onboardingService.needsOnboarding) {
          debugPrint(
              '🎯 OnboardingScreen: SAFETY CHECK - Onboarding already completed!');
          debugPrint(
              '   Redirecting to home immediately to prevent duplicate showing');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
          return;
        }

        debugPrint(
            '🎯 OnboardingScreen: First time - showing onboarding as expected');
      } catch (e) {
        debugPrint('⚠️ OnboardingScreen: Error checking onboarding status: $e');
      }
    });
  }

  void _optimizeForPerformance() {
    // More aggressive performance optimization to reduce ImageReader_JNI warnings
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (devicePixelRatio < 2.0) {
      // Lower-end device - significantly reduce animation complexity
      _waveController.duration = const Duration(milliseconds: 4000);
      _shimmerController.duration = const Duration(milliseconds: 5000);
      _rotateController.duration = const Duration(seconds: 30);
      _pulseController.duration = const Duration(seconds: 3);
      _backgroundController.duration = const Duration(seconds: 15);
    } else if (devicePixelRatio < 3.0) {
      // Mid-range device - moderate reduction
      _waveController.duration = const Duration(milliseconds: 3000);
      _shimmerController.duration = const Duration(milliseconds: 4000);
      _rotateController.duration = const Duration(seconds: 25);
      _pulseController.duration = const Duration(seconds: 2);
      _backgroundController.duration = const Duration(seconds: 12);
    }

    // Reduce floating particles for all devices
    // This will be handled in the build method
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

    // Enhanced controllers (reduced for better performance)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Removed particle controller to reduce buffer usage

    // Note: Performance optimization will be applied in _optimizeForPerformance()
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

    // New enhanced animations
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    ));
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubic,
    ));

    // Start initial animations with proper sequencing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _startPageAnimations();
      }
    });
  }

  void _startPageAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _scaleController.forward();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _slideController.forward();
            _startTransitionSpecificAnimations();
          }
        });
      }
    });
  }

  void _startTransitionSpecificAnimations() {
    final currentPage = _pages[_currentPage];
    switch (currentPage.transitionType) {
      case TransitionType.bounce:
        _bounceController.forward();
        break;
      case TransitionType.flip:
        _flipController.forward();
        break;
      case TransitionType.morph:
        _morphController.forward();
        break;
      case TransitionType.zoom:
        _scaleController.forward();
        break;
      case TransitionType.slide:
        _slideController.forward();
        break;
      case TransitionType.fade:
        _fadeController.forward();
        break;
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.asset('assets/images/logo.mp4.mp4');
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0);

      // Performance optimization: Reduce video quality on lower-end devices
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      if (devicePixelRatio < 2.0) {
        // Lower-end device - reduce video quality to minimize buffer usage
        await _videoController.setPlaybackSpeed(0.8);
      }

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
    _bounceController.stop();
    _flipController.stop();
    _waveController.stop();
    _shimmerController.stop();
    _morphController.stop();

    // Dispose controllers
    _pageController.dispose();
    _videoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _bounceController.dispose();
    _flipController.dispose();
    _waveController.dispose();
    _shimmerController.dispose();
    _morphController.dispose();

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
      _isForwardTransition = true;
      _lastPageIndex = _currentPage;
      _animatePageTransition(() {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_isTransitioning || _currentPage == 0) return;

    _isForwardTransition = false;
    _lastPageIndex = _currentPage;
    _animatePageTransition(() {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _animatePageTransition(VoidCallback transition) {
    if (_isTransitioning) return;

    setState(() => _isTransitioning = true);
    HapticFeedbackService().lightImpact();

    // Reset all animations
    _resetAllAnimations();

    // Get current and next page transition types
    final currentPage = _pages[_currentPage];
    final nextPageIndex =
        _isForwardTransition ? _currentPage + 1 : _currentPage - 1;
    final nextPage = _pages[nextPageIndex];

    // Create dynamic transition based on page types
    _createDynamicTransition(currentPage, nextPage, transition);
  }

  void _resetAllAnimations() {
    _fadeController.reset();
    _scaleController.reset();
    _slideController.reset();
    _bounceController.reset();
    _flipController.reset();
    _morphController.reset();
  }

  void _createDynamicTransition(OnboardingPageData currentPage,
      OnboardingPageData nextPage, VoidCallback transition) {
    // Exit animation for current page
    _playExitAnimation(currentPage).then((_) {
      if (mounted) {
        // Execute page transition
        transition();

        // Update current page index
        setState(() {
          _currentPage =
              _isForwardTransition ? _currentPage + 1 : _currentPage - 1;
        });

        // Enter animation for new page
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _playEnterAnimation(nextPage);
            setState(() => _isTransitioning = false);
          }
        });
      }
    });
  }

  Future<void> _playExitAnimation(OnboardingPageData page) async {
    switch (page.transitionType) {
      case TransitionType.fade:
        await _fadeController.reverse();
        break;
      case TransitionType.slide:
        await _slideController.reverse();
        break;
      case TransitionType.zoom:
        await _scaleController.reverse();
        break;
      case TransitionType.flip:
        await _flipController.reverse();
        break;
      case TransitionType.bounce:
        await _bounceController.reverse();
        break;
      case TransitionType.morph:
        await _morphController.reverse();
        break;
    }
  }

  void _playEnterAnimation(OnboardingPageData page) {
    switch (page.transitionType) {
      case TransitionType.fade:
        _fadeController.forward();
        break;
      case TransitionType.slide:
        _slideController.forward();
        break;
      case TransitionType.zoom:
        _scaleController.forward();
        break;
      case TransitionType.flip:
        _flipController.forward();
        break;
      case TransitionType.bounce:
        _bounceController.forward();
        break;
      case TransitionType.morph:
        _morphController.forward();
        break;
    }
  }

  Future<void> _saveNickname() async {
    final userProfile = Provider.of<UserProfileService>(context, listen: false);
    await userProfile.updateNickname(_nicknameController.text.trim());

    final onboardingService =
        Provider.of<UnifiedOnboardingService>(context, listen: false);
    await onboardingService.markNicknameSet();
  }

  Future<void> _completeOnboarding() async {
    if (_isTransitioning || !mounted) return;

    setState(() => _isTransitioning = true);
    HapticFeedbackService().success();

    try {
      // Get service reference while widget is mounted
      if (!mounted) return;
      final onboardingService =
          Provider.of<UnifiedOnboardingService>(context, listen: false);

      await onboardingService.markFeaturesExplained();

      // Save the selected theme
      await ThemeManager.instance.setTheme(_selectedTheme);

      await onboardingService.completeOnboarding();

      if (mounted) {
        // Add a small delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 300));

        // Final check before navigation
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() => _isTransitioning = false);
      }
    }
  }

  void _selectTheme(AppTheme theme) {
    setState(() {
      _selectedTheme = theme;
    });

    // Apply theme immediately for preview
    ThemeManager.instance.setTheme(theme);
    HapticFeedbackService().lightImpact();

    if (kDebugMode) {
      debugPrint('🎨 Theme selected: ${theme.id}');
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

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.of(context).size;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isInteractivePage = _currentPage == 1; // Page 2 is interactive

    return Scaffold(
      // Enable resize behavior for keyboard handling
      resizeToAvoidBottomInset: true,
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

          // Floating particles effect (further reduced for better performance)
          // Hide particles when keyboard is visible to reduce visual clutter
          if (!isKeyboardVisible) ...[
            ...List.generate(
                MediaQuery.of(context).devicePixelRatio < 2.0
                    ? 1
                    : (MediaQuery.of(context).devicePixelRatio < 3.0 ? 2 : 3),
                (index) => _buildFloatingParticle(index, size)),
          ],

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
                        setState(() {
                          _lastPageIndex = _currentPage;
                          _currentPage = index;
                          _isForwardTransition = index > _lastPageIndex;
                        });

                        // Trigger page-specific animations
                        _startTransitionSpecificAnimations();
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

                // Bottom navigation - hide when keyboard is visible on interactive page
                if (!(isKeyboardVisible && isInteractivePage))
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
    return _buildTransitionWrapper(
      page,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom -
                200, // Account for header and bottom nav
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon or video - Always show video for page 1
              if (index == 0) _buildVideoWidget() else _buildAnimatedIcon(page),

              const SizedBox(height: 40),

              // Title with enhanced animation
              _buildAnimatedTitle(page, tokens),

              const SizedBox(height: 12),

              // Subtitle with wave animation
              _buildAnimatedSubtitle(page, tokens),

              const SizedBox(height: 24),

              // Description with shimmer effect
              _buildAnimatedDescription(page, tokens),

              // Theme showcase for theme page
              if (page.isThemeShowcase) ...[
                const SizedBox(height: 32),
                _buildThemeShowcase(tokens),
              ],

              // Features list with staggered animation
              if (page.features != null && !page.isThemeShowcase) ...[
                const SizedBox(height: 32),
                ...page.features!
                    .asMap()
                    .entries
                    .map((entry) => _buildAnimatedFeatureItem(
                          entry.value,
                          page,
                          tokens,
                          entry.key,
                        )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionWrapper(OnboardingPageData page,
      {required Widget child}) {
    switch (page.transitionType) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      case TransitionType.slide:
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      case TransitionType.zoom:
        return ScaleTransition(
          scale: _scaleAnimation,
          child: child,
        );
      case TransitionType.flip:
        return AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value * math.pi),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: child,
        );
      case TransitionType.bounce:
        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_bounceAnimation.value * 0.2),
              child: child,
            );
          },
          child: child,
        );
      case TransitionType.morph:
        return AnimatedBuilder(
          animation: _morphAnimation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_morphAnimation.value * 0.1)
                ..rotateY(_morphAnimation.value * 0.1),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: child,
        );
    }
  }

  Widget _buildAnimatedTitle(OnboardingPageData page, SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
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
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle(
      OnboardingPageData page, SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_waveAnimation.value * 2 * math.pi) * 3),
          child: Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: page.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDescription(
      OnboardingPageData page, SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tokens.textSecondary,
                page.primaryColor.withOpacity(0.8),
                tokens.textSecondary,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFeatureItem(String feature, OnboardingPageData page,
      SemanticTokens tokens, int index) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = (_waveAnimation.value + delay) % 1.0;

        return Transform.translate(
          offset: Offset(
            math.sin(animationValue * 2 * math.pi) * 2,
            math.cos(animationValue * 2 * math.pi) * 1,
          ),
          child: Opacity(
            opacity: 0.7 + (0.3 * math.sin(animationValue * 2 * math.pi)),
            child: _buildFeatureItem(feature, page, tokens),
          ),
        );
      },
    );
  }

  Widget _buildThemeShowcase(SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Theme grid with better layout
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate optimal grid layout based on available space
                  final screenHeight = MediaQuery.of(context).size.height;
                  final availableHeight =
                      screenHeight * 0.4; // Use 40% of screen height

                  return SizedBox(
                    height: availableHeight,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, // Slightly taller cards
                      children: [
                        _buildThemeCard(
                            'Classic',
                            'Clean & Professional',
                            Icons.style,
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                            AppTheme.classic),
                        _buildThemeCard(
                            'Matrix',
                            'Cyberpunk Style',
                            Icons.code,
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                            AppTheme.matrix),
                        _buildThemeCard(
                            'Retro',
                            'Vintage Vibes',
                            Icons.music_note,
                            const Color(0xFFF59E0B),
                            const Color(0xFFD97706),
                            AppTheme.retro),
                        _buildThemeCard(
                            'Cyber Neon',
                            'Futuristic Glow',
                            Icons.electric_bolt,
                            const Color(0xFFEC4899),
                            const Color(0xFFBE185D),
                            AppTheme.cyberNeon),
                        _buildThemeCard(
                            'Dark Mode',
                            'Easy on Eyes',
                            Icons.dark_mode,
                            const Color(0xFF374151),
                            const Color(0xFF1F2937),
                            AppTheme.darkMode),
                        _buildThemeCard(
                            'Minimal',
                            'Simple & Clean',
                            Icons.crop_square,
                            const Color(0xFF6B7280),
                            const Color(0xFF4B5563),
                            AppTheme.minimal),
                        _buildThemeCard(
                            'Purple Neon',
                            'Vibrant Purple',
                            Icons.star,
                            const Color(0xFF8B5CF6),
                            const Color(0xFF7C3AED),
                            AppTheme.purpleNeon),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Theme selection info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tokens.borderDefault.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: tokens.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can change your theme anytime in Settings',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(String title, String description, IconData icon,
      Color primaryColor, Color secondaryColor, AppTheme theme) {
    final isSelected = _selectedTheme == theme;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_pulseAnimation.value * 0.05),
          child: GestureDetector(
            onTap: () => _selectTheme(theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(isSelected ? 0.3 : 0.1),
                    secondaryColor.withOpacity(isSelected ? 0.3 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? primaryColor : primaryColor.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(isSelected ? 0.3 : 0.1),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 2 : 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractivePage(OnboardingPageData page, SemanticTokens tokens) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return _buildTransitionWrapper(
      page,
      child: GestureDetector(
        onTap: _dismissKeyboard, // Dismiss keyboard when tapping outside
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  (isKeyboardVisible ? 0 : 200), // Account for bottom nav
            ),
            child: Column(
              mainAxisAlignment: isKeyboardVisible
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Show icon and title only when keyboard is not visible
                if (!isKeyboardVisible) ...[
                  _buildAnimatedIcon(page),
                  const SizedBox(height: 40),
                  _buildAnimatedTitle(page, tokens),
                  const SizedBox(height: 12),
                  _buildAnimatedSubtitle(page, tokens),
                  const SizedBox(height: 40),
                ] else ...[
                  // When keyboard is visible, show a smaller header
                  const SizedBox(height: 20),
                  _buildAnimatedTitle(page, tokens),
                  const SizedBox(height: 8),
                  _buildAnimatedSubtitle(page, tokens),
                  const SizedBox(height: 20),
                ],

                // Animated nickname input form
                _buildAnimatedForm(page, tokens),

                const SizedBox(height: 20),

                // Animated helper text
                _buildAnimatedHelperText(page, tokens),

                // Add extra space when keyboard is visible
                if (isKeyboardVisible) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedForm(OnboardingPageData page, SemanticTokens tokens) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_bounceAnimation.value * 0.05),
          child: Form(
            key: _formKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextFormField(
                controller: _nicknameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done, // iOS: "Done" button
                keyboardType: TextInputType.name, // Optimize for name input
                enableSuggestions: true, // Enable autocomplete suggestions
                autocorrect: false, // Disable autocorrect for names
                style: TextStyle(
                  fontSize: 18,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Your Nickname',
                  hintText: 'Enter your preferred name',
                  prefixIcon: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: page.primaryColor,
                        ),
                      );
                    },
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
                  // Add character counter
                  counterText: '${_nicknameController.text.length}/20',
                  counterStyle: TextStyle(
                    color: _nicknameController.text.length > 20
                        ? tokens.error
                        : tokens.textTertiary,
                    fontSize: 12,
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
                    _nicknameValid =
                        value.trim().length >= 2 && value.trim().length <= 20;
                  });
                },
                onFieldSubmitted: (value) {
                  // Auto-advance to next page when user presses "Done" on iOS
                  if (_nicknameValid) {
                    _nextPage();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHelperText(
      OnboardingPageData page, SemanticTokens tokens) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_waveAnimation.value * 2 * math.pi) * 2),
          child: Text(
            'This name will be used to personalize your experience',
            style: TextStyle(
              fontSize: 14,
              color: tokens.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
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
        child: _videoInitialized
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            : Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _pages[_currentPage].primaryColor,
                      _pages[_currentPage].secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
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

/// Transition types for different page animations
enum TransitionType {
  fade,
  slide,
  zoom,
  flip,
  bounce,
  morph,
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
  final bool isThemeShowcase;
  final TransitionType transitionType;

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
    this.isThemeShowcase = false,
    this.transitionType = TransitionType.fade,
  });
}
