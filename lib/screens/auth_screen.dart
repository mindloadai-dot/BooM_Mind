import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/widgets/unified_design_system.dart';

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

      if (kDebugMode) {
        debugPrint(
            'Biometric check: isAvailable=$isAvailable, isDeviceSupported=$isDeviceSupported');
      }

      if (isAvailable && isDeviceSupported) {
        // Check what biometric methods are actually available
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        final hasBiometrics = availableBiometrics.isNotEmpty;

        if (kDebugMode) {
          debugPrint('Available biometrics: $availableBiometrics');
        }

        setState(() {
          _hasBiometrics = hasBiometrics;
        });
      } else {
        setState(() {
          _hasBiometrics = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking biometrics: $e');
      }
      setState(() {
        _hasBiometrics = false;
      });
    }
  }

  Future<void> _testBiometricAuthentication() async {
    if (kDebugMode) {
      debugPrint('Testing biometric authentication...');
      debugPrint('Has biometrics: $_hasBiometrics');

      try {
        final isAvailable = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        final availableBiometrics = await _localAuth.getAvailableBiometrics();

        debugPrint('Test results:');
        debugPrint('  canCheckBiometrics: $isAvailable');
        debugPrint('  isDeviceSupported: $isDeviceSupported');
        debugPrint('  availableBiometrics: $availableBiometrics');
      } catch (e) {
        debugPrint('Test error: $e');
      }
    }
  }

  Future<void> _checkAuthentication() async {
    // Don't automatically check cached authentication state
    // This prevents authentication bypass when the app is restarted
    // Users must go through the proper authentication flow each time

    // Only check if user is already authenticated with Firebase
    // final bool isAuthenticated = await StorageService.instance.isAuthenticated();
    // if (isAuthenticated) {
    //   _navigateToHome();
    // }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    if (!_hasBiometrics) {
      // No biometrics available, use fallback authentication
      await _authenticateWithFallback();
      return;
    }

    try {
      // First, check if biometrics are still available
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Biometric authentication is no longer available';
        });
        return;
      }

      // Get available biometrics to provide better user feedback
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        setState(() {
          _errorMessage = 'No biometric methods are configured on this device';
        });
        return;
      }

      // Perform biometric authentication
      final bool authenticated = await _localAuth.authenticate(
        localizedReason:
            'Use Face ID, Touch ID, or PIN to access your AI study interface',
        options: const AuthenticationOptions(
          biometricOnly: true, // Only allow biometric authentication
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Biometric authentication successful, now authenticate with Firebase
        try {
          // Try to sign in with Firebase using stored credentials or anonymous auth
          final authService = AuthService.instance;
          final user =
              await authService.signInAsAdminTest(); // For now, use admin test

          if (user != null) {
            // Log successful authentication
            TelemetryService.instance.logEvent(
              'authentication_success',
              {
                'method': 'biometric',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );

            _navigateToHome();
          } else {
            setState(() {
              _errorMessage =
                  'Authentication successful but failed to sign in to account';
            });
          }
        } catch (firebaseError) {
          setState(() {
            _errorMessage =
                'Biometric authentication successful, but account sign-in failed: ${firebaseError.toString()}';
          });
        }
      } else {
        // Biometric authentication failed
        setState(() {
          _errorMessage = 'Biometric authentication was cancelled or failed';
        });

        // Log authentication failure
        TelemetryService.instance.logEvent(
          'authentication_failed',
          {
            'error': 'Biometric authentication cancelled or failed',
            'method': 'biometric',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      String errorMessage;

      // Provide user-friendly error messages
      if (e.toString().contains('NotAvailable')) {
        errorMessage =
            'Biometric authentication is not available on this device';
      } else if (e.toString().contains('NotEnrolled')) {
        errorMessage = 'No biometric methods are enrolled on this device';
      } else if (e.toString().contains('PasscodeNotSet')) {
        errorMessage =
            'Device passcode must be set to use biometric authentication';
      } else if (e.toString().contains('Lockout')) {
        errorMessage =
            'Biometric authentication is temporarily locked. Please try again later.';
      } else if (e.toString().contains('UserCancel')) {
        errorMessage = 'Authentication was cancelled';
      } else {
        errorMessage = 'Authentication failed: ${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      // Log authentication failure
      TelemetryService.instance.logEvent(
        'authentication_failed',
        {
          'error': e.toString(),
          'method': 'biometric',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _authenticateWithFallback() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Try to sign in with Firebase using fallback method
      final authService = AuthService.instance;
      final user =
          await authService.signInAsAdminTest(); // For now, use admin test

      if (user != null) {
        // Log successful authentication
        TelemetryService.instance.logEvent(
          'authentication_success',
          {
            'method': 'fallback',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = 'Fallback authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fallback authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToHome() {
    // Navigate to home route to allow onboarding check
    Navigator.of(context).pushReplacementNamed('/home');
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
            padding: UnifiedSpacing.screenPadding,
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
                  SizedBox(height: UnifiedSpacing.xl),

                  // Animated MINDLOAD title with glowing effect
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: UnifiedText(
                          'MINDLOAD',
                          style: UnifiedTypography.displayLarge.copyWith(
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

                  SizedBox(height: UnifiedSpacing.sm),

                  UnifiedText(
                    'AI STUDY INTERFACE',
                    style: UnifiedTypography.titleMedium.copyWith(
                      color: context.tokens.textPrimary,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: UnifiedSpacing.xxl),

                  // Authentication status card
                  UnifiedCard(
                    padding: UnifiedSpacing.cardPadding,
                    margin: EdgeInsets.zero,
                    elevation: 8,
                    borderRadius: UnifiedBorderRadius.lgRadius,
                    child: Column(
                      children: [
                        UnifiedIcon(
                          _hasBiometrics
                              ? (_getPreferredBiometricIcon())
                              : Icons.lock,
                          size: 48,
                          color: context.tokens.primary,
                        ),
                        SizedBox(height: UnifiedSpacing.md),
                        UnifiedText(
                          _hasBiometrics
                              ? 'BIOMETRIC SCAN REQUIRED'
                              : 'SECURE ACCESS ENABLED',
                          style: UnifiedTypography.titleMedium.copyWith(
                            color: context.tokens.textPrimary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: UnifiedSpacing.sm),
                        UnifiedText(
                          _hasBiometrics
                              ? 'Use biometric authentication to unlock your AI study interface'
                              : 'Tap to access your study data and begin your learning journey',
                          style: UnifiedTypography.bodyMedium.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Show error message if present
                        if (_errorMessage != null) ...[
                          SizedBox(height: UnifiedSpacing.md),
                          Container(
                            padding: EdgeInsets.all(UnifiedSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.tokens.error,
                              borderRadius: UnifiedBorderRadius.smRadius,
                            ),
                            child: Row(
                              children: [
                                UnifiedIcon(
                                  Icons.error_outline,
                                  color: context.tokens.onPrimary,
                                  size: 16,
                                ),
                                SizedBox(width: UnifiedSpacing.sm),
                                Expanded(
                                  child: UnifiedText(
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

                  SizedBox(height: UnifiedSpacing.xxl),

                  // Authentication button - modernized to match welcome screen
                  UnifiedButton(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    fullWidth: true,
                    loading: _isAuthenticating,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        UnifiedIcon(
                          _hasBiometrics
                              ? _getPreferredBiometricIcon()
                              : Icons.login,
                          size: 24,
                        ),
                        SizedBox(width: UnifiedSpacing.sm),
                        UnifiedText(
                          _hasBiometrics ? 'AUTHENTICATE' : 'ENTER MINDLOAD',
                          style: UnifiedTypography.labelLarge.copyWith(
                            color: context.tokens.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: UnifiedSpacing.xl),

                  // Bottom version info
                  UnifiedText(
                    'v1.0.0 • SECURE NEURAL NETWORK',
                    style: UnifiedTypography.bodySmall.copyWith(
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
