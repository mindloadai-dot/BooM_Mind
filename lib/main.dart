import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:mindload/config/app_check_config.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/local_image_storage_service.dart';
import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/firebase_options.dart';
import 'package:mindload/config/environment_config.dart';

import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/screens/home_screen.dart';
import 'package:mindload/screens/unified_onboarding_screen.dart';
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

  try {
    // Initialize WorkingNotificationService directly (eliminates conflicts)
    await WorkingNotificationService.instance.initialize();
    print('Unified Notification Service initialized successfully');
  } catch (e) {
    print('Unified Notification Service initialization failed: $e');
    // Continue without notifications
  }

  try {
    // Initialize Unified Onboarding Service (replaces old services)
    await UnifiedOnboardingService().initialize();
    print('Unified Onboarding Service initialized successfully');
  } catch (e) {
    print('Unified Onboarding Service initialization failed: $e');
    // Continue without onboarding
  }

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
    // Mindload Economy Service
    MindloadEconomyService.instance.initialize().catchError((e) {
      print('Mindload Economy Service initialization failed: $e');
    }),

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

  runApp(const MindLoadApp());
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
            title: 'MindLoad',
            theme: themeManager.lightTheme,
            darkTheme: themeManager.darkTheme,
            themeMode: ThemeMode.system,
            home: const _AppInitializationScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/auth': (context) => const SocialAuthScreen(),
              '/home': (context) => const HomeScreen(),
              '/logic-packs': (context) => const LogicPacksScreen(),
              '/my-plan': (context) => const MyPlanScreen(),
              '/achievements': (context) => const AchievementsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle dynamic routes if needed
              switch (settings.name) {
                case '/logic-packs':
                  return MaterialPageRoute(
                    builder: (context) => const LogicPacksScreen(),
                  );
                case '/my-plan':
                  return MaterialPageRoute(
                    builder: (context) => const MyPlanScreen(),
                  );
                case '/achievements':
                  return MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  );
                case '/settings':
                  return MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Page not found'),
                      ),
                    ),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class _AppInitializationScreen extends StatefulWidget {
  const _AppInitializationScreen();

  @override
  State<_AppInitializationScreen> createState() =>
      _AppInitializationScreenState();
}

class _AppInitializationScreenState extends State<_AppInitializationScreen> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _statusMessage = 'Initializing...';
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
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

      // Wait a moment for user to see status
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Initialization error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          if (user != null) {
            // User is authenticated, check onboarding
            return Consumer<UnifiedOnboardingService>(
              builder: (context, onboardingService, child) {
                if (onboardingService.needsOnboarding) {
                  return const UnifiedOnboardingScreen();
                } else {
                  return const HomeScreenWithWelcome();
                }
              },
            );
          } else {
            return const SocialAuthScreen();
          }
        },
      );
    }

    final tokens = ThemeManager.instance.currentTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Image.asset(
                'assets/images/Brain_logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              // App Title
              Text(
                'MindLoad',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.brandTitle,
                    ),
              ),
              const SizedBox(height: 16),

              // Status Message
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: tokens.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Progress Indicator
              if (!_hasError) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // Error Display
              if (_hasError) ...[
                Icon(
                  Icons.error_outline,
                  color: tokens.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _statusMessage = 'Retrying...';
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],

              // Skip Button (only show after delay)
              if (!_isInitialized && !_hasError) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() => _isInitialized = true);
                  },
                  child: const Text('Skip Verification & Continue'),
                ),
              ],

              // Local Admin Test Button (only in debug mode)
              if (kDebugMode && !_isInitialized && !_hasError) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() {
                        _statusMessage = 'Signing in as Local Admin...';
                      });

                      final authService = AuthService.instance;
                      final user = await authService.signInAsAdminTest();

                      if (user != null) {
                        setState(() {
                          _statusMessage =
                              'Local Admin signed in successfully!';
                          _isInitialized = true;
                        });
                      } else {
                        setState(() {
                          _statusMessage = 'Failed to sign in as Local Admin';
                          _hasError = true;
                        });
                      }
                    } catch (e) {
                      setState(() {
                        _statusMessage = 'Error: $e';
                        _hasError = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                  ),
                  child: const Text('Sign In as Local Admin (Debug)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// HomeScreen wrapper that shows welcome dialog if needed
class HomeScreenWithWelcome extends StatefulWidget {
  const HomeScreenWithWelcome({super.key});

  @override
  State<HomeScreenWithWelcome> createState() => _HomeScreenWithWelcomeState();
}

class _HomeScreenWithWelcomeState extends State<HomeScreenWithWelcome> {
  @override
  void initState() {
    super.initState();
    // Show welcome dialog after build if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialogIfNeeded();
    });
  }

  Future<void> _showWelcomeDialogIfNeeded() async {
    final onboardingService = UnifiedOnboardingService();
    if (onboardingService.shouldShowWelcomeDialog) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
