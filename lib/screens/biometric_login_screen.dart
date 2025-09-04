import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/biometric_auth_service.dart';
import 'package:mindload/widgets/unified_design_system.dart';

/// Biometric Login Screen - shown at app startup when biometric login is enabled
class BiometricLoginScreen extends StatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  State<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends State<BiometricLoginScreen>
    with TickerProviderStateMixin {
  bool _isAuthenticating = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _biometricDescription = 'Biometric authentication';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _initializeBiometric();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initializeBiometric() async {
    try {
      // Get biometric description
      final description =
          await BiometricAuthService.instance.getBiometricDescription();
      setState(() {
        _biometricDescription = description;
      });

      // Auto-trigger biometric authentication after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _authenticateWithBiometric();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing biometric: $e');
      }
      _showError('Failed to initialize biometric authentication');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final success =
          await BiometricAuthService.instance.authenticateWithBiometric(
        reason: 'Use $_biometricDescription to access MindLoad',
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ Biometric authentication successful');
        }
        _navigateToHome();
      } else {
        if (kDebugMode) {
          debugPrint('❌ Biometric authentication failed');
        }
        _showError('Authentication failed. Please try again.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Biometric authentication error: $e');
      }

      // Show user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _showError(errorMessage);

      // If biometric is not available or not enrolled, offer alternative
      if (errorMessage.contains('not available') ||
          errorMessage.contains('not enrolled') ||
          errorMessage.contains('No biometrics enrolled')) {
        _showBiometricSetupDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _showBiometricSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Setup Required'),
        content: const Text(
          'Biometric authentication is not available or not set up on this device. '
          'Please set up Face ID or fingerprint in your device settings, or use email sign-in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAuth();
            },
            child: const Text('Sign in with Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Disable biometric login since it's not working
              BiometricAuthService.instance.toggleBiometricLogin(false);
              _navigateToAuth();
            },
            child: const Text('Disable Biometric'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: UnifiedSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon with animations
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(_glowAnimation.value * 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: UnifiedIcon(
                        Icons.fingerprint,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: UnifiedSpacing.xl),

              // Title
              UnifiedText(
                'Welcome Back',
                style: UnifiedTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: UnifiedSpacing.md),

              // Subtitle
              UnifiedText(
                'Use $_biometricDescription to continue',
                style: UnifiedTypography.bodyLarge.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: UnifiedSpacing.xl),

              // Error message
              if (_hasError) ...[
                UnifiedCard(
                  padding: UnifiedSpacing.cardPadding,
                  borderRadius: UnifiedBorderRadius.mdRadius,
                  child: Row(
                    children: [
                      UnifiedIcon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: UnifiedSpacing.sm),
                      Expanded(
                        child: UnifiedText(
                          _errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: UnifiedSpacing.lg),
              ],

              // Authenticate button
              UnifiedButton(
                onPressed: _isAuthenticating ? null : _authenticateWithBiometric,
                fullWidth: true,
                loading: _isAuthenticating,
                child: UnifiedText(
                  'Authenticate with $_biometricDescription',
                  style: UnifiedTypography.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: UnifiedSpacing.md),

              // Alternative options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _navigateToAuth,
                    child: UnifiedText('Sign in with email'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Disable biometric login for future launches
                      await BiometricAuthService.instance
                          .toggleBiometricLogin(false);
                      _navigateToHome();
                    },
                    child: UnifiedText('Skip biometric'),
                  ),
                ],
              ),

              const Spacer(),

              // Footer
              UnifiedText(
                'MindLoad - AI Study Companion',
                style: UnifiedTypography.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
