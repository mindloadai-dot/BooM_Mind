import 'package:flutter/material.dart';
import 'package:mindload/services/enhanced_onboarding_service.dart';
import 'package:mindload/services/mandatory_onboarding_service.dart';
import 'package:mindload/screens/notification_settings_screen.dart';
import 'package:mindload/screens/my_plan_screen.dart';
import 'package:mindload/screens/privacy_security_screen.dart';
import 'package:mindload/screens/profile_screen.dart';
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

  late AnimationController _headerController;
  late AnimationController _sectionsController;
  late AnimationController _themeController;
  late AnimationController _actionsController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _sectionsScaleAnimation;
  late Animation<double> _themeFadeAnimation;
  late Animation<double> _actionsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _sectionsController.dispose();
    _themeController.dispose();
    _actionsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _sectionsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _sectionsScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _sectionsController, curve: Curves.easeOutCubic),
    );

    _themeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _themeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _themeController, curve: Curves.easeIn),
    );

    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _actionsSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionsController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 200), () => _sectionsController.forward());
    Future.delayed(
        const Duration(milliseconds: 400), () => _themeController.forward());
    Future.delayed(
        const Duration(milliseconds: 600), () => _actionsController.forward());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      appBar: const MindloadAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildThemeSection(),
            const SizedBox(height: 24),
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
            const SizedBox(height: 24),
            _buildOnboardingSection(),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildSignOutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.tokens.primary.withOpacity(0.1),
                context.tokens.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.tokens.primary,
                      context.tokens.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.tokens.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings,
                  size: 30,
                  color: context.tokens.onPrimary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Settings',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.tokens.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your MindLoad experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return ScaleTransition(
      scale: _sectionsScaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: context.tokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appearance & Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Theme Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.tokens.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.tokens.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.tokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: context.tokens.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Theme',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.tokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getThemeDisplayName(
                              ThemeManager.instance.currentTheme),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEnhancedThemeDialog,
                    icon: Icon(
                      Icons.edit,
                      color: context.tokens.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: context.tokens.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Theme Preview
            _buildThemePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview() {
    final currentTheme = ThemeManager.instance.currentTheme;
    final previewColors = _getThemePreviewColors(currentTheme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: previewColors,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: previewColors[0].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: previewColors[0].withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: previewColors[1].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return FadeTransition(
      opacity: _themeFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: context.tokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPreferenceTile(
              'Notifications',
              'Configure study reminders and alerts',
              Icons.notifications,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _buildPreferenceTile(
              'Accessibility',
              'Customize text size and contrast',
              Icons.accessibility,
              () {
                // TODO: Navigate to accessibility settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Accessibility settings coming soon')),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPreferenceTile(
              'Privacy & Security',
              'Manage data and account security',
              Icons.security,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacySecurityScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreferenceTile(
            'My Plan & Tokens',
            'Manage subscription and token balance',
            Icons.card_membership,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyPlanScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'Profile Settings',
            'Edit account information',
            Icons.person,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'Delete Account',
            'Permanently remove your account and all data',
            Icons.delete_forever,
            () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Help & Onboarding',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreferenceTile(
            'Reset Onboarding',
            'Show welcome dialogs again',
            Icons.refresh,
            _showResetOnboardingDialog,
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'Reset Mandatory Onboarding',
            'Show first-time setup again',
            Icons.settings_backup_restore,
            _showResetMandatoryOnboardingDialog,
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'Test Welcome Dialog',
            'Preview the welcome screen',
            Icons.preview_rounded,
            _showTestWelcomeDialog,
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'About MindLoad',
            'App version and information',
            Icons.info_outline,
            _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreferenceTile(
            'Help & FAQ',
            'Get help and find answers',
            Icons.help,
            () {
              // TODO: Navigate to help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help screen coming soon')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            'Send Feedback',
            'Help us improve MindLoad',
            Icons.feedback,
            () {
              // TODO: Implement feedback functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.tokens.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? context.tokens.error.withOpacity(0.1)
                      : context.tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? context.tokens.error
                      : context.tokens.primary,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.tokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SlideTransition(
      position:
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _actionsController, curve: Curves.easeOutCubic),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.tokens.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tokens.error.withOpacity(0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showSignOutDialog,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: context.tokens.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.tokens.error,
                          fontWeight: FontWeight.w600,
                        ),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: context.tokens.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Choose Your Theme',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.tokens.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Theme Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: AppTheme.values.length,
                itemBuilder: (context, index) {
                  final theme = AppTheme.values[index];
                  final isSelected =
                      theme == ThemeManager.instance.currentTheme;
                  final previewColors = _getThemePreviewColors(theme);

                  return _buildThemeOption(theme, isSelected, previewColors);
                },
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.tokens.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      AppTheme theme, bool isSelected, List<Color> previewColors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ThemeManager.instance.setTheme(theme);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? context.tokens.primary.withOpacity(0.1)
                : context.tokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.tokens.primary
                  : context.tokens.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Theme Preview
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: previewColors,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),

                // Theme Name
                Text(
                  _getThemeDisplayName(theme),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.tokens.primary
                            : context.tokens.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),

                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Icon(
                    Icons.check_circle,
                    color: context.tokens.primary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return 'Classic';
      case AppTheme.matrix:
        return 'Matrix';
      case AppTheme.retro:
        return 'Retro';
      case AppTheme.cyberNeon:
        return 'Cyber Neon';
      case AppTheme.darkMode:
        return 'Dark Mode';
      case AppTheme.minimal:
        return 'Minimal';
      case AppTheme.purpleNeon:
        return 'Purple Neon';
    }
  }

  List<Color> _getThemePreviewColors(AppTheme theme) {
    switch (theme) {
      case AppTheme.classic:
        return [Colors.blue, Colors.blue.shade700];
      case AppTheme.matrix:
        return [Colors.green, Colors.green.shade700];
      case AppTheme.retro:
        return [Colors.orange, Colors.orange.shade700];
      case AppTheme.cyberNeon:
        return [Colors.cyan, Colors.cyan.shade700];
      case AppTheme.darkMode:
        return [Colors.grey.shade800, Colors.grey.shade900];
      case AppTheme.minimal:
        return [Colors.grey.shade400, Colors.grey.shade600];
      case AppTheme.purpleNeon:
        return [Colors.purple, Colors.purple.shade700];
    }
  }

  void _showResetOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.refresh,
              color: context.tokens.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Onboarding',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will show the welcome dialogs again the next time you open the app. '
          'Are you sure you want to continue?',
          style: TextStyle(color: context.tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetOnboarding();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.primary,
              foregroundColor: context.tokens.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    HapticFeedbackService().warning();
    setState(() {
      _isResettingOnboarding = true;
    });

    try {
      await EnhancedOnboardingService().resetOnboarding();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Onboarding preferences reset successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset onboarding: $e'),
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

  void _showTestWelcomeDialog() async {
    await EnhancedOnboardingService().showWelcomeDialog(context);
  }

  void _showResetMandatoryOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.settings_backup_restore,
              color: context.tokens.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Mandatory Onboarding',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will show the mandatory first-time setup again, requiring you to set up your nickname and learn about features. '
          'Are you sure you want to continue?',
          style: TextStyle(color: context.tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetMandatoryOnboarding();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.primary,
              foregroundColor: context.tokens.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetMandatoryOnboarding() async {
    HapticFeedbackService().warning();
    setState(() {
      _isResettingOnboarding = true;
    });

    try {
      await MandatoryOnboardingService.instance.resetOnboarding();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mandatory onboarding reset successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset mandatory onboarding: $e'),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info,
              color: context.tokens.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'About MindLoad',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MindLoad - AI Study Companion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Transform your study materials with AI-powered learning. '
              'Create flashcards, quizzes, and study sets from text or YouTube videos.',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text('• AI-powered study material generation',
                style: TextStyle(color: context.tokens.textSecondary)),
            Text('• YouTube video transcript processing',
                style: TextStyle(color: context.tokens.textSecondary)),
            Text('• Smart flashcards with spaced repetition',
                style: TextStyle(color: context.tokens.textSecondary)),
            Text('• Ultra Mode for focused study sessions',
                style: TextStyle(color: context.tokens.textSecondary)),
            Text('• Cross-platform synchronization',
                style: TextStyle(color: context.tokens.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.delete_forever,
              color: context.tokens.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted:',
              style: TextStyle(color: context.tokens.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              '• Study sets and flashcards',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            Text(
              '• Quiz results and progress',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            Text(
              '• Profile and preferences',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            Text(
              '• Subscription and token data',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'To confirm deletion, long-press the delete button below.',
              style: TextStyle(
                color: context.tokens.warning,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
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
          GestureDetector(
            onLongPress: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Container(
              decoration: BoxDecoration(
                color: context.tokens.error,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Delete Account',
                style: TextStyle(
                  color: context.tokens.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: context.tokens.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? You will need to sign in again to access your account.',
          style: TextStyle(color: context.tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.error,
              foregroundColor: context.tokens.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    HapticFeedbackService().warning();
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: context.tokens.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.tokens.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Deleting your account...',
                style: TextStyle(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments. Please do not close the app.',
                style: TextStyle(
                  color: context.tokens.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Provide haptic feedback
      HapticFeedbackService().warning();

      // Delete the account
      await AuthService.instance.deleteAccount();

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: context.tokens.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to auth screen
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: context.tokens.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
