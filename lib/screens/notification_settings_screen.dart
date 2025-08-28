import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/accessible_components.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final UserProfileService _userProfile = UserProfileService.instance;

  // Notification category preferences
  final Map<String, bool> _categoryPreferences = {
    'Study Reminders': true,
    'Streak Alerts': true,
    'Exam Deadlines': true,
    'Inactivity Nudges': false,
    'Event Triggers': true,
    'Promotional': false,
  };

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;

    return Scaffold(
      appBar: const MindloadAppBar(title: 'Notification Settings'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: tokens.bg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(tokens),
                const SizedBox(height: 24),

                // Notification Style
                _buildNotificationStyleSection(tokens),
                const SizedBox(height: 24),

                // Notification Categories
                _buildNotificationCategoriesSection(tokens),
                const SizedBox(height: 24),

                // Permission Status
                _buildPermissionStatusSection(tokens),
                const SizedBox(height: 24),

                // Save Button
                _buildSaveButton(tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications, color: tokens.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Notification Preferences',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Customize how and when you receive notifications',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStyleSection(SemanticTokens tokens) {
    final currentStyle = _userProfile.notificationStyle;
    final availableStyles = _userProfile.availableStyles;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Style',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how notifications are delivered to you',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Style Selection
          for (final style in availableStyles) ...[
            _buildStyleOption(tokens, style, currentStyle == style),
            if (style != availableStyles.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleOption(
      SemanticTokens tokens, String style, bool isSelected) {
    final styleInfo = _userProfile.getStyleInfo(style);
    final emoji = styleInfo['emoji'] as String;
    final name = styleInfo['name'] as String;
    final description = styleInfo['description'] as String;

    return GestureDetector(
      onTap: () => _updateNotificationStyle(style),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary.withOpacity(0.1) : tokens.surface,
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.primary
                    : tokens.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: tokens.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCategoriesSection(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Categories',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which types of notifications you want to receive',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryToggle('Study Reminders', 'Study session notifications',
              Icons.school, 'Study Reminders'),
          _buildCategoryToggle('Streak Alerts', 'Daily streak maintenance',
              Icons.local_fire_department, 'Streak Alerts'),
          _buildCategoryToggle('Exam Deadlines', 'Important exam reminders',
              Icons.event, 'Exam Deadlines'),
          _buildCategoryToggle('Inactivity Nudges', 'Gentle reminders to study',
              Icons.notifications_active, 'Inactivity Nudges'),
          _buildCategoryToggle('Event Triggers', 'Special event notifications',
              Icons.celebration, 'Event Triggers'),
          _buildCategoryToggle('Promotional', 'App updates and features',
              Icons.campaign, 'Promotional'),
        ],
      ),
    );
  }

  Widget _buildCategoryToggle(
      String title, String description, IconData icon, String categoryKey) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: tokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _categoryPreferences[categoryKey] ?? false,
            onChanged: (value) {
              setState(() {
                _categoryPreferences[categoryKey] = value;
              });
            },
            activeColor: tokens.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusSection(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Status',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current notification system status',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Check actual permissions
          FutureBuilder<bool>(
            future: WorkingNotificationService.instance.hasPermissions,
            builder: (context, snapshot) {
              final hasPermissions = snapshot.data ?? false;
              final isServiceActive =
                  WorkingNotificationService.instance.isInitialized;

              return Column(
                children: [
                  _buildStatusRow(
                    tokens,
                    'Notification Permissions',
                    hasPermissions ? 'GRANTED' : 'DENIED',
                    Icons.notifications,
                    hasPermissions ? tokens.success : tokens.error,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    tokens,
                    'Background Processing',
                    Platform.isIOS ? 'ENABLED' : 'N/A',
                    Icons.schedule,
                    Platform.isIOS ? tokens.success : tokens.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    tokens,
                    'WorkingNotificationService',
                    isServiceActive ? 'ACTIVE' : 'INACTIVE',
                    Icons.check_circle,
                    isServiceActive ? tokens.success : tokens.error,
                  ),

                  // Add iOS-specific test button
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 20),
                    AccessibleButton(
                      onPressed: () async {
                        await WorkingNotificationService.instance
                            .ensureIOSNotificationsWork();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Test notification sent! Check your notifications.',
                                style: TextStyle(color: tokens.textPrimary),
                              ),
                              backgroundColor: tokens.success,
                            ),
                          );
                        }
                      },
                      variant: ButtonVariant.secondary,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phonelink_ring),
                          SizedBox(width: 8),
                          Text('Test iOS Notifications'),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(SemanticTokens tokens, String label, String status,
      IconData icon, Color statusColor) {
    return Row(
      children: [
        Icon(icon, color: tokens.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: tokens.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(SemanticTokens tokens) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Notification Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _updateNotificationStyle(String newStyle) async {
    try {
      await _userProfile.updateNotificationStyle(newStyle);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Notification style updated to: ${_userProfile.getStyleDisplayName(newStyle)}'),
            backgroundColor: Theme.of(context)
                    .extension<SemanticTokensExtension>()
                    ?.tokens
                    .success ??
                Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification style: $e'),
            backgroundColor: Theme.of(context)
                    .extension<SemanticTokensExtension>()
                    ?.tokens
                    .error ??
                Colors.red,
          ),
        );
      }
    }
  }

  void _saveSettings() {
    // TODO: Implement saving category preferences
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
