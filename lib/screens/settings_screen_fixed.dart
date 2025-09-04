import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mindload/services/unified_onboarding_service.dart';

import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/privacy_security_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
import 'package:mindload/screens/notification_settings_screen.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool _isResettingOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: MindloadAppBar(
        title: 'Settings',
        backgroundColor: tokens.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildSection(
                context,
                'Profile',
                [
                  _buildSettingsItem(
                    context,
                    'My Profile',
                    'Manage your profile information',
                    Icons.person_outline,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Appearance Section
              _buildSection(
                context,
                'Appearance',
                [
                  _buildSettingsItem(
                    context,
                    'Theme',
                    'Choose your app theme',
                    Icons.palette_outlined,
                    () => _showEnhancedThemeDialog(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSection(
                context,
                'Notifications',
                [
                  _buildSettingsItem(
                    context,
                    'Notification Settings',
                    'Manage your notification preferences',
                    Icons.notifications_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Privacy & Security Section
              _buildSection(
                context,
                'Privacy & Security',
                [
                  _buildSettingsItem(
                    context,
                    'Privacy & Security',
                    'Manage your privacy settings',
                    Icons.security_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySecurityScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Section
              _buildSection(
                context,
                'Account',
                [
                  _buildSettingsItem(
                    context,
                    'My Plan',
                    'View and manage your subscription',
                    Icons.card_membership_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPlanScreen(),
                      ),
                    ),
                  ),
                  _buildSettingsItem(
                    context,
                    'Reset Onboarding',
                    'Go through the welcome flow again',
                    Icons.refresh_outlined,
                    _resetOnboarding,
                    isLoading: _isResettingOnboarding,
                  ),
                  _buildSettingsItem(
                    context,
                    'Sign Out',
                    'Sign out of your account',
                    Icons.logout_outlined,
                    _signOut,
                    isDestructive: true,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.borderDefault.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: items
                .map((item) => [item, if (item != items.last) _buildDivider()])
                .expand((element) => element)
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.tokens.borderDefault.withOpacity(0.1),
      indent: 56,
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final tokens = context.tokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? tokens.error.withOpacity(0.1)
                      : tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? tokens.error : tokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDestructive
                                ? tokens.error
                                : tokens.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.primary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: tokens.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnhancedThemeDialog() {
    HapticFeedbackService().lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ThemeSelectionDialog(),
    );
  }

  Future<void> _resetOnboarding() async {
    setState(() {
      _isResettingOnboarding = true;
    });

    try {
      await UnifiedOnboardingService().resetOnboarding();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Onboarding reset successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset onboarding: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingOnboarding = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  List<Color> _getThemePreviewColors(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case AppTheme.darkMode:
        return [Colors.grey.shade700, Colors.grey.shade900];
      case AppTheme.matrix:
        return [Colors.green.shade400, Colors.green.shade700];
      case AppTheme.forestNight:
        return [Colors.green.shade600, Colors.green.shade800];
      case AppTheme.oceanDepths:
        return [Colors.teal.shade400, Colors.cyan.shade600];
      case AppTheme.sunsetGlow:
        return [Colors.orange.shade400, Colors.pink.shade400];
      case AppTheme.purpleNeon:
        return [Colors.purple.shade300, Colors.purple.shade500];
      case AppTheme.cyberNeon:
        return [Colors.cyan.shade400, Colors.purple.shade400];
      case AppTheme.retro:
        return [Colors.orange.shade600, Colors.red.shade600];
      case AppTheme.minimal:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Classic';
      case AppTheme.darkMode:
        return 'Dark Mode';
      case AppTheme.matrix:
        return 'Matrix';
      case AppTheme.forestNight:
        return 'Forest Night';
      case AppTheme.oceanDepths:
        return 'Ocean Depths';
      case AppTheme.sunsetGlow:
        return 'Sunset Glow';
      case AppTheme.purpleNeon:
        return 'Purple Neon';
      case AppTheme.cyberNeon:
        return 'Cyber Neon';
      case AppTheme.retro:
        return 'Retro';
      case AppTheme.minimal:
        return 'Minimal';
    }
  }
}

// Enhanced Theme Selection Dialog with Animations and Overflow Fixes
class _ThemeSelectionDialog extends StatefulWidget {
  @override
  State<_ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<_ThemeSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  AppTheme? _selectedTheme;
  bool _isAnimatingSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeManager.instance.currentTheme;

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Start entrance animations
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _selectTheme(AppTheme theme) async {
    if (_isAnimatingSelection) return;

    setState(() {
      _selectedTheme = theme;
      _isAnimatingSelection = true;
    });

    // Trigger celebration animations
    HapticFeedbackService().success();
    _pulseController.forward().then((_) => _pulseController.reverse());
    _sparkleController.forward();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 800));

    // Apply theme and close dialog
    if (mounted) {
      ThemeManager.instance.setTheme(theme);

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.palette, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🎨 Theme changed to ${_getThemeDisplayName(theme)}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: tokens.borderDefault.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.overlayDim.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with sparkle animation
                _buildAnimatedHeader(tokens),

                // Scrollable theme grid
                Flexible(
                  child: _buildThemeGrid(tokens),
                ),

                // Action buttons
                _buildActionButtons(tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          // Sparkle effects
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _SparklePainter(
                    animation: _sparkleAnimation,
                    color: tokens.primary,
                  ),
                ),
              );
            },
          ),

          // Main header content
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: tokens.primary,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Theme',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transform your experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(SemanticTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid: 2 columns for narrow screens, 3 for wide
          final crossAxisCount = constraints.maxWidth > 400 ? 3 : 2;
          final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) /
              crossAxisCount;
          final aspectRatio = itemWidth / 120; // Fixed height of 120

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: aspectRatio,
            ),
            itemCount: AppTheme.values.length,
            itemBuilder: (context, index) {
              final theme = AppTheme.values[index];
              return _buildAnimatedThemeOption(theme, tokens, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnimatedThemeOption(
      AppTheme theme, SemanticTokens tokens, int index) {
    final isSelected = _selectedTheme == theme;
    final isCurrentTheme = theme == ThemeManager.instance.currentTheme;
    final previewColors = _getThemePreviewColors(theme);

    return TweenAnimationBuilder<double>(
      duration:
          Duration(milliseconds: 300 + (index * 50)), // Staggered entrance
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(isSelected && _isAnimatingSelection ? 1.05 : 1.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectTheme(theme),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.primary.withOpacity(0.1)
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? tokens.primary
                            : tokens.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: tokens.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Theme Preview with animated gradient
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: previewColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: previewColors.first
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Theme Name
                          Text(
                            _getThemeDisplayName(theme),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? tokens.primary
                                          : tokens.textPrimary,
                                    ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Status indicators
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCurrentTheme)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: tokens.success,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 8,
                                        ),
                                  ),
                                ),
                              if (isSelected && !isCurrentTheme) ...[
                                const SizedBox(width: 4),
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: tokens.primary,
                                        size: 16,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: tokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getThemePreviewColors(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case AppTheme.darkMode:
        return [Colors.grey.shade700, Colors.grey.shade900];
      case AppTheme.matrix:
        return [Colors.green.shade400, Colors.green.shade700];
      case AppTheme.forestNight:
        return [Colors.green.shade600, Colors.green.shade800];
      case AppTheme.oceanDepths:
        return [Colors.teal.shade400, Colors.cyan.shade600];
      case AppTheme.sunsetGlow:
        return [Colors.orange.shade400, Colors.pink.shade400];
      case AppTheme.purpleNeon:
        return [Colors.purple.shade300, Colors.purple.shade500];
      case AppTheme.cyberNeon:
        return [Colors.cyan.shade400, Colors.purple.shade400];
      case AppTheme.retro:
        return [Colors.orange.shade600, Colors.red.shade600];
      case AppTheme.minimal:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Classic';
      case AppTheme.darkMode:
        return 'Dark Mode';
      case AppTheme.matrix:
        return 'Matrix';
      case AppTheme.forestNight:
        return 'Forest Night';
      case AppTheme.oceanDepths:
        return 'Ocean Depths';
      case AppTheme.sunsetGlow:
        return 'Sunset Glow';
      case AppTheme.purpleNeon:
        return 'Purple Neon';
      case AppTheme.cyberNeon:
        return 'Cyber Neon';
      case AppTheme.retro:
        return 'Retro';
      case AppTheme.minimal:
        return 'Minimal';
    }
  }
}

// Custom painter for sparkle effects
class _SparklePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _SparklePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * animation.value)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = math.Random(42); // Fixed seed for consistent sparkles

    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final sparkleSize = 4 + (random.nextDouble() * 6);

      final sparkleOpacity =
          (math.sin(animation.value * 2 * math.pi + i) + 1) / 2;
      paint.color = color.withOpacity(0.4 * sparkleOpacity * animation.value);

      // Draw sparkle as a cross
      canvas.drawLine(
        Offset(x - sparkleSize, y),
        Offset(x + sparkleSize, y),
        paint,
      );
      canvas.drawLine(
        Offset(x, y - sparkleSize),
        Offset(x, y + sparkleSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
