import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/widgets/deadline_date_picker.dart';
import 'package:mindload/widgets/deadline_indicator.dart';
import 'package:mindload/services/deadline_service.dart';

class DeadlineManagementDialog extends StatefulWidget {
  final StudySet studySet;
  final ValueChanged<StudySet>? onDeadlineUpdated;

  const DeadlineManagementDialog({
    super.key,
    required this.studySet,
    this.onDeadlineUpdated,
  });

  @override
  State<DeadlineManagementDialog> createState() => _DeadlineManagementDialogState();
}

class _DeadlineManagementDialogState extends State<DeadlineManagementDialog> {
  DateTime? _selectedDeadline;
  bool _isDeadlineEnabled = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedDeadline = widget.studySet.deadlineDate;
    _isDeadlineEnabled = widget.studySet.hasDeadline;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Dialog(
      backgroundColor: tokens.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 24,
                    color: tokens.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Deadline',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.studySet.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Current deadline status
              if (widget.studySet.hasDeadline) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.borderDefault.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Deadline',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          DeadlineIndicator(
                            studySet: widget.studySet,
                            showLabel: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DeadlineService.instance.getDeadlineStatusMessage(widget.studySet),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Deadline picker with toggle
              DeadlineDatePicker(
                initialDate: _selectedDeadline,
                initialToggleState: _isDeadlineEnabled,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDeadline = date;
                  });
                },
                onToggleChanged: (enabled) {
                  setState(() {
                    _isDeadlineEnabled = enabled;
                    if (!enabled) {
                      _selectedDeadline = null;
                    }
                  });
                },
                label: 'New Deadline',
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: tokens.borderDefault,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _handleUpdateDeadline,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: tokens.primary,
                        foregroundColor: tokens.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUpdating
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(tokens.onPrimary),
                            ),
                          )
                        : Text(
                            !_isDeadlineEnabled ? 'Remove Deadline' : (_selectedDeadline == null ? 'Enable Deadline' : 'Update Deadline'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              // Additional info
              const SizedBox(height: 16),
              Text(
                !_isDeadlineEnabled 
                  ? 'Removing the deadline will cancel all related notifications.'
                  : (_selectedDeadline == null 
                      ? 'Enable deadline tracking to receive study reminders.'
                      : 'Updating the deadline will reschedule notifications accordingly.'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdateDeadline() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Determine the final deadline date based on toggle state
      final finalDeadline = _isDeadlineEnabled ? _selectedDeadline : null;
      
      // Update deadline using the service
      await DeadlineService.instance.updateDeadline(widget.studySet, finalDeadline);
      
      // Create updated study set
      final updatedStudySet = widget.studySet.copyWith(deadlineDate: finalDeadline);
      
      // Notify callback
      widget.onDeadlineUpdated?.call(updatedStudySet);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !_isDeadlineEnabled
                ? 'Deadline removed successfully'
                : (finalDeadline == null 
                    ? 'Deadline enabled successfully'
                    : 'Deadline updated successfully'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(updatedStudySet);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update deadline: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}