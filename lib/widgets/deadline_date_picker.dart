import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';

class DeadlineDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateChanged;
  final bool? initialToggleState;
  final ValueChanged<bool>? onToggleChanged;
  final String label;
  final bool isRequired;

  const DeadlineDatePicker({
    super.key,
    this.initialDate,
    required this.onDateChanged,
    this.initialToggleState,
    this.onToggleChanged,
    this.label = 'Deadline',
    this.isRequired = false,
  });

  @override
  State<DeadlineDatePicker> createState() => _DeadlineDatePickerState();
}

class _DeadlineDatePickerState extends State<DeadlineDatePicker> {
  DateTime? _selectedDate;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _isEnabled = widget.initialToggleState ?? (widget.initialDate != null);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: _isEnabled
                    ? (_selectedDate != null && _selectedDate!.isBefore(today) 
                        ? tokens.error 
                        : tokens.primary)
                    : tokens.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label + (widget.isRequired ? ' *' : ''),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isEnabled ? tokens.textPrimary : tokens.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Toggle switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                        if (!value) {
                          _selectedDate = null;
                          widget.onDateChanged(null);
                        }
                      });
                      widget.onToggleChanged?.call(value);
                    },
                    activeThumbColor: tokens.primary,
                    inactiveThumbColor: tokens.textTertiary,
                    inactiveTrackColor: tokens.surfaceAlt,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                if (_isEnabled && _selectedDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                      widget.onDateChanged(null);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Date display and picker (only when enabled)
          if (_isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: InkWell(
                onTap: _showDatePicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tokens.borderDefault.withValues(alpha:  0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDate != null) ...[
                        // Selected date display
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _getDateStatusColor(tokens),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(_selectedDate!),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Status indicator
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getDateStatusColor(tokens),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getDateStatusText(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getDateStatusColor(tokens),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // No date selected
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: tokens.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Set deadline date',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: tokens.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select a deadline for this study set',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Disabled state message
          if (!_isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt.withValues(alpha:  0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.borderDefault.withValues(alpha:  0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: tokens.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deadline disabled',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toggle the switch above to enable deadline tracking for this study set',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Quick action buttons (only when enabled and no date selected)
          if (_isEnabled && _selectedDate == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildQuickActionChip('Today', () => _selectDate(today)),
                  const SizedBox(width: 8),
                  _buildQuickActionChip('Tomorrow', () => _selectDate(today.add(const Duration(days: 1)))),
                  const SizedBox(width: 8),
                  _buildQuickActionChip('Next Week', () => _selectDate(today.add(const Duration(days: 7)))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    final tokens = context.tokens;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.primary.withValues(alpha:  0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tokens.primary.withValues(alpha:  0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getDateStatusColor(SemanticTokens tokens) {
    if (_selectedDate == null) return tokens.textTertiary;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    
    if (deadline.isBefore(today)) {
      return tokens.error; // Overdue
    } else if (deadline == today) {
      return tokens.warning; // Due today
    } else if (deadline == today.add(const Duration(days: 1))) {
      return tokens.warning; // Due tomorrow
    } else {
      return tokens.success; // Future date
    }
  }

  String _getDateStatusText() {
    if (_selectedDate == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    
    if (deadline.isBefore(today)) {
      final daysPast = today.difference(deadline).inDays;
      return daysPast == 1 ? 'Overdue by 1 day' : 'Overdue by $daysPast days';
    } else if (deadline == today) {
      return 'Due today';
    } else if (deadline == today.add(const Duration(days: 1))) {
      return 'Due tomorrow';
    } else {
      final daysUntil = deadline.difference(today).inDays;
      return daysUntil == 1 ? 'In 1 day' : 'In $daysUntil days';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    // Add ordinal suffix
    String dayWithSuffix = day.toString();
    if (day >= 11 && day <= 13) {
      dayWithSuffix += 'th';
    } else {
      switch (day % 10) {
        case 1: dayWithSuffix += 'st'; break;
        case 2: dayWithSuffix += 'nd'; break;
        case 3: dayWithSuffix += 'rd'; break;
        default: dayWithSuffix += 'th'; break;
      }
    }
    
    return '$dayWithSuffix $month $year';
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateChanged(date);
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 5, 12, 31);
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select deadline date',
      cancelText: 'Cancel',
      confirmText: 'Set Deadline',
      builder: (context, child) {
        final tokens = context.tokens;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: tokens.primary,
              onPrimary: tokens.onPrimary,
              surface: tokens.surface,
              onSurface: tokens.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      _selectDate(date);
    }
  }
}