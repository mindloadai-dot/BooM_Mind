import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/biometric_auth_service.dart';

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
      _showError('Authentication error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
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
    Navigator.of(context).pushReplacementNamed('/social-auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      child: Icon(
                        Icons.fingerprint,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Use $_biometricDescription to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Error message
              if (_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Authenticate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isAuthenticating ? null : _authenticateWithBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAuthenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Authenticate with $_biometricDescription',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Alternative options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _navigateToAuth,
                    child: const Text('Sign in with email'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Disable biometric login for future launches
                      await BiometricAuthService.instance
                          .toggleBiometricLogin(false);
                      _navigateToHome();
                    },
                    child: const Text('Skip biometric'),
                  ),
                ],
              ),

              const Spacer(),

              // Footer
              Text(
                'MindLoad - AI Study Companion',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
