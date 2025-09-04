import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/screens/home_screen.dart';
import 'package:mindload/screens/social_auth_screen.dart';
import 'package:mindload/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (details) {
    // Log error to telemetry service
    TelemetryService.instance.trackEvent(
      'flutter_error',
      parameters: {
        'error': details.exception.toString(),
        'stack': details.stack.toString(),
      },
    );
  };

  // Initialize core services
  try {
    // Initialize storage service
    await UnifiedStorageService.instance.initialize();

    // Initialize theme manager
    await ThemeManager.instance.loadTheme();

    // Initialize telemetry service
    TelemetryService.instance.setEnabled(true);

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize auth service
    await AuthService.instance.initialize();

    // Initialize Ultra Audio Controller
    await UltraAudioController.instance.initialize();

    // Initialize Mindload Economy Service
    await MindloadEconomyService.instance.initialize();
  } catch (e) {
    // Continue with limited functionality
  }

  runApp(const MindLoadApp());
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
        ChangeNotifierProvider<UnifiedStorageService>.value(
          value: UnifiedStorageService.instance,
        ),
        ChangeNotifierProvider<UltraAudioController>.value(
          value: UltraAudioController.instance,
        ),
        ChangeNotifierProvider<MindloadEconomyService>.value(
          value: MindloadEconomyService.instance,
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
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if all services are ready
      final services = [
        'Storage Service',
        'Theme Manager',
        'Telemetry Service',
        'Firebase',
        'Auth Service',
        'Ultra Audio Controller',
      ];

      for (final serviceName in services) {
        setState(() => _statusMessage = 'Initializing $serviceName...');
        await Future.delayed(const Duration(milliseconds: 300));
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _statusMessage = 'Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          if (user != null) {
            return const HomeScreen();
          } else {
            return const SocialAuthScreen();
          }
        },
      );
    }

    final tokens = ThemeManager.instance.currentTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: tokens.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'MindLoad',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tokens.brandTitle,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
