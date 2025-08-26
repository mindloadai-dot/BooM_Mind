import 'package:flutter/material.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/study_data.dart';

class DeadlineIndicator extends StatelessWidget {
  final StudySet studySet;
  final bool showLabel;
  final double iconSize;

  const DeadlineIndicator({
    super.key,
    required this.studySet,
    this.showLabel = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!studySet.hasDeadline) return const SizedBox.shrink();

    final deadlineInfo = _getDeadlineInfo(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 6,
        vertical: showLabel ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: deadlineInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(showLabel ? 12 : 8),
        border: Border.all(
          color: deadlineInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            deadlineInfo.icon,
            size: iconSize,
            color: deadlineInfo.color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              deadlineInfo.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: deadlineInfo.color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  DeadlineInfo _getDeadlineInfo(BuildContext context) {
    final tokens = context.tokens;
    
    if (studySet.isOverdue) {
      final daysPast = DateTime.now().difference(studySet.deadlineDate!).inDays;
      return DeadlineInfo(
        icon: Icons.error,
        color: tokens.error,
        text: daysPast == 0 
          ? 'Overdue' 
          : daysPast == 1 
            ? '1d overdue' 
            : '${daysPast}d overdue',
      );
    }
    
    if (studySet.isDeadlineToday) {
      return DeadlineInfo(
        icon: Icons.today,
        color: tokens.warning,
        text: 'Due today',
      );
    }
    
    if (studySet.isDeadlineTomorrow) {
      return DeadlineInfo(
        icon: Icons.event,
        color: tokens.warning,
        text: 'Tomorrow',
      );
    }
    
    final daysUntil = studySet.daysUntilDeadline!;
    if (daysUntil <= 7) {
      return DeadlineInfo(
        icon: Icons.schedule,
        color: tokens.warning,
        text: daysUntil == 1 ? '1 day' : '$daysUntil days',
      );
    }
    
    if (daysUntil <= 30) {
      final weeks = (daysUntil / 7).ceil();
      return DeadlineInfo(
        icon: Icons.calendar_today,
        color: tokens.primary,
        text: weeks == 1 ? '1 week' : '$weeks weeks',
      );
    }
    
    final months = (daysUntil / 30).ceil();
    return DeadlineInfo(
      icon: Icons.calendar_month,
      color: tokens.textSecondary,
      text: months == 1 ? '1 month' : '$months months',
    );
  }
}

class DeadlineInfo {
  final IconData icon;
  final Color color;
  final String text;

  const DeadlineInfo({
    required this.icon,
    required this.color,
    required this.text,
  });
}