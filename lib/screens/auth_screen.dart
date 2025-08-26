import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mindload/screens/home_screen.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _hasBiometrics = false;
  String? _errorMessage;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkBiometrics();
    _checkAuthentication();

    // Log screen access for telemetry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelemetryService.instance.logEvent(
        'screen_accessed',
        {
          'screen_name': 'auth_screen',
          'has_biometrics': _hasBiometrics,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _hasBiometrics = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking biometrics: $e');
      }
      setState(() {
        _hasBiometrics = false;
      });
    }
  }

  Future<void> _checkAuthentication() async {
    final bool isAuthenticated =
        await StorageService.instance.isAuthenticated();
    if (isAuthenticated) {
      _navigateToHome();
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    if (!_hasBiometrics) {
      await StorageService.instance.setAuthenticated(true);
      _navigateToHome();
      return;
    }

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason:
            'Use Face ID, Touch ID, or PIN to access your AI study interface',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await StorageService.instance.setAuthenticated(true);

        // Log successful authentication
        TelemetryService.instance.logEvent(
          'authentication_success',
          {
            'method': _hasBiometrics ? 'biometric' : 'fallback',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        _navigateToHome();
      }
    } catch (e) {
      final String errorMessage = 'Authentication failed: ${e.toString()}';

      setState(() {
        _errorMessage = errorMessage;
      });

      // Log authentication failure
      TelemetryService.instance.logEvent(
        'authentication_failed',
        {
          'error': e.toString(),
          'method': _hasBiometrics ? 'biometric' : 'fallback',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.tokens.surface,
              context.tokens.onPrimaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Animated MINDLOAD title with glowing effect
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Text(
                          'MINDLOAD',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                            color: context.tokens.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            shadows: [
                              Shadow(
                                blurRadius: 30.0 * _glowAnimation.value,
                                color: context.tokens.primary.withValues(
                                    alpha: 0.9 * _glowAnimation.value),
                                offset: const Offset(0.0, 0.0),
                              ),
                              Shadow(
                                blurRadius: 60.0 * _glowAnimation.value,
                                color: context.tokens.primary.withValues(
                                    alpha: 0.7 * _glowAnimation.value),
                                offset: const Offset(0.0, 0.0),
                              ),
                              Shadow(
                                blurRadius: 90.0 * _glowAnimation.value,
                                color: context.tokens.primary.withValues(
                                    alpha: 0.5 * _glowAnimation.value),
                                offset: const Offset(0.0, 0.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'AI STUDY INTERFACE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.tokens.textPrimary,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Authentication status card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.tokens.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.tokens.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _hasBiometrics
                              ? (_getPreferredBiometricIcon())
                              : Icons.lock,
                          size: 48,
                          color: context.tokens.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasBiometrics
                              ? 'BIOMETRIC SCAN REQUIRED'
                              : 'SECURE ACCESS ENABLED',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: context.tokens.textPrimary,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasBiometrics
                              ? 'Use biometric authentication to unlock your AI study interface'
                              : 'Tap to access your study data and begin your learning journey',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        // Show error message if present
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.tokens.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: context.tokens.onPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: context.tokens.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Authentication button - modernized to match welcome screen
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isAuthenticating ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.tokens.primary,
                        foregroundColor: context.tokens.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor:
                            context.tokens.primary.withValues(alpha: 0.4),
                      ),
                      child: _isAuthenticating
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: context.tokens.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _hasBiometrics
                                      ? _getPreferredBiometricIcon()
                                      : Icons.login,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _hasBiometrics
                                      ? 'AUTHENTICATE'
                                      : 'ENTER MINDLOAD',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: context.tokens.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom version info
                  Text(
                    'v1.0.0 • SECURE NEURAL NETWORK',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPreferredBiometricIcon() {
    // Return appropriate icon based on platform capabilities
    // For iOS devices, Face ID is more common on newer devices
    // For Android, fingerprint is most common
    return Icons.face; // Face ID icon for sci-fi aesthetic
  }
}
