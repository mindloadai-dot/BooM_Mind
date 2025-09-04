import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/services/local_image_storage_service.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/screens/privacy_policy_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = false;
  bool _hapticFeedbackEnabled = true;
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load current settings from storage
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hapticFeedbackEnabled = prefs.getBool('haptic_feedback') ?? true;
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      _crashReportingEnabled = prefs.getBool('crash_reporting') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback', _hapticFeedbackEnabled);
    await prefs.setBool('analytics_enabled', _analyticsEnabled);
    await prefs.setBool('crash_reporting', _crashReportingEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Privacy & Security'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.tokens.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                    color: context.tokens.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'PRIVACY & SECURITY',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: context.tokens.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control your data, privacy, and security settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Authentication & Security Section
            _buildSection(
              'AUTHENTICATION & SECURITY',
              Icons.lock,
              [
                _buildSecurityTile(
                  'Biometric Authentication',
                  'Use fingerprint, face ID, or PIN for quick access',
                  Icons.fingerprint,
                  _biometricEnabled,
                  (value) {
                    setState(() {
                      _biometricEnabled = value;
                    });
                    // TODO: Implement biometric authentication
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Biometric authentication enabled'
                              : 'Biometric authentication disabled',
                        ),
                        backgroundColor: context.tokens.success,
                      ),
                    );
                  },
                ),
                _buildSecurityTile(
                  'Two-Factor Authentication',
                  'Add an extra layer of security to your account',
                  Icons.verified_user,
                  false, // TODO: Implement 2FA
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Two-factor authentication coming soon'),
                      ),
                    );
                  },
                ),
                _buildSecurityTile(
                  'Session Management',
                  'Manage active sessions and login history',
                  Icons.devices,
                  false, // TODO: Implement session management
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session management coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Privacy Controls Section
            _buildSection(
              'PRIVACY CONTROLS',
              Icons.privacy_tip,
              [
                _buildSecurityTile(
                  'Data Collection',
                  'Control what data we collect and how we use it',
                  Icons.data_usage,
                  _analyticsEnabled,
                  (value) {
                    setState(() {
                      _analyticsEnabled = value;
                    });
                    _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Data collection enabled'
                              : 'Data collection disabled',
                        ),
                        backgroundColor: context.tokens.success,
                      ),
                    );
                  },
                ),
                _buildSecurityTile(
                  'Crash Reporting',
                  'Help improve app stability by sharing crash reports',
                  Icons.bug_report,
                  _crashReportingEnabled,
                  (value) {
                    setState(() {
                      _crashReportingEnabled = value;
                    });
                    _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Crash reporting enabled'
                              : 'Crash reporting disabled',
                        ),
                        backgroundColor: context.tokens.success,
                      ),
                    );
                  },
                ),
                _buildSecurityTile(
                  'Personalized Experience',
                  'Allow AI to personalize your study experience',
                  Icons.psychology,
                  true, // Default enabled
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personalization settings updated'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Data Management Section
            _buildSection(
              'DATA MANAGEMENT',
              Icons.storage,
              [
                _buildActionTile(
                  'Export My Data',
                  'Download a copy of all your data',
                  Icons.download,
                  () => _exportData(),
                ),
                _buildActionTile(
                  'Clear Local Data',
                  'Remove all data stored on this device',
                  Icons.clear_all,
                  () => _showClearDataDialog(),
                ),
                _buildActionTile(
                  'Data Usage Report',
                  'See how much data you\'ve used',
                  Icons.analytics,
                  () => _showDataUsageReport(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Privacy Policy & Legal Section
            _buildSection(
              'PRIVACY POLICY & LEGAL',
              Icons.gavel,
              [
                _buildActionTile(
                  'Privacy Policy',
                  'Read our complete privacy policy',
                  Icons.privacy_tip,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen()),
                  ),
                ),
                _buildActionTile(
                  'Terms of Service',
                  'Read our terms of service',
                  Icons.description,
                  () => _showTermsOfService(),
                ),
                _buildActionTile(
                  'Data Processing Agreement',
                  'View our data processing terms',
                  Icons.assignment,
                  () => _showDataProcessingAgreement(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Contact & Support Section
            _buildSection(
              'CONTACT & SUPPORT',
              Icons.support_agent,
              [
                _buildActionTile(
                  'Privacy Questions',
                  'Contact our privacy team',
                  Icons.email,
                  () => _contactPrivacyTeam(),
                ),
                _buildActionTile(
                  'Security Issues',
                  'Report security concerns',
                  Icons.security,
                  () => _reportSecurityIssue(),
                ),
                _buildActionTile(
                  'Data Rights Request',
                  'Exercise your data rights',
                  Icons.people,
                  () => _requestDataRights(),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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
                icon,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSecurityTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
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
              color: context.tokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.tokens.primary,
            activeTrackColor: context.tokens.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surfaceAlt,
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
                    color: context.tokens.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: context.tokens.primary,
                    size: 20,
                    semanticLabel: title,
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
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  semanticLabel: 'Navigate to $title',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
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
                'Preparing your data...',
                style: TextStyle(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      // TODO: Implement actual data export
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data export feature coming soon'),
            backgroundColor: context.tokens.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: context.tokens.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Clear Local Data',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove all data stored on this device, including study sets, progress, and preferences. This action cannot be undone.',
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
              await _clearLocalData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.warning,
              foregroundColor: context.tokens.onPrimary,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLocalData() async {
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
                      AlwaysStoppedAnimation<Color>(context.tokens.warning),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Clearing local data...',
                style: TextStyle(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      // Clear local data
      await UnifiedStorageService.instance.clearAllData();
      await LocalImageStorageService.instance.deleteProfileImage();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Local data cleared successfully'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  void _showDataUsageReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Data Usage Report',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data usage reporting feature coming soon.',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'This will show you:',
              style: TextStyle(
                color: context.tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Storage space used\n• Data collection summary\n• Privacy settings overview\n• Export history',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Terms of Service feature coming soon. For now, please visit our website or contact support.',
          style: TextStyle(color: context.tokens.textSecondary),
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

  void _showDataProcessingAgreement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Data Processing Agreement',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Data Processing Agreement feature coming soon. For now, please visit our website or contact support.',
          style: TextStyle(color: context.tokens.textSecondary),
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

  void _contactPrivacyTeam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contact Privacy Team',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For privacy-related questions, please contact our privacy team:',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: privacy@mindload.app',
              style: TextStyle(
                color: context.tokens.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We typically respond within 24-48 hours.',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
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

  void _reportSecurityIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: context.tokens.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Report Security Issue',
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
              'For security issues, please contact our security team immediately:',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: security@mindload.app',
              style: TextStyle(
                color: context.tokens.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We treat security issues with the highest priority and respond within 4 hours.',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
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

  void _requestDataRights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Data Rights Request',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To exercise your data rights (access, rectification, erasure, portability), please contact our privacy team:',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Email: privacy@mindload.app',
              style: TextStyle(
                color: context.tokens.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subject: Data Rights Request',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'We will process your request within 30 days as required by law.',
              style: TextStyle(color: context.tokens.textSecondary),
            ),
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
}
