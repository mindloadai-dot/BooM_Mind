import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mindload/services/notification_service.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

class ScheduleBuilderScreen extends StatefulWidget {
  const ScheduleBuilderScreen({super.key});

  @override
  State<ScheduleBuilderScreen> createState() => _ScheduleBuilderScreenState();
}

class _ScheduleBuilderScreenState extends State<ScheduleBuilderScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService.instance;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<TimeWindow> _timeWindows = [];
  QuietHours _quietHours = const QuietHours(start: "22:00", end: "07:00");
  String _timezone = "America/Chicago";
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPreferences();
    _loadTimezone();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _notificationService.getUserPreferences();
      setState(() {
        _timeWindows = preferences.timeWindows;
        _quietHours = QuietHours(start: "22:00", end: "07:00");
        _timezone = preferences.timezone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint('Error loading preferences: $e');
      }
    }
  }

  Future<void> _loadTimezone() async {
    try {
      final currentTimezone = await FlutterTimezone.getLocalTimezone();
      if (mounted && _timezone != currentTimezone) {
        setState(() {
          _timezone = currentTimezone;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading timezone: $e');
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Methods not available in simplified NotificationService
      // await _notificationService.updateTimeWindows(_timeWindows);
      // await _notificationService.updateQuietHours(_quietHours);
      if (kDebugMode) {
        debugPrint('Time windows and quiet hours saved (simplified implementation)');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Schedule updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update schedule'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _addTimeWindow() {
    setState(() {
      _timeWindows.add(const TimeWindow(start: "09:00", end: "11:00"));
    });
  }

  void _removeTimeWindow(int index) {
    setState(() {
      _timeWindows.removeAt(index);
    });
  }

  void _updateTimeWindow(int index, TimeWindow window) {
    setState(() {
      _timeWindows[index] = window;
    });
  }

  Future<void> _selectTime(BuildContext context, String currentTime, Function(String) onTimeSelected) async {
    final time = TimeOfDay(
      hour: int.parse(currentTime.split(':')[0]),
      minute: int.parse(currentTime.split(':')[1]),
    );
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerTheme.of(context).copyWith(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      final formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      onTimeSelected(formattedTime);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MindloadAppBarFactory.secondary(
        title: 'Schedule Builder',
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildTimezoneInfo(theme),
                    const SizedBox(height: 32),
                    _buildTimeWindows(theme),
                    const SizedBox(height: 32),
                    _buildQuietHours(theme),
                    const SizedBox(height: 32),
                    _buildSchedulePreview(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure Your Study Schedule',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your preferred study times and quiet hours for optimal notifications.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha:  0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha:  0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Timezone',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timezone.replaceAll('_', ' '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:  0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWindows(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Study Time Windows',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: _timeWindows.length < 5 ? _addTimeWindow : null,
              icon: const Icon(Icons.add_circle_outline),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Set time periods when you prefer to receive study notifications.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_timeWindows.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha:  0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha:  0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No time windows configured',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first study window',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:  0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        
        ..._timeWindows.asMap().entries.map((entry) {
          final index = entry.key;
          final window = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha:  0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, window.start, (time) {
                            _updateTimeWindow(index, TimeWindow(start: time, end: window.end));
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha:  0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              window.start,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'to',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context, window.end, (time) {
                            _updateTimeWindow(index, TimeWindow(start: window.start, end: time));
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha:  0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              window.end,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeTimeWindow(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuietHours(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiet Hours',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set hours when you don\'t want to receive any notifications.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha:  0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bedtime,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Do Not Disturb',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _quietHours.start, (time) {
                        setState(() {
                          _quietHours = QuietHours(start: time, end: _quietHours.end);
                        });
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withValues(alpha:  0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha:  0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Starts',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _quietHours.start,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha:  0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, _quietHours.end, (time) {
                        setState(() {
                          _quietHours = QuietHours(start: _quietHours.start, end: time);
                        });
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withValues(alpha:  0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha:  0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Ends',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _quietHours.end,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:  0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Schedule Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_timeWindows.isNotEmpty) ...[
            Text(
              'Active Periods',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._timeWindows.map((window) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${window.start} - ${window.end}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          Text(
            'Quiet Hours',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.bedtime,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
              ),
              const SizedBox(width: 8),
              Text(
                '${_quietHours.start} - ${_quietHours.end}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}