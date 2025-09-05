import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:mindload/config/app_check_config.dart';

import 'package:mindload/services/auth_service.dart';

import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/services/user_profile_service.dart';

import 'package:mindload/services/local_image_storage_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/biometric_auth_service.dart';
import 'package:mindload/services/user_specific_storage_service.dart';
import 'package:mindload/services/pdf_export_service.dart';
import 'package:mindload/models/notification_preferences.dart';
import 'package:mindload/neurograph_v2/neurograph_local_storage.dart';
import 'package:mindload/neurograph_v2/neurograph_offline_repo.dart';
import 'package:mindload/firebase_options.dart';
import 'package:mindload/config/environment_config.dart';

import 'package:mindload/screens/home_screen.dart';
import 'package:mindload/auth/auth_gate.dart';
import 'package:mindload/screens/biometric_login_screen.dart';
import 'package:mindload/screens/modern_onboarding_screen.dart';
import 'package:mindload/screens/logic_packs_screen.dart';
import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/achievements_screen.dart';
import 'package:mindload/screens/settings_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
import 'package:mindload/screens/app_icon_demo_screen.dart';
import 'package:mindload/neurograph_v2/neurograph_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:mindload/screens/notification_debug_screen.dart';
import 'package:mindload/theme.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

// Lifecycle observer for notification rescheduling
class _MlLifecycleRelay with WidgetsBindingObserver {
  void start() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - rescheduling daily notifications');
      MindLoadNotificationService.rescheduleDailyPlan();
    }
  }

  void stop() => WidgetsBinding.instance.removeObserver(this);
}

final _mlLifecycleRelay = _MlLifecycleRelay();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate API configuration
  try {
    EnvironmentConfig.validateConfiguration();
    print('API configuration validated successfully');
  } catch (e) {
    debugPrint('API Configuration Error: $e');
    // In development, continue with fallbacks
    if (!EnvironmentConfig.isDevelopment) {
      rethrow;
    }
  }

  // Initialize Firebase & Core Services
  try {
    // Initialize Firebase with proper configuration options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase - app can still run with limited functionality
  }

  try {
    // Initialize Firebase App Check for mobile (non-blocking)
    if (kDebugMode) {
      await AppCheckConfig.disableAppCheck();
      print('📱 App Check disabled for mobile debug mode');
    } else {
      await AppCheckConfig.initialize();
      print('📱 App Check initialized for mobile production');
    }
  } catch (e) {
    print('📱 App Check initialization failed (non-critical): $e');
    // Continue without App Check - app works perfectly without it
    await AppCheckConfig.disableAppCheck();
  }

  // Initialize other services
  await _initializeCoreServices();

  // Initialize the single unified notification service
  await MindLoadNotificationService.initialize();
  print('✅ MindLoad notification service initialized');

  // Re-apply saved daily notification plan on cold start
  await MindLoadNotificationService.rescheduleDailyPlan();
  print('✅ Daily notification plan re-applied on startup');

  // Set up default notifications if none exist
  await MindLoadNotificationService.setupDefaultDailyNotifications();
  print('✅ Default daily notifications checked/set up');

  // Keep plans fresh when returning to foreground
  _mlLifecycleRelay.start();
  print('✅ Lifecycle observer started for notification management');

  // Initialize the economy service
  await MindloadEconomyService.instance.initialize();
  print('✅ MindLoad economy service initialized');

  // Run the app
  runApp(const MindLoadApp());
}

Future<void> _initializeCoreServices() async {
  try {
    // Initialize timezone data first (required for NeuroGraph V2)
    tz.initializeTimeZones();
    print('✅ Timezone data initialized');

    // Initialize critical services in parallel for faster startup
    await Future.wait([
      // Theme Manager (critical for UI)
      ThemeManager.instance.loadTheme().catchError((e) {
        print('Theme Manager initialization failed: $e');
      }),

      // Auth Service (critical for user state) with iOS-specific handling
      AuthService.instance.initialize().catchError((e) {
        print('Auth Service initialization failed: $e');
        // Continue without throwing - app should still work
      }),

      // Enhanced Storage Service (critical for data)
      UnifiedStorageService.instance.initialize().catchError((e) {
        print('Unified Storage Service initialization failed: $e');
      }),
    ]);

    // Initialize non-critical services in parallel (lazy loading)
    Future.wait([
      // User Profile Service
      UserProfileService.instance.loadProfileData().catchError((e) {
        print('User Profile Service initialization failed: $e');
      }),

      // Haptic Feedback Service
      HapticFeedbackService().initialize().catchError((e) {
        print('Haptic Feedback Service initialization failed: $e');
      }),
    ]).then((_) {
      print('Non-critical services initialized successfully');
    });

    // Initialize heavy services asynchronously (don't block startup)
    _initializeHeavyServicesAsync();
  } catch (e) {
    print('Core services initialization failed: $e');
  }
}

