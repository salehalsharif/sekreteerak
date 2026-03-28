import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/providers.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/common_widgets.dart';

/// Task detail screen with full info and action buttons
class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Edit task
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () {
              // Delete / cancel task
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: taskAsync.when(
        data: (task) {
          if (task == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'المهمة غير موجودة',
            );
          }
          return _buildContent(context, ref, task);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'خطأ في التحميل',
          subtitle: e.toString(),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, TaskModel task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              _statusBadge(task),
              const SizedBox(width: 8),
              PriorityBadge(
                label: task.priorityLabel,
                color: _priorityColor(task.priority),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor(task.itemType).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.itemTypeLabel,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _typeColor(task.itemType),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            task.title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),

          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              task.description!,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                // Date
                _detailRow(
                  Icons.calendar_today_rounded,
                  'التاريخ',
                  task.dueDate != null
                      ? DateHelpers.formatFullDate(task.dueDate!)
                      : 'بدون تاريخ',
                ),

                if (task.dueTime != null) ...[
                  const Divider(height: 24),
                  _detailRow(
                    Icons.schedule_rounded,
                    'الوقت',
                    DateHelpers.formatTime(task.dueTime),
                  ),
                ],

                if (task.linkedPerson != null) ...[
                  const Divider(height: 24),
                  _detailRow(
                    Icons.person_rounded,
                    'مرتبط بـ',
                    task.linkedPerson!,
                  ),
                ],

                if (task.recurrenceRule != null) ...[
                  const Divider(height: 24),
                  _detailRow(
                    Icons.repeat_rounded,
                    'تكرار',
                    task.recurrenceRule!,
                  ),
                ],

                const Divider(height: 24),
                _detailRow(
                  Icons.access_time_rounded,
                  'أُنشئت',
                  DateHelpers.formatFullDate(task.createdAt),
                ),

                if (task.completedAt != null) ...[
                  const Divider(height: 24),
                  _detailRow(
                    Icons.check_circle_rounded,
                    'اكتملت',
                    DateHelpers.formatFullDate(task.completedAt!),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Action buttons
          if (task.status == TaskStatus.pending || task.status == TaskStatus.snoozed) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Complete task
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('اكتمل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Snooze
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SnoozeSheet(
                            onSnooze: (duration) {
                              // Handle snooze
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.snooze_rounded, size: 20),
                      label: const Text('تأجيل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                        side: const BorderSide(color: AppTheme.warningColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Reschedule
                },
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                label: const Text('إعادة جدولة'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(TaskModel task) {
    Color color;
    switch (task.status) {
      case TaskStatus.pending:
        color = task.isOverdue ? AppTheme.errorColor : AppTheme.primaryColor;
        break;
      case TaskStatus.done:
        color = AppTheme.successColor;
        break;
      case TaskStatus.snoozed:
        color = AppTheme.warningColor;
        break;
      case TaskStatus.cancelled:
        color = AppTheme.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        task.isOverdue ? 'متأخرة' : task.statusLabel,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.high:
        return AppTheme.errorColor;
      case PriorityLevel.medium:
        return AppTheme.warningColor;
      case PriorityLevel.low:
        return AppTheme.textMuted;
    }
  }

  Color _typeColor(ItemType type) {
    switch (type) {
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
}
