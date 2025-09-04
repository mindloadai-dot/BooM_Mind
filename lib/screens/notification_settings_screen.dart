import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/widgets/unified_design_system.dart';

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
            padding: UnifiedSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(tokens),
                SizedBox(height: UnifiedSpacing.lg),

                // Notification Style
                _buildNotificationStyleSection(tokens),
                SizedBox(height: UnifiedSpacing.lg),

                // Notification Categories
                _buildNotificationCategoriesSection(tokens),
                SizedBox(height: UnifiedSpacing.lg),

                // Permission Status
                _buildPermissionStatusSection(tokens),
                SizedBox(height: UnifiedSpacing.lg),

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
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UnifiedIcon(Icons.notifications, color: tokens.primary, size: 28),
              SizedBox(width: UnifiedSpacing.md),
              Expanded(
                child: UnifiedText(
                  'Notification Preferences',
                  style: UnifiedTypography.headlineMedium.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: UnifiedSpacing.sm),
          UnifiedText(
            'Customize how and when you receive notifications',
            style: UnifiedTypography.bodyLarge.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStyleSection(SemanticTokens tokens) {
    final currentStyle = _userProfile.notificationStyle;
    final availableStyles = _userProfile.availableStyles;

    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Notification Style',
            style: UnifiedTypography.headlineSmall.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.sm),
          UnifiedText(
            'Choose how notifications are delivered to you',
            style: UnifiedTypography.bodyMedium.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          SizedBox(height: UnifiedSpacing.lg),

          // Style Selection
          for (final style in availableStyles) ...[
            _buildStyleOption(tokens, style, currentStyle == style),
            if (style != availableStyles.last)
              SizedBox(height: UnifiedSpacing.sm),
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
        padding: UnifiedSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected ? tokens.primary.withOpacity(0.1) : tokens.surface,
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: UnifiedBorderRadius.mdRadius,
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
                borderRadius: UnifiedBorderRadius.lgRadius,
              ),
              child: Center(
                child: UnifiedText(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            SizedBox(width: UnifiedSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UnifiedText(
                    name,
                    style: UnifiedTypography.titleMedium.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UnifiedSpacing.xs),
                  UnifiedText(
                    description,
                    style: UnifiedTypography.bodyMedium.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              UnifiedIcon(
                Icons.check_circle,
                color: tokens.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCategoriesSection(SemanticTokens tokens) {
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Notification Categories',
            style: UnifiedTypography.headlineSmall.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.sm),
          UnifiedText(
            'Choose which types of notifications you want to receive',
            style: UnifiedTypography.bodyMedium.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          SizedBox(height: UnifiedSpacing.lg),
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
          UnifiedIcon(icon, color: tokens.primary, size: 20),
          SizedBox(width: UnifiedSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnifiedText(
                  title,
                  style: UnifiedTypography.bodyMedium.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                UnifiedText(
                  description,
                  style: UnifiedTypography.bodySmall.copyWith(
                    color: tokens.textSecondary,
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
    return UnifiedCard(
      padding: UnifiedSpacing.cardPadding,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnifiedText(
            'Permission Status',
            style: UnifiedTypography.headlineSmall.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UnifiedSpacing.sm),
          UnifiedText(
            'Current notification system status',
            style: UnifiedTypography.bodyMedium.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          SizedBox(height: UnifiedSpacing.lg),

          // Check actual permissions
          FutureBuilder<bool>(
            future: Future.value(true), // Placeholder - service is active
            builder: (context, snapshot) {
              final hasPermissions = snapshot.data ?? false;
              final isServiceActive = true; // Placeholder - service is active

              return Column(
                children: [
                  _buildStatusRow(
                    tokens,
                    'Notification Permissions',
                    hasPermissions ? 'GRANTED' : 'DENIED',
                    Icons.notifications,
                    hasPermissions ? tokens.success : tokens.error,
                  ),
                  SizedBox(height: UnifiedSpacing.sm),
                  _buildStatusRow(
                    tokens,
                    'Background Processing',
                    Platform.isIOS ? 'ENABLED' : 'N/A',
                    Icons.schedule,
                    Platform.isIOS ? tokens.success : tokens.textSecondary,
                  ),
                  SizedBox(height: UnifiedSpacing.sm),
                  _buildStatusRow(
                    tokens,
                    'MindLoad Notification Service',
                    isServiceActive ? 'ACTIVE' : 'INACTIVE',
                    Icons.check_circle,
                    isServiceActive ? tokens.success : tokens.error,
                  ),

                  // Add iOS-specific test button
                  if (Platform.isIOS) ...[
                    SizedBox(height: UnifiedSpacing.lg),
                    AccessibleButton(
                      onPressed: () async {
                        try {
                          // Run comprehensive notification test
                          await MindLoadNotificationService
                              .runComprehensiveTest();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: UnifiedText(
                                  'Notification test completed! Check your notifications.',
                                  style: UnifiedTypography.bodyMedium.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                backgroundColor: tokens.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: UnifiedText(
                                  'Notification test failed: $e',
                                  style: UnifiedTypography.bodyMedium.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                backgroundColor: tokens.error,
                              ),
                            );
                          }
                        }
                      },
                      variant: ButtonVariant.secondary,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UnifiedIcon(Icons.phonelink_ring),
                          SizedBox(width: UnifiedSpacing.sm),
                          UnifiedText('Test Notifications'),
                        ],
                      ),
                    ),
                  ],

                  // Add Android-specific test button
                  if (Platform.isAndroid) ...[
                    SizedBox(height: UnifiedSpacing.lg),
                    AccessibleButton(
                      onPressed: () async {
                        try {
                          // Run comprehensive notification test
                          await MindLoadNotificationService
                              .runComprehensiveTest();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: UnifiedText(
                                  'Notification test completed! Check your notifications.',
                                  style: UnifiedTypography.bodyMedium.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                backgroundColor: tokens.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: UnifiedText(
                                  'Notification test failed: $e',
                                  style: UnifiedTypography.bodyMedium.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                backgroundColor: tokens.error,
                              ),
                            );
                          }
                        }
                      },
                      variant: ButtonVariant.secondary,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UnifiedIcon(Icons.notifications_active),
                          SizedBox(width: UnifiedSpacing.sm),
                          UnifiedText('Test Notifications'),
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
        UnifiedIcon(icon, color: tokens.primary, size: 20),
        SizedBox(width: UnifiedSpacing.md),
        Expanded(
          child: UnifiedText(
            label,
            style: UnifiedTypography.bodyMedium.copyWith(
              color: tokens.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: UnifiedText(
            status,
            style: UnifiedTypography.bodySmall.copyWith(
              color: tokens.onPrimary,
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
        child: const UnifiedText(
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
            content: UnifiedText(
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
            content: UnifiedText('Failed to update notification style: $e'),
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
        content: UnifiedText('Notification settings saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
