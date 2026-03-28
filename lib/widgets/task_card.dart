import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/task_model.dart';
import '../utils/date_helpers.dart';

/// Reusable task card widget
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animNormal,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: task.isOverdue
                ? AppTheme.errorColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Complete checkbox
            GestureDetector(
              onTap: onComplete,
              child: AnimatedContainer(
                duration: AppTheme.animFast,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.status == TaskStatus.done
                      ? AppTheme.successColor
                      : Colors.transparent,
                  border: Border.all(
                    color: task.status == TaskStatus.done
                        ? AppTheme.successColor
                        : _priorityColor,
                    width: 2,
                  ),
                ),
                child: task.status == TaskStatus.done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.black,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: 14),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: task.status == TaskStatus.done
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Meta row
                  Row(
                    children: [
                      // Type badge
                      _typeBadge(),
                      const SizedBox(width: 8),

                      // Date/time
                      if (task.dueDate != null) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: task.isOverdue
                              ? AppTheme.errorColor
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateHelpers.getRelativeDate(task.dueDate),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: task.isOverdue
                                ? AppTheme.errorColor
                                : AppTheme.textMuted,
                            fontWeight: task.isOverdue
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (task.dueTime != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            DateHelpers.formatTime(task.dueTime),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: task.isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],

                      const Spacer(),

                      // Person tag
                      if (task.linkedPerson != null) ...[
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: AppTheme.accentColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.linkedPerson!,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: AppTheme.accentColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Snooze / actions
            if (task.isOverdue && onSnooze != null)
              IconButton(
                onPressed: onSnooze,
                icon: const Icon(
                  Icons.snooze_rounded,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _typeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.itemTypeLabel,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _typeColor,
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (task.itemType) {
      case ItemType.task:
        return AppTheme.primaryColor;
      case ItemType.meeting:
        return AppTheme.accentColor;
      case ItemType.followup:
        return AppTheme.warningColor;
      case ItemType.reminder:
        return const Color(0xFF64B5F6);
      case ItemType.idea:
        return const Color(0xFFCE93D8);
      case ItemType.shopping:
        return const Color(0xFF81C784);
    }
  }

  Color get _priorityColor {
    switch (task.priority) {
      case PriorityLevel.high:
        return AppTheme.errorColor;
      case PriorityLevel.medium:
        return AppTheme.warningColor;
      case PriorityLevel.low:
        return AppTheme.textMuted;
    }
  }
}
