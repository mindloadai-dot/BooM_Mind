import 'package:flutter/material.dart';
import 'package:mindload/services/unified_onboarding_service.dart';
import 'package:mindload/theme.dart';

import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/privacy_security_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
import 'package:mindload/screens/notification_settings_screen.dart';
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
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isResettingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
  }

  void _startAnimations() {
    _mainController.forward();
  }

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
              _buildSettingsHeader(),
              const SizedBox(height: 24),
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildAppearanceSection(),
              const SizedBox(height: 24),
              _buildNotificationsSection(),
              const SizedBox(height: 24),
              _buildPrivacySecuritySection(),
              const SizedBox(height: 24),
              _buildAccountSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: context.tokens.outline.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Settings Icon with scale animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.tokens.primary,
                        context.tokens.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: context.tokens.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings,
                    color: context.tokens.onPrimary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Settings Info with slide animation
              Expanded(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _mainController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                  )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.tokens.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize your experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildAnimatedSettingsCard(
      'Profile',
      [
        _buildAnimatedSettingsTile(
          'My Profile',
          'Manage your profile information',
          Icons.person_outline,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          ),
          0,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildAnimatedSettingsCard(
      'Appearance',
      [
        _buildAnimatedSettingsTile(
          'Theme',
          'Choose your app theme',
          Icons.palette_outlined,
          () => _showEnhancedThemeDialog(),
          0,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildAnimatedSettingsCard(
      'Notifications',
      [
        _buildAnimatedSettingsTile(
          'Notification Settings',
          'Manage your notification preferences',
          Icons.notifications_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationSettingsScreen(),
            ),
          ),
          0,
        ),
      ],
    );
  }

  Widget _buildPrivacySecuritySection() {
    return _buildAnimatedSettingsCard(
      'Privacy & Security',
      [
        _buildAnimatedSettingsTile(
          'Privacy & Security',
          'Manage your privacy settings',
          Icons.security_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacySecurityScreen(),
            ),
          ),
          0,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildAnimatedSettingsCard(
      'Account',
      [
        _buildAnimatedSettingsTile(
          'My Plan',
          'View and manage your subscription',
          Icons.card_membership_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyPlanScreen(),
            ),
          ),
          0,
        ),
        _buildAnimatedSettingsTile(
          'Reset Onboarding',
          'Go through the welcome flow again',
          Icons.refresh_outlined,
          _resetOnboarding,
          1,
          isLoading: _isResettingOnboarding,
        ),
        _buildAnimatedSettingsTile(
          'Sign Out',
          'Sign out of your account',
          Icons.logout_outlined,
          _signOut,
          2,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildAnimatedSettingsCard(String title, List<Widget> items) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: context.tokens.outline.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              ...items,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    int index, {
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: Interval(
            (0.3 + (index * 0.1)).clamp(0.0, 1.0),
            (0.9 + (index * 0.02)).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(
              (0.3 + (index * 0.1)).clamp(0.0, 1.0),
              (0.9 + (index * 0.02)).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? context.tokens.error.withOpacity(0.1)
                          : context.tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive
                          ? context.tokens.error
                          : context.tokens.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: isDestructive
                                        ? context.tokens.error
                                        : context.tokens.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.tokens.textSecondary,
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
                        color: context.tokens.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: context.tokens.textTertiary,
                      size: 20,
                    ),
                ],
              ),
            ),
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
      builder: (context) => _EnhancedThemeSelectionDialog(),
    );
  }

  Future<void> _resetOnboarding() async {
    setState(() {
      _isResettingOnboarding = true;
    });

    try {
      await UnifiedOnboardingService().resetOnboarding();
      HapticFeedbackService().success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Onboarding reset successfully!'),
            backgroundColor: context.tokens.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset onboarding: $e'),
            backgroundColor: context.tokens.error,
            behavior: SnackBarBehavior.floating,
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
    HapticFeedbackService().lightImpact();

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: context.tokens.error),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await AuthService.instance.signOut();
        HapticFeedbackService().success();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: context.tokens.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

class _EnhancedThemeSelectionDialog extends StatefulWidget {
  @override
  State<_EnhancedThemeSelectionDialog> createState() =>
      _EnhancedThemeSelectionDialogState();
}

class _EnhancedThemeSelectionDialogState
    extends State<_EnhancedThemeSelectionDialog> with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _backgroundController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _backgroundAnimation;

  AppTheme? _selectedTheme;
  AppTheme? _hoveredTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeManager.instance.currentTheme;

    // Multiple animation controllers for rich effects
    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Complex entrance animations
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Start all animations
    _dialogController.forward();
    _staggerController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat(reverse: true);
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _staggerController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_dialogController, _pulseController, _backgroundController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Animated background blur
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.black
                    .withOpacity(0.3 + 0.2 * _backgroundAnimation.value),
              ),
            ),

            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: screenSize.width > 600 ? 80 : 16,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 480,
                          maxHeight: screenSize.height * 0.9,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                                spreadRadius: -5,
                              ),
                              BoxShadow(
                                color: tokens.primary.withOpacity(0.15),
                                blurRadius: 60,
                                offset: const Offset(0, 30),
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSpectacularHeader(tokens),
                              Flexible(
                                child: _buildResponsiveThemeGrid(
                                    tokens, screenSize),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpectacularHeader(dynamic tokens) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tokens.primary.withOpacity(0.2),
                tokens.primary.withOpacity(0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Row(
            children: [
              // Pulsing animated icon
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tokens.primary,
                        tokens.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Header text with slide animation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Choose Your Theme',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Transform your experience with stunning themes',
                      style: TextStyle(
                        fontSize: 15,
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Animated close button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tokens.surfaceAlt.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tokens.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: tokens.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveThemeGrid(dynamic tokens, Size screenSize) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: AnimatedBuilder(
        animation: _staggerController,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid calculation
              final isWideScreen = constraints.maxWidth > 400;
              final crossAxisCount = isWideScreen ? 2 : 1;
              final childAspectRatio = isWideScreen ? 3.0 : 4.2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: AppTheme.values.length,
                itemBuilder: (context, index) {
                  final theme = AppTheme.values[index];

                  // Stagger animation with elastic curve
                  final delay = index * 0.08;
                  final animationValue = Curves.elasticOut.transform(
                    ((_staggerController.value - delay).clamp(0.0, 1.0)),
                  );

                  return Transform.translate(
                    offset: Offset(0, 40 * (1 - animationValue)),
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * animationValue),
                      child: Opacity(
                        opacity: animationValue,
                        child: _buildSpectacularThemeCard(theme, tokens),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSpectacularThemeCard(AppTheme theme, dynamic tokens) {
    final isSelected = _selectedTheme == theme;
    final isHovered = _hoveredTheme == theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTheme = theme),
      onExit: (_) => setState(() => _hoveredTheme = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(isHovered
              ? 1.05
              : isSelected
                  ? 1.02
                  : 1.0)
          ..translate(
              0.0,
              isHovered
                  ? -4.0
                  : isSelected
                      ? -2.0
                      : 0.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    tokens.primary.withOpacity(0.2),
                    tokens.primary.withOpacity(0.05),
                    Colors.transparent,
                  ]
                : [
                    tokens.surfaceAlt,
                    tokens.surfaceAlt.withOpacity(0.8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? tokens.primary
                : isHovered
                    ? tokens.primary.withOpacity(0.4)
                    : Colors.transparent,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: tokens.primary.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: tokens.primary.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
            ] else if (isHovered) ...[
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -3,
              ),
            ],
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _selectThemeWithAnimation(theme),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAnimatedThemePreview(theme, tokens, isSelected),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getThemeDisplayName(theme),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getThemeDescription(theme),
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildAnimatedSelectionIndicator(tokens, isSelected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedThemePreview(
      AppTheme theme, dynamic tokens, bool isSelected) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerController, _pulseController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Main preview container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _getThemeGradient(theme),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color:
                        _getThemeGradient(theme).colors.first.withOpacity(0.4),
                    blurRadius: isSelected ? 16 : 10,
                    offset: const Offset(0, 6),
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Shimmer effect for selected theme
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(-1.5 + _shimmerAnimation.value, -1.0),
                      end: Alignment(1.5 + _shimmerAnimation.value, 1.0),
                    ),
                  ),
                ),
              ),

            // Pulsing ring for selected theme
            if (isSelected)
              Positioned.fill(
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedSelectionIndicator(dynamic tokens, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? tokens.primary : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? tokens.primary
              : tokens.textSecondary.withOpacity(0.4),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: tokens.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: isSelected ? 1.0 : 0.0,
        curve: Curves.elasticOut,
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _selectThemeWithAnimation(AppTheme theme) async {
    if (_selectedTheme == theme) return;

    setState(() {
      _selectedTheme = theme;
    });

    // Enhanced haptic feedback
    HapticFeedbackService().mediumImpact();

    // Visual feedback delay with animation
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await ThemeManager.instance.setTheme(theme);

      // Success animation
      await Future.delayed(const Duration(milliseconds: 150));
      Navigator.pop(context);

      // Enhanced success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: _getThemeGradient(theme),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getThemeGradient(theme)
                          .colors
                          .first
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✨ Theme Applied!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Now using ${_getThemeDisplayName(theme)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
          elevation: 8,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Failed to apply theme: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: context.tokens.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  LinearGradient _getThemeGradient(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.darkMode:
        return const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF212121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.matrix:
        return const LinearGradient(
          colors: [Color(0xFF00FF00), Color(0xFF00C851)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.retro:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.cyberNeon:
        return const LinearGradient(
          colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.minimal:
        return const LinearGradient(
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.purpleNeon:
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.oceanDepths:
        return const LinearGradient(
          colors: [Color(0xFF006064), Color(0xFF00838F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.sunsetGlow:
        return const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppTheme.forestNight:
        return const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Classic Blue';
      case AppTheme.darkMode:
        return 'Dark Mode';
      case AppTheme.matrix:
        return 'Matrix Green';
      case AppTheme.retro:
        return 'Retro Vibes';
      case AppTheme.cyberNeon:
        return 'Cyber Neon';
      case AppTheme.minimal:
        return 'Minimal';
      case AppTheme.purpleNeon:
        return 'Purple Neon';
      case AppTheme.oceanDepths:
        return 'Ocean Depths';
      case AppTheme.sunsetGlow:
        return 'Sunset Glow';
      case AppTheme.forestNight:
        return 'Forest Night';
    }
  }

  String _getThemeDescription(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Clean professional design';
      case AppTheme.darkMode:
        return 'Easy on the eyes';
      case AppTheme.matrix:
        return 'Digital matrix world';
      case AppTheme.retro:
        return 'Nostalgic 80s vibes';
      case AppTheme.cyberNeon:
        return 'Futuristic cyberpunk';
      case AppTheme.minimal:
        return 'Simple and focused';
      case AppTheme.purpleNeon:
        return 'Electric purple energy';
      case AppTheme.oceanDepths:
        return 'Deep sea tranquility';
      case AppTheme.sunsetGlow:
        return 'Warm golden vibes';
      case AppTheme.forestNight:
        return 'Nature-inspired calm';
    }
  }
}

class _ThemeSelectionDialog extends StatefulWidget {
  @override
  State<_ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<_ThemeSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Choose Theme',
            style: TextStyle(
              color: context.tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption('Light', Icons.wb_sunny_outlined, 'light'),
              const SizedBox(height: 12),
              _buildThemeOption('Dark', Icons.nightlight_outlined, 'dark'),
              const SizedBox(height: 12),
              _buildThemeOption(
                  'System', Icons.settings_system_daydream_outlined, 'system'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.tokens.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, String theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedbackService().lightImpact();

          // Map theme string to AppTheme enum
          AppTheme selectedTheme;
          switch (theme) {
            case 'light':
              selectedTheme = AppTheme.classic;
              break;
            case 'dark':
              selectedTheme = AppTheme.darkMode;
              break;
            case 'system':
              selectedTheme = AppTheme.minimal; // System theme
              break;
            default:
              selectedTheme = AppTheme.classic;
          }

          try {
            await ThemeManager.instance.setTheme(selectedTheme);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme changed to $title'),
                backgroundColor: context.tokens.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to change theme: $e'),
                backgroundColor: context.tokens.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: context.tokens.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: context.tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
