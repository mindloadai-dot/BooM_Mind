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
  State<_EnhancedThemeSelectionDialog> createState() => _EnhancedThemeSelectionDialogState();
}

class _EnhancedThemeSelectionDialogState extends State<_EnhancedThemeSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  AppTheme? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeManager.instance.currentTheme;
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
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption('Light', Icons.wb_sunny_outlined, AppTheme.classic),
                const SizedBox(height: 12),
                _buildThemeOption('Dark', Icons.nightlight_outlined, AppTheme.darkMode),
                const SizedBox(height: 12),
                _buildThemeOption('Matrix', Icons.grid_on_outlined, AppTheme.matrix),
                const SizedBox(height: 12),
                _buildThemeOption('Retro', Icons.radio_outlined, AppTheme.retro),
                const SizedBox(height: 12),
                _buildThemeOption('Cyber Neon', Icons.electric_bolt_outlined, AppTheme.cyberNeon),
                const SizedBox(height: 12),
                _buildThemeOption('Minimal', Icons.format_clear_outlined, AppTheme.minimal),
                const SizedBox(height: 12),
                _buildThemeOption('Purple Neon', Icons.auto_awesome_outlined, AppTheme.purpleNeon),
                const SizedBox(height: 12),
                _buildThemeOption('Ocean Depths', Icons.water_drop_outlined, AppTheme.oceanDepths),
                const SizedBox(height: 12),
                _buildThemeOption('Sunset Glow', Icons.wb_sunny_outlined, AppTheme.sunsetGlow),
                const SizedBox(height: 12),
                _buildThemeOption('Forest Night', Icons.forest_outlined, AppTheme.forestNight),
              ],
            ),
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

  Widget _buildThemeOption(String title, IconData icon, AppTheme theme) {
    final isSelected = _selectedTheme == theme;
    final themeManager = ThemeManager.instance;
    final tokens = themeManager.getSemanticTokens(theme);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedbackService().lightImpact();
          
          try {
            await ThemeManager.instance.setTheme(theme);
            setState(() {
              _selectedTheme = theme;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme changed to $title'),
                backgroundColor: context.tokens.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? tokens.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? tokens.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isSelected ? tokens.primary : context.tokens.primary, 
                size: 24
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? tokens.primary : context.tokens.textPrimary,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: tokens.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
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
