import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mindload/services/auth_service.dart';

import 'package:mindload/theme.dart';
import 'package:mindload/widgets/unified_design_system.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _errorMessage = '';

  // Email form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _showEmailForm = false;

  // Animation controllers for particles and glow - identical to social auth screen
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

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      _errorMessage = '';
    });
  }

  void _setError(String error) {
    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    try {
      final user = await AuthService.instance.signInWithGoogleSafe();
      if (user != null) {
        _navigateToHome();
      } else {
        _setError('Google sign in was cancelled');
      }
    } catch (e) {
      _setError('Google sign in failed: ${e.toString()}');
    }
  }

  Future<void> _handleAppleSignIn() async {
    _setLoading(true);
    try {
      final user = await AuthService.instance.signInWithApple();
      if (user != null) {
        _navigateToHome();
      } else {
        _setError('Apple sign in was cancelled');
      }
    } catch (e) {
      _setError('Apple sign in failed: ${e.toString()}');
    }
  }

  Future<void> _handleMicrosoftSignIn() async {
    _setLoading(true);
    try {
      final user = await AuthService.instance.signInWithMicrosoft();
      if (user != null) {
        _navigateToHome();
      } else {
        _setError('Microsoft sign in was cancelled');
      }
    } catch (e) {
      _setError('Microsoft sign in failed: ${e.toString()}');
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      AuthUser? user;

      if (_isSignUp) {
        user = await AuthService.instance.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        user = await AuthService.instance.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (user != null) {
        _navigateToHome();
      } else {
        _setError('Email authentication failed');
      }
    } catch (e) {
      String errorMsg = _getUserFriendlyError(e.toString());
      _setError(errorMsg);
    }
  }

  Future<void> _handleAdminLogin() async {
    _setLoading(true);
    try {
      final user = await AuthService.instance.signInAsAdminTest();
      if (user != null) {
        _navigateToHome();
      } else {
        _setError('Admin login failed');
      }
    } catch (e) {
      String errorMsg = _getUserFriendlyError(e.toString());
      _setError(errorMsg);
    }
  }

  void _navigateToHome() {
    // Navigate to home route to allow onboarding check
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _toggleEmailForm() {
    setState(() {
      _showEmailForm = !_showEmailForm;
      _errorMessage = '';
    });
  }

  void _toggleSignUpMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = '';
    });
  }

  /// Convert Firebase errors to user-friendly messages
  String _getUserFriendlyError(String error) {
    String errorMessage = error.toLowerCase();

    if (errorMessage.contains('firebase setup incomplete') ||
        errorMessage.contains('configuration-not-found') ||
        errorMessage.contains('firebase configuration error') ||
        errorMessage.contains('placeholder')) {
      return 'App setup incomplete. Please configure Firebase for this platform.';
    } else if (errorMessage.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('exception: ')) {
      return errorMessage
          .replaceFirst('exception: ', '')
          .replaceFirst('Exception: ', '');
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Stack(
        children: [
          // Animated particle background - identical to social auth screen
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                  color: tokens.primary,
                ),
                size: Size.infinite,
              );
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
                  tokens.bg.withValues(alpha: 0.9),
                  tokens.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          // Main content area
          SafeArea(
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
                    const SizedBox(height: UnifiedSpacing.xl),

                    // Massive MINDLOAD branding with enhanced particle glow animation - identical to social auth
                    Column(
                      children: [
                        // Massive animated MINDLOAD title with dynamic glow - identical to social auth
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return UnifiedText(
                              'MINDLOAD',
                              style: UnifiedTypography.displayLarge.copyWith(
                                color: tokens.brandTitle,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                fontSize: 42, // Smaller, more reasonable size
                                height: 0.9,
                                shadows: [
                                  Shadow(
                                    blurRadius: 40 * _glowAnimation.value,
                                    color: tokens.brandTitle.withValues(
                                        alpha: 0.9 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    blurRadius: 80 * _glowAnimation.value,
                                    color: tokens.brandTitle.withValues(
                                        alpha: 0.7 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    blurRadius: 120 * _glowAnimation.value,
                                    color: tokens.brandTitle.withValues(
                                        alpha: 0.5 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    blurRadius: 160 * _glowAnimation.value,
                                    color: tokens.brandTitle.withValues(
                                        alpha: 0.3 * _glowAnimation.value),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),

                        const SizedBox(height: UnifiedSpacing.md),

                        // AI Study Interface subtitle with enhanced visibility - identical to social auth
                        UnifiedText(
                          'AI Study Interface',
                          style: UnifiedTypography.headlineMedium.copyWith(
                            color: tokens.textPrimary,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color:
                                    tokens.textPrimary.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: UnifiedSpacing.sm),
                      ],
                    ),

                    const SizedBox(height: UnifiedSpacing.xxxl),

                    // Authentication methods
                    if (!_showEmailForm) ...[
                      // Social sign-in buttons - identical styling to social auth screen
                      _buildSocialSignInButton(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Continue with Google',
                        color: tokens.surface,
                        textColor: tokens.textPrimary,
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                      ),

                      const SizedBox(height: UnifiedSpacing.md),

                      _buildSocialSignInButton(
                        icon: Icons.apple,
                        label: 'Continue with Apple',
                        color: tokens.surfaceAlt,
                        textColor: tokens.textPrimary,
                        onPressed: _isLoading ? null : _handleAppleSignIn,
                      ),

                      const SizedBox(height: UnifiedSpacing.md),

                      _buildSocialSignInButton(
                        icon: Icons.window_outlined,
                        label: 'Continue with Microsoft',
                        color: tokens.primary,
                        textColor: tokens.onPrimary,
                        onPressed: _isLoading ? null : _handleMicrosoftSignIn,
                      ),

                      const SizedBox(height: UnifiedSpacing.xl),

                      // Divider - identical to social auth screen
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: UnifiedSpacing.md),
                            child: UnifiedText(
                              'OR',
                              style: UnifiedTypography.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: UnifiedSpacing.xl),

                      // Email sign-in button - identical to social auth screen
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _toggleEmailForm,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Continue with Email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Admin test button (for development) - identical to social auth screen
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'DEVELOPER MODE',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: _isLoading ? null : _handleAdminLogin,
                              icon: _isLoading
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Icon(
                                      Icons.admin_panel_settings,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                              label: Text(
                                'Local Admin Test',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              'Works offline without Firebase',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Email form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tokens.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: tokens.textEmphasis,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.email,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                ),
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
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 8,
                                  shadowColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(),
                                      )
                                    : Text(
                                        _isSignUp
                                            ? 'CREATE ACCOUNT'
                                            : 'SIGN IN',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed:
                                    _isLoading ? null : _toggleSignUpMode,
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Sign In'
                                      : 'Need an account? Sign Up',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _toggleEmailForm,
                                child: Text(
                                  'Back to other options',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Bottom info - identical to social auth screen
                    Text(
                      'v1.0.0+25 • SECURE NEURAL NETWORK',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            letterSpacing: 1,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSignInButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
            : UnifiedIcon(icon, color: textColor),
        label: UnifiedText(
          label,
          style: UnifiedTypography.titleMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: UnifiedBorderRadius.lgRadius,
          ),
          elevation: 0,
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
