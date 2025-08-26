import 'package:flutter/material.dart';
import 'package:mindload/services/notification_service.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

class ExamCalendarScreen extends StatefulWidget {
  const ExamCalendarScreen({super.key});

  @override
  State<ExamCalendarScreen> createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService.instance;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<ExamEntry> _exams = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadExams();
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

  Future<void> _loadExams() async {
    try {
      final preferences = await _notificationService.getUserPreferences();
      setState(() {
        _exams = preferences.exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading exams: $e');
    }
  }

  Future<void> _addExam() async {
    final result = await showDialog<ExamEntry>(
      context: context,
      builder: (context) => const AddExamDialog(),
    );
    
    if (result != null) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        await _notificationService.addExam(result.course, result.examDate);
        setState(() {
          _exams.add(result);
          _exams.sort((a, b) => a.examDate.compareTo(b.examDate));
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exam "${result.course}" added successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to add exam'),
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
  }

  Future<void> _removeExam(ExamEntry exam) async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _notificationService.removeExam(exam.course, exam.examDate);
      setState(() {
        _exams.removeWhere((e) => e.course == exam.course);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam "${exam.course}" removed'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove exam'),
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
      appBar: MindloadAppBarFactory.secondary(title: 'Exam Calendar'),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _isSaving ? null : _addExam,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.add),
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
                    _buildUpcomingExams(theme),
                    const SizedBox(height: 32),
                    _buildNotificationInfo(theme),
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
          'Manage Your Exams',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your exam dates to receive personalized study reminders and escalation notifications.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingExams(ThemeData theme) {
    final now = DateTime.now();
    final upcomingExams = _exams.where((exam) => exam.examDate.isAfter(now)).toList();
    final pastExams = _exams.where((exam) => exam.examDate.isBefore(now)).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Exams',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        if (upcomingExams.isEmpty && pastExams.isEmpty)
          _buildEmptyState(theme)
        else if (upcomingExams.isEmpty)
          _buildNoUpcomingExams(theme)
        else
          ...upcomingExams.map((exam) => _buildExamCard(theme, exam, true)),
        
        if (pastExams.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'Past Exams',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
            ),
          ),
          const SizedBox(height: 16),
          ...pastExams.map((exam) => _buildExamCard(theme, exam, false)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:  0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha:  0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Exams Added',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first exam and get personalized study reminders.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:  0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUpcomingExams(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha:  0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha:  0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Caught Up!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No upcoming exams scheduled. Add new ones as they come up.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ThemeData theme, ExamEntry exam, bool isUpcoming) {
    final now = DateTime.now();
    final daysUntil = exam.examDate.difference(now).inDays;
    final isToday = daysUntil == 0;
    final isTomorrow = daysUntil == 1;
    final isThisWeek = daysUntil <= 7 && daysUntil > 0;
    
    Color cardColor;
    Color accentColor;
    String urgencyText;
    
    if (!isUpcoming) {
      cardColor = theme.colorScheme.surface;
      accentColor = theme.colorScheme.onSurface.withValues(alpha:  0.5);
      urgencyText = 'Completed';
    } else if (isToday) {
      cardColor = Colors.red.withValues(alpha:  0.1);
      accentColor = Colors.red;
      urgencyText = 'TODAY';
    } else if (isTomorrow) {
      cardColor = Colors.orange.withValues(alpha:  0.1);
      accentColor = Colors.orange;
      urgencyText = 'Tomorrow';
    } else if (isThisWeek) {
      cardColor = Colors.amber.withValues(alpha:  0.1);
      accentColor = Colors.amber.shade700;
      urgencyText = '$daysUntil days left';
    } else {
      cardColor = theme.colorScheme.primaryContainer.withValues(alpha:  0.3);
      accentColor = theme.colorScheme.primary;
      urgencyText = '$daysUntil days left';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withValues(alpha:  0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.course,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(exam.examDate),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        urgencyText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(exam);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                    ),
                  ),
                ],
              ),
              
              if (isUpcoming && (isToday || isTomorrow || isThisWeek)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha:  0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        color: accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getNotificationMessage(daysUntil),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationInfo(ThemeData theme) {
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
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Exam Notifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildNotificationRule(theme, '7 days before', 'Initial reminder to start preparation'),
          _buildNotificationRule(theme, '3 days before', 'Intensified study reminders'),
          _buildNotificationRule(theme, '1 day before', 'Final review notifications'),
          _buildNotificationRule(theme, 'Day of exam', 'Last-minute preparation alerts'),
        ],
      ),
    );
  }

  Widget _buildNotificationRule(ThemeData theme, String timing, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timing,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:  0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ExamEntry exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exam'),
        content: Text('Are you sure you want to remove "${exam.course}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeExam(exam);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getNotificationMessage(int daysUntil) {
    switch (daysUntil) {
      case 0:
        return 'Exam day! You\'ll get final prep notifications.';
      case 1:
        return 'Last day for review! Expect intensive reminders.';
      default:
        return 'Escalated notifications are now active.';
    }
  }

  String _getNotificationText(int daysUntil) {
    if (daysUntil == 0) return 'TODAY';
    if (daysUntil == 1) return 'Tomorrow';
    return '$daysUntil days left';
  }
}

class AddExamDialog extends StatefulWidget {
  const AddExamDialog({super.key});

  @override
  State<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends State<AddExamDialog> {
  final _courseController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerTheme.of(context).copyWith(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Add Exam'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _courseController,
            decoration: const InputDecoration(
              labelText: 'Course/Subject',
              hintText: 'e.g., Biology 101',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exam Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:  0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _courseController.text.trim().isEmpty
              ? null
              : () {
                  final exam = ExamEntry(
                    course: _courseController.text.trim(),
                    examDate: _selectedDate,
                  );
                  Navigator.of(context).pop(exam);
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}