/// Initialize heavy services asynchronously without blocking startup
void _initializeHeavyServicesAsync() {
  // Initialize these services in the background
  Future.microtask(() async {
    try {
      // Local Image Storage Service (heavy I/O operations)
      await LocalImageStorageService.instance.getStorageInfo();
      print('Local Image Storage Service initialized successfully');
    } catch (e) {
      print('Local Image Storage Service initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Ultra Audio Controller (heavy audio processing)
      await UltraAudioController.instance.initialize();
      print('Ultra Audio Controller initialized successfully');
    } catch (e) {
      print('Ultra Audio Controller initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // PDF Export Service (loads package info)
      await PdfExportService.instance.initialize();
      print('PDF Export Service initialized successfully');
    } catch (e) {
      print('PDF Export Service initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Notification Preferences Service
      await NotificationPreferencesService.instance.initialize();
      print('Notification Preferences Service initialized successfully');
    } catch (e) {
      print('Notification Preferences Service initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // Unified Storage Service (for all study sets)
      await UnifiedStorageService.instance.initialize();
      print('Unified Storage Service initialized successfully');
    } catch (e) {
      print('Unified Storage Service initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // NeuroGraph V2 Local Storage (for offline analytics)
      await NeuroGraphLocalStorage.instance.initialize();
      print('NeuroGraph V2 Local Storage initialized successfully');
    } catch (e) {
      print('NeuroGraph V2 Local Storage initialization failed: $e');
    }
  });

  Future.microtask(() async {
    try {
      // NeuroGraph V2 Offline Repository (for data access)
      await NeuroGraphOfflineRepository.instance.initialize();
      print('NeuroGraph V2 Offline Repository initialized successfully');
    } catch (e) {
      print('NeuroGraph V2 Offline Repository initialization failed: $e');
    }
  });
}

class MindLoadApp extends StatelessWidget {
  const MindLoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(
          value: ThemeManager.instance,
        ),
        ChangeNotifierProvider<AuthService>.value(
          value: AuthService.instance,
        ),
        ChangeNotifierProvider<MindloadEconomyService>.value(
          value: MindloadEconomyService.instance,
        ),
        ChangeNotifierProvider<UserProfileService>.value(
          value: UserProfileService.instance,
        ),
        ChangeNotifierProvider<LocalImageStorageService>.value(
          value: LocalImageStorageService.instance,
        ),
        ChangeNotifierProvider<UnifiedOnboardingService>.value(
          value: UnifiedOnboardingService(),
        ),
        ChangeNotifierProvider<NotificationPreferencesService>.value(
          value: NotificationPreferencesService.instance,
        ),
        ChangeNotifierProvider<UnifiedStorageService>.value(
          value: UnifiedStorageService.instance,
        ),
        ChangeNotifierProvider<BiometricAuthService>.value(
          value: BiometricAuthService.instance,
        ),
        ChangeNotifierProvider<UserSpecificStorageService>.value(
          value: UserSpecificStorageService.instance,
        ),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'Mindload',
            debugShowCheckedModeBanner: false,
            theme: themeManager.lightTheme,
            home: const AppInitializer(),
            routes: {
              '/auth': (context) => const AuthGate(),
              '/home': (context) => const HomeScreen(),
              '/biometric-login': (context) => const BiometricLoginScreen(),
              '/onboarding': (context) => const ModernOnboardingScreen(),
              '/logic-packs': (context) => const LogicPacksScreen(),
              '/my-plan': (context) => const MyPlanScreen(),
              '/achievements': (context) => const AchievementsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/app-icon-demo': (context) => const AppIconDemoScreen(),
              '/neurograph': (context) => NeuroGraphV2Screen(
                  userId: AuthService.instance.currentUserId ?? 'anonymous'),
              '/notification-debug': (context) =>
                  const NotificationDebugScreen(),
              '/profile/insights/neurograph': (context) => NeuroGraphV2Screen(
                  userId: AuthService.instance.currentUserId ?? 'anonymous'),
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  AppInitializerState createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer>
    with TickerProviderStateMixin {
  bool _isInitialized = false;
  bool _hasError = false;
  String _statusMessage = 'Initializing MindLoad...';
  Timer? _safetyTimer;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  // Animation controller for glow effect
  late AnimationController _glowController;

  // Animation for glow effect
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundAnimations();
    _initializeVideo();
    _initializeApp();

    // Safety timeout - force app to continue after 15 seconds
    _safetyTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_isInitialized) {
        setState(() {
          _statusMessage = 'Safety timeout reached - continuing...';
          _isInitialized = true;
        });
      }
    });
  }

  void _initializeBackgroundAnimations() {
    // Glow intensity animation for video logo
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  /// Initialize the video player
  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.asset('assets/images/logo.mp4.mp4');
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });

        // Set the video to loop and start playing
        _videoController!.setLooping(true);
        _videoController!.play();
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      // Continue without video - fallback to static logo
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _videoController?.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure video plays for exactly 4 seconds
      final startTime = DateTime.now();

      // CRITICAL: Initialize AuthService FIRST - Authentication must be checked before anything else
      setState(() => _statusMessage = 'Checking authentication...');

      // Wait for AuthService to properly initialize and load user state
      final authService = AuthService.instance;
      await authService.initialize();

      // Give Firebase auth state a moment to load if user is authenticated
      await Future.delayed(const Duration(milliseconds: 500));

      if (authService.currentUser != null) {
        setState(() => _statusMessage = 'Authentication verified');
      } else {
        setState(() => _statusMessage = 'Ready for authentication');
      }

      // Initialize BiometricAuthService
      setState(() => _statusMessage = 'Setting up security features...');
      await BiometricAuthService.instance.initialize();

      // Initialize UserSpecificStorageService
      setState(() => _statusMessage = 'Setting up user storage...');
      await UserSpecificStorageService.instance.initialize();

      // Initialize App Check if not in debug mode
      if (!kDebugMode || !AppCheckConfig.shouldSkipAppCheck) {
        setState(() => _statusMessage = 'Verifying app security...');

        try {
          await AppCheckConfig.verifyAppCheckToken();
          setState(() => _statusMessage = 'Security verified');
        } catch (e) {
          // Continue without App Check verification
          setState(() => _statusMessage = 'Security check skipped');
        }
      } else {
        setState(() =>
            _statusMessage = 'Debug mode: Skipping security verification');
      }

      // Calculate remaining time to ensure total 4-second display
      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = const Duration(seconds: 4) - elapsed;

      if (remainingTime.inMilliseconds > 0) {
        setState(() => _statusMessage = 'Loading MindLoad...');
        await Future.delayed(remainingTime);
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      // Even on error, ensure minimum 4-second display
      final startTime = DateTime.now();
      setState(() {
        _hasError = true;
        _statusMessage = 'Initialization error: $e';
      });

      final elapsed = DateTime.now().difference(startTime);
      final remainingTime = const Duration(seconds: 4) - elapsed;
      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _initializeApp(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main content with video
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MP4 Video Logo with enhanced glow
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withOpacity(0.3 * _glowAnimation.value),
                              blurRadius: 30 * _glowAnimation.value,
                              spreadRadius: 5 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: const Color(0xFF8B5CF6)
                                  .withOpacity(0.2 * _glowAnimation.value),
                              blurRadius: 20 * _glowAnimation.value,
                              spreadRadius: 3 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: _videoInitialized && _videoController != null
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                            0xFF6366F1), // Electric blue
                                        const Color(0xFF8B5CF6), // Purple
                                        const Color(0xFFEC4899), // Pink
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Status overlay at the bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Loading indicator
                  CircularProgressIndicator(),
                  const SizedBox(height: 24),

                  // Status message
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Please wait...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // App is initialized - show main app logic with STRICT authentication priority
    return Consumer4<AuthService, UnifiedOnboardingService,
        BiometricAuthService, ThemeManager>(
      builder: (context, authService, onboardingService, biometricService,
          themeManager, child) {
        // 🔐 CRITICAL: Authentication is ALWAYS first priority - NO EXCEPTIONS!
        if (authService.currentUser == null) {
          debugPrint(
              '🔐 AppInitializer: User not authenticated - showing AuthGate');
          return const AuthGate();
        }

        debugPrint(
            '🔐 AppInitializer: User authenticated: ${authService.currentUser!.email}');

        // 🔒 Check if biometric login should be used
        if (biometricService.isBiometricLoginEnabled) {
          debugPrint(
              '🔒 AppInitializer: Biometric login enabled - showing BiometricLoginScreen');
          return const BiometricLoginScreen();
        }

        // ✅ User is authenticated - now check onboarding (shows ONLY ONCE after first install)
        // CRITICAL: Once onboarding is completed, it will NEVER show again - NO EXCEPTIONS!
        if (onboardingService.needsOnboarding) {
          debugPrint(
              '🎯 AppInitializer: Onboarding needed - showing ModernOnboardingScreen (FIRST TIME ONLY)');
          debugPrint(
              '   This will be the ONLY time the user sees the welcome screen');
          return const ModernOnboardingScreen();
        }

        debugPrint(
            '✅ AppInitializer: Onboarding already completed - skipping welcome screen forever');

        debugPrint('🏠 AppInitializer: Showing main HomeScreen');
        // ✅ User is authenticated and onboarding is complete - show main app
        return const HomeScreen();
      },
    );
  }
}
