import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/services/notification_service.dart';
// Removed import: enhanced_notification_copy_library - service removed
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class OnboardingNotificationsScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const OnboardingNotificationsScreen({super.key, this.onComplete});

  @override
  State<OnboardingNotificationsScreen> createState() => _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState extends State<OnboardingNotificationsScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Settings State
  NotificationStyle _selectedStyle = NotificationStyle.coach;
  int _frequency = 5; // Updated to match OfflinePrefs default
  final Set<DayPart> _selectedDayparts = {DayPart.evening};
  bool _quietHours = true;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _eveningDigest = true;
  TimeOfDay _digestTime = const TimeOfDay(hour: 20, minute: 30);
  bool _stoEnabled = true;
  bool _timeSensitive = false;
  
  // Unified text styles to ensure consistency with app theme and semantic tokens
  TextStyle _titlePrimary(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
  }
  
  TextStyle _sectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall!.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
  }
  
  TextStyle _bodyMuted(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  // Category toggles
  bool _dailyReminders = true;
  bool _quizNotifications = false;
  bool _achievementAlerts = false;
  bool _streakAlerts = false;
  bool _deadlineAlerts = false;
  
  // State management
  bool _hasPermission = false;
  bool _isLoading = false;
  bool _showPermissionExplainer = true;
  DateTime? _testDate;
  NotificationTemplate? _previewTemplate;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _checkPermissionStatus();
    _generatePreview();
    _startPreviewRotation();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final prefs = await NotificationService.instance.getUserPreferences();
      setState(() => _hasPermission = prefs != null);
    } catch (e) {
      setState(() => _hasPermission = false);
    }
  }

  void _generatePreview() {
    if (!mounted) return;
    
    // Generate style-specific preview based on selected style
    String title, body;
    switch (_selectedStyle) {
      case NotificationStyle.coach:
        title = 'NEURAL SYNC: TRAINING MODE READY';
        body = 'Your cognitive systems are optimized for learning. Let\'s boost your performance!';
        break;
      case NotificationStyle.toughLove:
        title = 'WAKE UP: MIND NEEDS ACTIVATION';
        body = 'No excuses. Your brain is waiting for input. Time to deliver results.';
        break;
      case NotificationStyle.mindful:
        title = 'Gentle Reminder: Learning Opportunity';
        body = 'Take a moment to nurture your mind with some focused study time.';
        break;
      case NotificationStyle.cram:
        title = 'URGENT: KNOWLEDGE INJECTION REQUIRED';
        body = 'Maximum absorption mode activated! 8 Biology cards need immediate processing.';
        break;
    }
    
    setState(() {
      _previewTemplate = NotificationTemplate(title: title, body: body);
    });
  }

  NotificationCategory _getActiveCategoryForPreview() {
    if (_dailyReminders) return NotificationCategory.studyNow;
    if (_quizNotifications) return NotificationCategory.eventTrigger;
    if (_deadlineAlerts && _testDate != null) return NotificationCategory.examAlert;
    if (_streakAlerts) return NotificationCategory.streakSave;
    if (_achievementAlerts) return NotificationCategory.promotional;
    return NotificationCategory.studyNow;
  }

  void _startPreviewRotation() {
    _previewTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) _generatePreview();
    });
  }

  String _getDaypartLabel(DayPart daypart) {
    switch (daypart) {
      case DayPart.morning: return 'Morning';
      case DayPart.midday: return 'Midday';
      case DayPart.afternoon: return 'Afternoon';
      case DayPart.evening: return 'Evening';
      case DayPart.late: return 'Late';
    }
  }

  Color _getStyleColor(NotificationStyle style) {
    switch (style) {
      case NotificationStyle.cram: return Theme.of(context).colorScheme.error;
      case NotificationStyle.coach: return Theme.of(context).colorScheme.primary;
      case NotificationStyle.mindful: return Theme.of(context).colorScheme.tertiary;
      case NotificationStyle.toughLove: return Theme.of(context).colorScheme.secondary;
    }
  }

  String _getStyleIcon(NotificationStyle style) {
    switch (style) {
      case NotificationStyle.cram: return '⚡';
      case NotificationStyle.coach: return '🧠';
      case NotificationStyle.mindful: return '🧘';
      case NotificationStyle.toughLove: return '💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Smart Notifications'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Value-first explainer (only if no permission)
            if (!_hasPermission && _showPermissionExplainer) _buildValueExplainer(),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildWhatYouReceiveCard(),
                    const SizedBox(height: 24),
                    _buildWhenYouReceiveCard(),
                    const SizedBox(height: 24),
                    _buildHowTheyFeelCard(),
                    const SizedBox(height: 32),
                    _buildSystemFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueExplainer() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha:  0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your AI coach learns when you\'re most focused',
                  style: _titlePrimary(context),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showPermissionExplainer = false),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Smart reminders that respect your schedule and maximize learning',
            style: _bodyMuted(context).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouReceiveCard() {
    return _buildCard(
      'What you receive',
      Column(
        children: [
          _buildToggle(
            'Daily Reminders (Coach)',
            'A gentle nudge to show up.',
            _dailyReminders,
            (value) => setState(() {
              _dailyReminders = value;
              _generatePreview();
            }),
          ),
          _buildToggle(
            'Quiz Notifications (Cram)',
            'Tiny pop-quizzes for quick wins.',
            _quizNotifications,
            (value) => setState(() {
              _quizNotifications = value;
              _generatePreview();
            }),
          ),
          _buildToggle(
            'Achievement Alerts (Coach)',
            'Celebrate badges and milestones.',
            _achievementAlerts,
            (value) => setState(() {
              _achievementAlerts = value;
              _generatePreview();
            }),
          ),
          _buildToggle(
            'Study Streak Alerts (Coach)',
            'Keep your chain glowing.',
            _streakAlerts,
            (value) => setState(() {
              _streakAlerts = value;
              _generatePreview();
            }),
          ),
          _buildToggle(
            'Deadline/Test Date Alerts (Cram)',
            'Stronger nudges as exams near.',
            _deadlineAlerts,
            (value) => setState(() {
              _deadlineAlerts = value;
              _generatePreview();
            }),
          ),
          
          // Add test date chip if deadline alerts are on but no date exists
          if (_deadlineAlerts && _testDate == null) _buildAddTestDateChip(),
          
          // iOS Time-Sensitive toggle
          if (_shouldShowTimeSensitiveToggle()) _buildTimeSensitiveToggle(),
        ],
      ),
    );
  }

  Widget _buildWhenYouReceiveCard() {
    return _buildCard(
      'When you receive them',
      Column(
        children: [
          // Frequency slider
          _buildFrequencySlider(),
          const SizedBox(height: 16),
          
          // Dayparts selector
          _buildDaypartsSelector(),
          const SizedBox(height: 16),
          
          // Quiet hours
          _buildQuietHoursSection(),
          const SizedBox(height: 16),
          
          // Evening digest
          _buildEveningDigestSection(),
          const SizedBox(height: 16),
          
          // STO toggle
          _buildSTOToggle(),
        ],
      ),
    );
  }

  Widget _buildHowTheyFeelCard() {
    return _buildCard(
      'How they feel',
      Column(
        children: [
          // Style selector
          _buildStyleSelector(),
          const SizedBox(height: 20),
          
          // Live preview
          _buildLivePreview(),
          const SizedBox(height: 16),
          
          // Preview controls
          _buildPreviewControls(),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha:  0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              title,
              style: _titlePrimary(context).copyWith(letterSpacing: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _sectionHeader(context),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: _bodyMuted(context),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddTestDateChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: _showDatePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha:  0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                'Add test date',
                style: GoogleFonts.orbitron(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSensitiveToggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Allow Time-Sensitive near deadlines (T-2h/T-30m)',
              style: GoogleFonts.sourceCodePro(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ),
          Switch.adaptive(
            value: _timeSensitive,
            onChanged: (value) => setState(() => _timeSensitive = value),
            activeThumbColor: Colors.orange,
            activeTrackColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySlider() {
    // Ensure slider value always falls within the valid range [min, max]
    final int minFreq = 1;
    final int maxFreq = 10; // Increased from 4 to 10 to match notification settings
    final double safeValue = _frequency.clamp(minFreq, maxFreq).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Frequency',
              style: _sectionHeader(context),
            ),
            Text(
              '~$_frequency/day',
              style: _titlePrimary(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha:  0.2),
          ),
          child: Slider(
            value: safeValue,
            min: minFreq.toDouble(),
            max: maxFreq.toDouble(),
            divisions: maxFreq - minFreq,
            onChanged: (value) => setState(() => _frequency = value.round()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This controls the maximum number of notifications you\'ll receive per day.',
          style: _bodyMuted(context),
        ),
      ],
    );
  }

  Widget _buildDaypartsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dayparts (multi-select)',
          style: GoogleFonts.orbitron(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DayPart.values.map((daypart) {
            final isSelected = _selectedDayparts.contains(daypart);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedDayparts.remove(daypart);
                } else {
                  _selectedDayparts.add(daypart);
                }
                _generatePreview();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                  ),
                ),
                child: Text(
                  _getDaypartLabel(daypart),
                  style: GoogleFonts.orbitron(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quiet Hours',
                style: GoogleFonts.orbitron(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: _quietHours,
              onChanged: (value) => setState(() => _quietHours = value),
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (_quietHours) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector('From', _quietStart, (time) => setState(() => _quietStart = time)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeSelector('To', _quietEnd, (time) => setState(() => _quietEnd = time)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
                  dialHandColor: Theme.of(context).colorScheme.primary,
                  dialBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: child!,
            );
          },
        );
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.sourceCodePro(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time.format(context),
              style: GoogleFonts.orbitron(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEveningDigestSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Evening Digest',
                style: GoogleFonts.orbitron(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: _eveningDigest,
              onChanged: (value) => setState(() => _eveningDigest = value),
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (_eveningDigest) ...[
          const SizedBox(height: 12),
          _buildTimeSelector('Time', _digestTime, (time) => setState(() => _digestTime = time)),
        ],
      ],
    );
  }

  Widget _buildSTOToggle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STO (Send-Time Optimization)',
                style: GoogleFonts.orbitron(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We learn your best hours.',
                style: GoogleFonts.sourceCodePro(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _stoEnabled,
          onChanged: (value) => setState(() => _stoEnabled = value),
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return Row(
      children: NotificationStyle.values.map((style) {
        final isSelected = _selectedStyle == style;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedStyle = style;
              _generatePreview();
            }),
            child: Container(
              margin: EdgeInsets.only(
                left: style == NotificationStyle.values.first ? 0 : 4,
                right: style == NotificationStyle.values.last ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _getStyleColor(style).withValues(alpha:  0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _getStyleColor(style) : Colors.grey.shade600,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getStyleIcon(style),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.name.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: isSelected ? _getStyleColor(style) : Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLivePreview() {
    if (_previewTemplate == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha:  0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.psychology, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mindload',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'now',
                      style: GoogleFonts.sourceCodePro(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _previewTemplate!.title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _previewTemplate!.body,
            style: GoogleFonts.sourceCodePro(
              color: Colors.grey.shade300,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewControls() {
    final hasAtLeastOneCategory = _dailyReminders || _quizNotifications || 
        _achievementAlerts || _streakAlerts || _deadlineAlerts;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _hasPermission ? _sendTestNotification : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _hasPermission ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
              ),
              foregroundColor: _hasPermission ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
            ),
            child: Text(
              'Send Test',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: hasAtLeastOneCategory ? () => _generatePreview() : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasAtLeastOneCategory ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              foregroundColor: hasAtLeastOneCategory ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
            child: Text(
              'Shuffle Preview',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemFooter() {
    final hasAtLeastOneCategory = _dailyReminders || _quizNotifications || 
        _achievementAlerts || _streakAlerts || _deadlineAlerts;

    return Column(
      children: [
        // Status row
        _buildPermissionStatus(),
        const SizedBox(height: 24),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.orbitron(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: hasAtLeastOneCategory && !_isLoading ? _saveAndEnable : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasAtLeastOneCategory ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                  foregroundColor: hasAtLeastOneCategory ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                      )
                    : Text(
                        'Save & Enable',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        
        // Helper text if no categories selected
        if (!hasAtLeastOneCategory) ...[
          const SizedBox(height: 12),
          Text(
            'Pick at least one.',
            style: GoogleFonts.sourceCodePro(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionStatus() {
    String status;
    Color statusColor;
    IconData statusIcon;
    String? action;

    if (_hasPermission) {
      status = 'Allowed';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      status = 'Permission Needed';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      action = 'Request Permission';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha:  0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: GoogleFonts.orbitron(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: _requestPermission,
              child: Text(
                action,
                style: GoogleFonts.orbitron(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() => _testDate = date);
      _generatePreview();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await NotificationService.instance.getUserPreferences();
      setState(() => _hasPermission = prefs != null);
    } catch (e) {
      _showError('Failed to request permission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestNotification() async {
    if (_previewTemplate == null) return;
    
    try {
      await NotificationService.instance.sendImmediateNotification(
        _previewTemplate!.title,
        _previewTemplate!.body,
      );
      _showSuccess('Test notification sent!');
    } catch (e) {
      _showError('Failed to send test: $e');
    }
  }

  Future<void> _saveAndEnable() async {
    setState(() => _isLoading = true);
    
    try {
      // Request permission if needed
      if (!_hasPermission) {
        await _requestPermission();
        if (!_hasPermission) {
          _showError('Permission required to save settings');
          return;
        }
      }

      // Save all preferences
      final preferences = UserNotificationPreferences(
        uid: 'temp_uid',
        notificationStyle: _selectedStyle,
        frequencyPerDay: _frequency,
        enabledCategories: _getEnabledCategories(),
        selectedDayparts: _selectedDayparts.toList(),
        quietHours: _quietHours,
        quietStart: _quietStart,
        quietEnd: _quietEnd,
        eveningDigest: _eveningDigest,
        digestTime: _digestTime,
        stoEnabled: _stoEnabled,
        timeSensitive: _timeSensitive,
        timezone: 'America/Chicago',
        exams: _testDate != null ? [ExamEntry(course: 'Test Course', examDate: _testDate!)] : [],
        analytics: const NotificationAnalytics(opens: 0, dismissals: 0, streakDays: 0),
        pushTokens: const [],
        promotionalConsent: const PromotionalConsent(hasConsented: false, canReceive: false, consentSource: 'default'),
        permissionStatus: const NotificationPermissionStatus(systemPermissionGranted: false, appNotificationsEnabled: true, gracefulDegradationActive: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await NotificationService.instance.updateUserPreferences(preferences);
      
      _showSuccess('Saved. You\'ll get smart reminders at good times.');
      
      // Complete onboarding after brief delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onComplete?.call();
        Navigator.of(context).pop();
      });
      
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Set<NotificationCategory> _getEnabledCategories() {
    final categories = <NotificationCategory>{};
    if (_dailyReminders) categories.add(NotificationCategory.studyNow);
    if (_quizNotifications) categories.add(NotificationCategory.eventTrigger);
    if (_achievementAlerts) categories.add(NotificationCategory.promotional);
    if (_streakAlerts) categories.add(NotificationCategory.streakSave);
    if (_deadlineAlerts) categories.add(NotificationCategory.examAlert);
    return categories;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.sourceCodePro(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _shouldShowTimeSensitiveToggle() {
    return !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS && _deadlineAlerts;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.sourceCodePro(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // This method is now handled by the primary _generatePreview method above
}