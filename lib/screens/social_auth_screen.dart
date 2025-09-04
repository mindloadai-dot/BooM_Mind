import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/firebase_client_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class SocialAuthScreen extends StatefulWidget {
  const SocialAuthScreen({super.key});

  @override
  State<SocialAuthScreen> createState() => _SocialAuthScreenState();
}

class _SocialAuthScreenState extends State<SocialAuthScreen>
    with TickerProviderStateMixin {
  bool _isSigningIn = false;
  String _currentProvider = '';
  bool _showEmailForm = false;

  // Email form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;

  // Animation controllers for particles and glow
  late AnimationController _particleController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    try {
      _particleController = AnimationController(
        duration: const Duration(seconds: 20),
        vsync: this,
      )..repeat();

      _glowController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ));

      print('🎨 Animations initialized successfully');
    } catch (e) {
      print('❌ Error initializing animations: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _generateParticles() {
    final random = Random();
    _particles = List.generate(25, (index) {
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.4 + 0.1,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _signInWithProvider(AuthProvider provider) async {
    if (!mounted) return;

    setState(() {
      _isSigningIn = true;
      _currentProvider = provider.name;
    });

    try {
      print('🔐 Starting sign-in with ${provider.name}...');

      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseClient = FirebaseClientService.instance;
      AuthUser? user;

      switch (provider) {
        case AuthProvider.google:
          print('🔍 Attempting Google Sign-In...');
          // Try Firebase client first, fallback to existing auth service
          if (firebaseClient.isInitialized) {
            try {
              final result = await firebaseClient.signInWithGoogle();
              if (result.success) {
                print('✅ Google Sign-In successful via Firebase client');
                _navigateToHome();
                return;
              }
            } catch (e) {
              print(
                  '⚠️ Firebase client Google Sign-In failed, trying auth service: $e');
            }
          }
          user = await authService.signInWithGoogle();
          break;
        case AuthProvider.apple:
          print('🍎 Attempting Apple Sign-In...');
          // Check if Apple Sign-In is available on this platform
          if (!Platform.isIOS && !Platform.isMacOS) {
            throw Exception('Apple Sign-In is only available on iOS and macOS');
          }

          // Try Firebase client first, fallback to existing auth service
          if (firebaseClient.isInitialized) {
            try {
              final result = await firebaseClient.signInWithApple();
              if (result.success) {
                print('✅ Apple Sign-In successful via Firebase client');
                _navigateToHome();
                return;
              }
            } catch (e) {
              print(
                  '⚠️ Firebase client Apple Sign-In failed, trying auth service: $e');
            }
          }
          user = await authService.signInWithApple();
          break;
        case AuthProvider.microsoft:
          print('🔷 Attempting Microsoft Sign-In...');
          user = await authService.signInWithMicrosoft();
          break;
        case AuthProvider.email:
          // This is handled by the email form
          break;
        case AuthProvider.local:
          print('🔧 Attempting local admin sign-in...');
          // Try biometric authentication with Firebase client
          if (firebaseClient.isInitialized) {
            try {
              final result = await firebaseClient.signInWithBiometrics();
              if (result.success) {
                print('✅ Biometric Sign-In successful via Firebase client');
                _navigateToHome();
                return;
              }
            } catch (e) {
              print(
                  '⚠️ Firebase client biometric Sign-In failed, trying auth service: $e');
            }
          }
          user = await authService.signInAsAdminTest();
          break;
      }

      if (user != null && mounted) {
        print('✅ Sign-in successful for user: ${user.email}');
        _navigateToHome();
      } else {
        print('❌ Sign-in failed: No user returned');
        if (mounted) {
          _showErrorDialog('Sign-in failed. Please try again.');
        }
      }
    } on UnsupportedError catch (e) {
      print('❌ Unsupported operation: $e');
      if (mounted) {
        _showErrorDialog(e.message ?? 'Unsupported operation');
      }
    } catch (e) {
      print('❌ Sign-in error with ${provider.name}: $e');
      if (mounted) {
        // Clean up the error message for user display
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _currentProvider = '';
        });
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSigningIn = true;
      _currentProvider = 'email';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseClient = FirebaseClientService.instance;
      AuthUser? user;

      // Try Firebase client first if available
      if (firebaseClient.isInitialized) {
        if (_isSignUp) {
          final result = await firebaseClient.createUserWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
          if (result.success) {
            _navigateToHome();
            return;
          }
        } else {
          final result = await firebaseClient.signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
          if (result.success) {
            _navigateToHome();
            return;
          }
        }
      }

      // Fallback to existing auth service
      if (_isSignUp) {
        user = await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        user = await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (user != null && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _currentProvider = '';
        });
      }
    }
  }

  Future<void> _signInAsAdmin() async {
    setState(() {
      _isSigningIn = true;
      _currentProvider = 'admin';
    });

    try {
      print('🔐 Starting Local Admin Test sign in...');

      final authService = Provider.of<AuthService>(context, listen: false);
      print('🔐 AuthService obtained: ${authService.runtimeType}');

      // Ensure AuthService is initialized
      await authService.initialize();
      print('🔐 AuthService initialized successfully');

      final user = await authService.signInAsAdminTest();
      print('🔐 Sign in result: ${user?.email ?? 'null'}');

      if (user != null && mounted) {
        print('🔐 Local admin sign in successful, navigating to home...');
        _navigateToHome();
      } else {
        print('🔐 Local admin sign in failed - user is null');
        if (mounted) {
          _showErrorDialog('Local admin sign in failed. Please try again.');
        }
      }
    } catch (e) {
      print('🔐 Local admin sign in error: $e');
      if (mounted) {
        _showErrorDialog('Local admin sign in error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _currentProvider = '';
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        title: Text(
          'Authentication Failed',
          style: TextStyle(color: context.tokens.textPrimary),
        ),
        content: Text(
          message,
          style: TextStyle(color: context.tokens.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: context.tokens.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    print('🔐 _navigateToHome called');
    try {
      // Navigate to home route to allow onboarding check
      Navigator.of(context).pushReplacementNamed('/home');
      print('🔐 Navigation to home route initiated');
    } catch (e) {
      print('🔐 Navigation error: $e');
      _showErrorDialog('Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for animation controllers - check if they're properly initialized
    try {
      // Test if controllers are working by accessing their value
      final _ = _particleController.value;
      final __ = _glowController.value;
    } catch (e) {
      print('⚠️ Animation controllers not properly initialized: $e');
      return Scaffold(
        backgroundColor: context.tokens.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.tokens.surface,
      body: Stack(
        children: [
          // Animated particle background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              try {
                return CustomPaint(
                  painter: ParticlesPainter(
                    particles: _particles,
                    animationValue: _particleController.value,
                    color: context.tokens.primary,
                  ),
                  size: Size.infinite,
                );
              } catch (e) {
                print('❌ Error in particle animation: $e');
                return const SizedBox.shrink(); // Fallback widget
              }
            },
          ),
          // Main gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.tokens.surface.withValues(alpha: 0.9),
                  context.tokens.onPrimaryContainer.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Main content area
          SafeArea(
            child: Padding(
              padding: UnifiedSpacing.screenPadding,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Massive MINDLOAD branding with enhanced particle glow animation
                            Column(
                              children: [
                                // Massive animated MINDLOAD title with dynamic glow
                                AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    try {
                                      return UnifiedText(
                                        'MINDLOAD',
                                        style: UnifiedTypography.displayLarge.copyWith(
                                          color: context.tokens.primary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 8,
                                          fontSize: 42, // Smaller, more reasonable size
                                          height: 0.9,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 40 * _glowAnimation.value,
                                              color: context.tokens.primary.withValues(
                                                  alpha: 0.9 * _glowAnimation.value),
                                            ),
                                            Shadow(
                                              blurRadius: 80 * _glowAnimation.value,
                                              color: context.tokens.primary.withValues(
                                                  alpha: 0.7 * _glowAnimation.value),
                                            ),
                                            Shadow(
                                              blurRadius: 120 * _glowAnimation.value,
                                              color: context.tokens.primary.withValues(
                                                  alpha: 0.5 * _glowAnimation.value),
                                            ),
                                            Shadow(
                                              blurRadius: 160 * _glowAnimation.value,
                                              color: context.tokens.primary.withValues(
                                                  alpha: 0.3 * _glowAnimation.value),
                                            ),
                                          ],
                                        ),
                                      );
                                    } catch (e) {
                                      print('❌ Error in glow animation: $e');
                                      return UnifiedText(
                                        'MINDLOAD',
                                        style: UnifiedTypography.displayLarge.copyWith(
                                          color: context.tokens.primary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 8,
                                          fontSize: 42,
                                          height: 0.9,
                                        ),
                                      ); // Fallback text
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // AI Study Interface subtitle with enhanced visibility
                                Text(
                                  'AI Study Interface',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    color: context.tokens.textPrimary,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: context.tokens.textPrimary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: UnifiedSpacing.sm),
                              ],
                            ),

                            SizedBox(height: UnifiedSpacing.xxl),

                            if (!_showEmailForm) ...[
                              // Section header for social login
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: UnifiedSpacing.md),
                                child: UnifiedText(
                                  'Sign in to continue',
                                  style: UnifiedTypography.titleMedium.copyWith(
                                    color: context.tokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Social sign-in buttons container
                              UnifiedCard(
                                padding: UnifiedSpacing.cardPadding,
                                borderRadius: UnifiedBorderRadius.lgRadius,
                                child: Column(
                                  children: [
                                    // Social sign-in buttons
                                    _buildSocialSignInButton(
                                      provider: AuthProvider.google,
                                      icon: Icons.g_mobiledata_rounded,
                                      label: 'Continue with Google',
                                      color: context.tokens.surface,
                                      textColor: context.tokens.textPrimary,
                                    ),

                                    SizedBox(height: UnifiedSpacing.lg),

                                    _buildSocialSignInButton(
                                      provider: AuthProvider.apple,
                                      icon: Icons.apple,
                                      label: 'Continue with Apple',
                                      color: context.tokens.surfaceAlt,
                                      textColor: context.tokens.textPrimary,
                                    ),

                                    SizedBox(height: UnifiedSpacing.lg),

                                    _buildSocialSignInButton(
                                      provider: AuthProvider.microsoft,
                                      icon: Icons.window_outlined,
                                      label: 'Continue with Microsoft',
                                      color: context.tokens.primary,
                                      textColor: context.tokens.onPrimary,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: UnifiedSpacing.xxl),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: context.tokens.outline.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: UnifiedSpacing.md),
                                    child: UnifiedText(
                                      'OR',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context.tokens.textPrimary
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: context.tokens.outline
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Email sign-in button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _isSigningIn
                                      ? null
                                      : () {
                                          setState(() {
                                            _showEmailForm = true;
                                          });
                                        },
                                  icon: const Icon(Icons.email_outlined),
                                  label: const Text('Continue with Email'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.tokens.textPrimary,
                                    side: BorderSide(
                                      color: context.tokens.outline
                                          .withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Admin test button (for development)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.tokens.secondary
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.tokens.secondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'DEVELOPER MODE',
                                      style: TextStyle(
                                        color: context.tokens.textPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed:
                                          _isSigningIn ? null : _signInAsAdmin,
                                      icon: _isSigningIn &&
                                              _currentProvider == 'admin'
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.admin_panel_settings,
                                              size: 16,
                                              color: context.tokens.secondary,
                                            ),
                                      label: Text(
                                        'Local Admin Test',
                                        style: TextStyle(
                                          color: context.tokens.secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Works offline without Firebase',
                                      style: TextStyle(
                                        color: context.tokens.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Email form
                              _buildEmailForm(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'v1.0.0 • SECURE NEURAL NETWORK',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.tokens.textSecondary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSignInButton({
    required AuthProvider provider,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    final isLoading = _isSigningIn && _currentProvider == provider.name;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSigningIn ? null : () => _signInWithProvider(provider),
        key: Key('${provider.name}_signin_button'),
        autofocus: false,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: textColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: textColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return textColor.withValues(alpha: 0.1);
              }
              if (states.contains(MaterialState.hovered)) {
                return textColor.withValues(alpha: 0.05);
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.onPrimaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.tokens.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isSignUp ? 'Create Account' : 'Sign In',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showEmailForm = false;
                      _isSignUp = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isSignUp) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (_isSignUp && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSigningIn ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.tokens.primary,
                  foregroundColor: context.tokens.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSigningIn && _currentProvider == 'email'
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isSigningIn
                    ? null
                    : () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Sign up",
                  style: TextStyle(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlesPainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    for (final particle in particles) {
      final progress = (animationValue * particle.speed) % 1.0;
      final currentY = (particle.y + progress) % 1.0;
      final currentX =
          particle.x + sin(progress * 2 * pi + particle.y * 10) * 0.1;

      paint.color = color.withValues(alpha: particle.opacity * (1 - progress));

      canvas.drawCircle(
        Offset(
          (currentX % 1.0) * size.width,
          currentY * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
