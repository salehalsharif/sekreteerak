import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/common_widgets.dart';

/// Follow-ups screen — shows all follow-up items
class FollowupsScreen extends ConsumerWidget {
  const FollowupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followups = ref.watch(followupTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المتابعات',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: followups.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'لا توجد متابعات',
              subtitle: 'قل "تابع خالد بخصوص العرض" لإضافة متابعة',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(followupTasksProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () => context.push('/task/${task.id}'),
                  onComplete: () {
                    ref.invalidate(followupTasksProvider);
                  },
                  onSnooze: task.isOverdue
                      ? () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SnoozeSheet(
                              onSnooze: (duration) {
                                ref.invalidate(followupTasksProvider);
                              },
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          );
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
}
