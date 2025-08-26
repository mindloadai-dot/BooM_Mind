import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/services/notification_service.dart';
import 'package:mindload/services/notifications/offline_scheduler.dart';
import 'package:mindload/services/notifications/state_store.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/screens/enhanced_subscription_screen.dart';
import 'package:mindload/screens/subscription_settings_screen.dart';
import 'package:mindload/screens/tiers_benefits_screen.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  UserNotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  OfflinePrefs? _offlinePrefs;
  bool _freqSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Widget _buildCriticalAlertsSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final p = _offlinePrefs ?? OfflinePrefs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRITICAL ALERTS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.warning,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time‑Sensitive for Deadlines',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Allow urgent exam/deadline alerts to break through focus modes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: p.deadlineAlerts,
                onChanged: _isSaving
                    ? null
                    : (enabled) async {
                        HapticFeedbackService().selectionClick();
                        setState(() => _isSaving = true);
                        try {
                          // Update offline preferences
                          final updatedOfflinePrefs = OfflinePrefs(
                            stoEnabled: p.stoEnabled,
                            quietEnabled: p.quietEnabled,
                            quietStart: p.quietStart,
                            quietEnd: p.quietEnd,
                            digestEnabled: p.digestEnabled,
                            digestTime: p.digestTime,
                            globalMaxPerDay: p.globalMaxPerDay,
                            perToneMax: p.perToneMax,
                            minGapMinutes: p.minGapMinutes,
                            maxPerWeek: p.maxPerWeek,
                            deadlineAlerts: enabled,
                            timeSensitiveIOS: p.timeSensitiveIOS,
                            preferredTones: p.preferredTones,
                          );

                          // Save to local storage
                          await LocalStateStore.savePrefs(updatedOfflinePrefs);

                          // Update state
                          setState(() {
                            _offlinePrefs = updatedOfflinePrefs;
                          });

                          _showSuccess(
                              'Critical alerts ${enabled ? 'enabled' : 'disabled'}');
                        } catch (e) {
                          _showError('Failed to update: $e');
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                activeThumbColor: tokens.warning,
                activeTrackColor: tokens.warning.withValues(alpha: 0.3),
                inactiveThumbColor: tokens.textTertiary,
                inactiveTrackColor: tokens.divider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadPreferences() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Loading notification preferences...');
      }

      // Add timeout to prevent endless loading
      final prefs = await NotificationService.instance
          .getUserPreferences()
          .timeout(const Duration(seconds: 10));
      final offline = await LocalStateStore.loadPrefs();

      if (mounted) {
        setState(() {
          _preferences = prefs;
          _offlinePrefs = offline;
          _isLoading = false;
          _errorMessage = null;
        });
        if (kDebugMode) {
          debugPrint('✅ Preferences loaded successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load preferences: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load preferences: $e';
        });
        _showError('Failed to load preferences: $e');
      }
    }
  }

  Future<void> _updateStyle(NotificationStyle style) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await NotificationService.instance.updateNotificationStyle(style);
      await _loadPreferences();
      _showSuccess('Coaching style updated!');
    } catch (e) {
      _showError('Failed to update style: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Quiet hours toggle is now handled inline in _buildQuietHoursSection
  // using the offline preferences system for consistency

  void _showSuccess(String message) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: tokens.textEmphasis),
        ),
        backgroundColor: tokens.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: tokens.textEmphasis),
        ),
        backgroundColor: tokens.error.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: MindloadAppBarFactory.secondary(
        title: 'Notification Settings',
        showCreditsChip: true,
        onBuyCredits: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedSubscriptionScreen(),
            )),
        onViewLedger: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionSettingsScreen(),
            )),
        onUpgrade: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TiersBenefitsScreen(),
            )),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: tokens.primary,
                backgroundColor: tokens.primary.withValues(alpha: 0.2),
              ),
            )
          : (_preferences == null && _offlinePrefs == null)
              ? _buildErrorState()
              : SafeArea(child: _buildContent()),
    );
  }

  Widget _buildErrorState() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrainLogo(size: 100),
          const SizedBox(height: 24),
          Text(
            'FAILED TO LOAD PREFERENCES',
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
            ),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoachingStyleSection(),
          const SizedBox(height: 32),
          _buildFrequencySection(),
          const SizedBox(height: 32),
          _buildQuietHoursSection(),
          const SizedBox(height: 32),
          _buildCriticalAlertsSection(),
          const SizedBox(height: 32),
          _buildAnalyticsSection(),
          const SizedBox(height: 32),
          _buildSystemStatusSection(),
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final p = _offlinePrefs ?? OfflinePrefs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENCY',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Max Notifications per Day',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text('${p.globalMaxPerDay}/day',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: tokens.textSecondary)),
                ],
              ),
              Slider(
                value: p.globalMaxPerDay.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: tokens.primary,
                inactiveColor: tokens.divider,
                label: '${p.globalMaxPerDay}',
                onChanged: _freqSaving
                    ? null
                    : (v) {
                        setState(() {
                          _offlinePrefs = OfflinePrefs(
                            stoEnabled: p.stoEnabled,
                            quietEnabled: p.quietEnabled,
                            quietStart: p.quietStart,
                            quietEnd: p.quietEnd,
                            digestEnabled: p.digestEnabled,
                            digestTime: p.digestTime,
                            globalMaxPerDay: v.round(),
                            perToneMax: p.perToneMax,
                            minGapMinutes: p.minGapMinutes,
                            maxPerWeek: p.maxPerWeek,
                            deadlineAlerts: p.deadlineAlerts,
                            timeSensitiveIOS: p.timeSensitiveIOS,
                            preferredTones: p.preferredTones,
                          );
                        });
                      },
                onChangeEnd: _freqSaving
                    ? null
                    : (v) async {
                        setState(() => _freqSaving = true);
                        try {
                          await LocalStateStore.savePrefs(_offlinePrefs ?? p);
                          _showSuccess('Frequency updated');
                        } catch (e) {
                          _showError('Failed to save: $e');
                        } finally {
                          if (mounted) setState(() => _freqSaving = false);
                        }
                      },
              ),
              const SizedBox(height: 8),
              Text(
                'This controls the maximum number of notifications you\'ll receive per day across all types.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachingStyleSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced section header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.psychology,
                color: tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NOTIFICATION STYLE',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Help text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.borderDefault.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            'Choose your notification personality. Each style has a different tone and approach to help you stay motivated and focused.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        _buildStyleOption(
          style: NotificationStyle.coach,
          title: '🧠 COACH',
          description:
              'Supportive and motivating coach that celebrates your progress. Uses encouraging language and provides gentle reminders. Perfect for building consistent study habits with positive reinforcement.',
          isSelected:
              _preferences?.notificationStyle == NotificationStyle.coach ??
                  true,
        ),
        const SizedBox(height: 20),
        _buildStyleOption(
          style: NotificationStyle.cram,
          title: '⚡ CRAM',
          description:
              'High-energy and urgent messaging for intense study sessions. Uses action-oriented language and creates urgency. Ideal for exam preparation when you need to maximize study time.',
          isSelected:
              _preferences?.notificationStyle == NotificationStyle.cram ??
                  false,
        ),
        const SizedBox(height: 20),
        _buildStyleOption(
          style: NotificationStyle.mindful,
          title: '🧘 MINDFUL',
          description:
              'Calm and zen-like approach to learning. Uses peaceful language and promotes balance. Great for reducing study anxiety and maintaining long-term learning mindset.',
          isSelected:
              _preferences?.notificationStyle == NotificationStyle.mindful ??
                  false,
        ),
        const SizedBox(height: 20),
        _buildStyleOption(
          style: NotificationStyle.toughLove,
          title: '💪 TOUGH LOVE',
          description:
              'No-nonsense, direct approach that challenges you to stay accountable. Uses firm language and calls out procrastination. Best for when you need extra motivation to stick to your goals.',
          isSelected:
              _preferences?.notificationStyle == NotificationStyle.toughLove ??
                  false,
        ),
      ],
    );
  }

  Widget _buildStyleOption({
    required NotificationStyle style,
    required String title,
    required String description,
    required bool isSelected,
  }) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return GestureDetector(
      onTap: _isSaving ? null : () => _updateStyle(style),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.primary.withValues(alpha: 0.1)
              : tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.borderDefault,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? tokens.primary.withValues(alpha: 0.1)
                  : tokens.borderDefault.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with better spacing
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              isSelected ? tokens.primary : tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 12),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: tokens.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: tokens.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Description with better readability
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.primary.withValues(alpha: 0.05)
                    : tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? tokens.primary.withValues(alpha: 0.2)
                      : tokens.borderDefault.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? tokens.textPrimary.withValues(alpha: 0.9)
                              : tokens.textSecondary,
                          height: 1.5,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tokens.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: tokens.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Currently Active',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: tokens.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final p = _offlinePrefs ?? OfflinePrefs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUIET HOURS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do Not Disturb',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Respect device quiet hours and sleep schedules',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: p.quietEnabled,
                onChanged: _isSaving
                    ? null
                    : (enabled) async {
                        setState(() => _isSaving = true);
                        try {
                          // Update offline preferences
                          final updatedOfflinePrefs = OfflinePrefs(
                            stoEnabled: p.stoEnabled,
                            quietEnabled: enabled,
                            quietStart: p.quietStart,
                            quietEnd: p.quietEnd,
                            digestEnabled: p.digestEnabled,
                            digestTime: p.digestTime,
                            globalMaxPerDay: p.globalMaxPerDay,
                            perToneMax: p.perToneMax,
                            minGapMinutes: p.minGapMinutes,
                            maxPerWeek: p.maxPerWeek,
                            deadlineAlerts: p.deadlineAlerts,
                            timeSensitiveIOS: p.timeSensitiveIOS,
                            preferredTones: p.preferredTones,
                          );

                          // Save to local storage
                          await LocalStateStore.savePrefs(updatedOfflinePrefs);

                          // Update state
                          setState(() {
                            _offlinePrefs = updatedOfflinePrefs;
                          });

                          _showSuccess(
                              'Quiet hours ${enabled ? 'enabled' : 'disabled'}!');
                        } catch (e) {
                          _showError('Failed to update quiet hours: $e');
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                activeThumbColor: tokens.primary,
                activeTrackColor: tokens.primary.withValues(alpha: 0.3),
                inactiveThumbColor: tokens.textTertiary,
                inactiveTrackColor: tokens.divider,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigestSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final theme = Theme.of(context);
    final prefs = _preferences ??
        UserNotificationPreferences.defaultPreferences('default');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENING DIGEST',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily evening summary',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sends once at your digest time (${prefs.digestTime.format(context)}).',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: prefs.eveningDigest,
                    onChanged: _isSaving
                        ? null
                        : (enabled) async {
                            setState(() => _isSaving = true);
                            try {
                              // Update preferences
                              final updatedPrefs =
                                  prefs.copyWith(eveningDigest: enabled);
                              await NotificationService.instance
                                  .updateUserPreferences(updatedPrefs);

                              if (enabled) {
                                _showSuccess(
                                    '🗞️ Evening digest enabled for ${prefs.digestTime.format(context)}');
                              } else {
                                _showSuccess('🗞️ Evening digest disabled');
                              }

                              // Refresh preferences
                              await _loadPreferences();
                            } catch (e) {
                              _showError(
                                  'Failed to update digest settings: $e');
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    activeThumbColor: tokens.primary,
                    activeTrackColor: tokens.primary.withValues(alpha: 0.3),
                    inactiveThumbColor: tokens.textTertiary,
                    inactiveTrackColor: tokens.divider,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    final analytics = _preferences?.analytics ??
        const NotificationAnalytics(opens: 0, dismissals: 0, streakDays: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COACHING ANALYTICS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Column(
            children: [
              _buildAnalyticRow('Notifications Opened', '${analytics.opens}'),
              Divider(color: tokens.divider),
              _buildAnalyticRow(
                  'Current Streak', '${analytics.streakDays} days'),
              Divider(color: tokens.divider),
              _buildAnalyticRow(
                  'Engagement Rate',
                  analytics.opens + analytics.dismissals > 0
                      ? '${((analytics.opens / (analytics.opens + analytics.dismissals)) * 100).toStringAsFixed(1)}%'
                      : '0%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: tokens.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SYSTEM STATUS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderDefault),
          ),
          child: Column(
            children: [
              _buildStatusRow(
                  'System Ready', NotificationService.instance.isInitialized),
              Divider(color: tokens.divider),
              _buildStatusRow('Permissions Granted',
                  NotificationService.instance.hasPermissions),
              Divider(color: tokens.divider),
              _buildStatusRow('Firebase Available',
                  WorkingNotificationService.instance.hasFirebase),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool isActive) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textPrimary),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? Colors.green : Colors.red),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'INACTIVE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'TEST NOW',
                Icons.notifications_active,
                () async {
                  try {
                    await OfflineScheduler.initialize();
                    await OfflineScheduler.sendTest();
                    _showSuccess('🧪 Offline test notification sent!');
                  } catch (e) {
                    // Fallback to unified test if offline path fails
                    await NotificationService.sendTestNotification();
                    _showSuccess('🧪 Test notification sent!');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'RESET',
                Icons.refresh,
                () async {
                  try {
                    await NotificationService.instance
                        .resetPreferencesToDefaults();
                    await _loadPreferences();
                    _showSuccess('🔄 Preferences reset to defaults!');
                  } catch (e) {
                    _showSuccess('🔄 Preferences reset!');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, VoidCallback onPressed) {
    final tokens =
        Theme.of(context).extension<SemanticTokensExtension>()?.tokens ??
            ThemeManager.instance.currentTokens;
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: tokens.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
