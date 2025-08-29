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
import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/firebase_options.dart';
import 'package:mindload/config/environment_config.dart';

import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/screens/home_screen.dart';
import 'package:mindload/screens/modern_onboarding_screen.dart';
import 'package:mindload/widgets/welcome_dialog.dart';
import 'package:mindload/screens/logic_packs_screen.dart';
import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/achievements_screen.dart';
import 'package:mindload/screens/settings_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
import 'package:mindload/theme.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

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
    // Initialize Firebase App Check (non-blocking)
    if (kDebugMode && AppCheckConfig.shouldSkipAppCheck) {
      await AppCheckConfig.disableAppCheck();
      print('App Check disabled for debug mode');
    } else {
      await AppCheckConfig.initialize();
      print('App Check initialized successfully');
    }
  } catch (e) {
    print('App Check initialization failed: $e');
    // Continue without App Check - app can still run
    await AppCheckConfig.disableAppCheck();
  }

  // Initialize other services
  await _initializeCoreServices();

  // Initialize the single unified notification service
  await MindLoadNotificationService.initialize();
  print('✅ MindLoad notification service initialized');

  // Initialize the economy service
  await MindloadEconomyService.instance.initialize();
  print('✅ MindLoad economy service initialized');

  // Run the app
  runApp(const MindLoadApp());
}

Future<void> _initializeCoreServices() async {
  try {
    // Initialize critical services in parallel for faster startup
    await Future.wait([
      // Theme Manager (critical for UI)
      ThemeManager.instance.loadTheme().catchError((e) {
        print('Theme Manager initialization failed: $e');
      }),

      // Auth Service (critical for user state)
      AuthService.instance.initialize().catchError((e) {
        print('Auth Service initialization failed: $e');
      }),

      // Enhanced Storage Service (critical for data)
      EnhancedStorageService.instance.initialize().catchError((e) {
        print('Enhanced Storage Service initialization failed: $e');
      }),
    ]);

    // Initialize non-critical services in parallel (lazy loading)
    Future.wait([
      // User Profile Service
      UserProfileService.instance.initialize().catchError((e) {
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
        ChangeNotifierProvider<EnhancedStorageService>.value(
          value: EnhancedStorageService.instance,
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
              '/social-auth': (context) => const SocialAuthScreen(),
              '/home': (context) => const HomeScreen(),
              '/onboarding': (context) => const ModernOnboardingScreen(),
              '/logic-packs': (context) => const LogicPacksScreen(),
              '/my-plan': (context) => const MyPlanScreen(),
              '/achievements': (context) => const AchievementsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/profile': (context) => const ProfileScreen(),
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

class AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _statusMessage = 'Initializing MindLoad...';
  Timer? _safetyTimer;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure video plays for exactly 4 seconds
      final startTime = DateTime.now();

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
            // Video background
            if (_videoInitialized && _videoController != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              // Fallback static logo
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
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
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 3,
                  ),
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

    // App is initialized - show main app logic
    return Consumer3<AuthService, UnifiedOnboardingService, ThemeManager>(
      builder: (context, authService, onboardingService, themeManager, child) {
        // Check authentication state
        if (authService.currentUser == null) {
          return const SocialAuthScreen();
        }

        // Check if onboarding is needed (shows only once after first install)
        if (onboardingService.needsOnboarding) {
          return const ModernOnboardingScreen();
        }

        // Show welcome dialog if needed
        if (onboardingService.shouldShowWelcomeDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const WelcomeDialog(),
              );
            }
          });
        }

        // Main app content
        return const HomeScreen();
      },
    );
  }
}
