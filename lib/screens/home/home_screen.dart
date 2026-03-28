import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/providers.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/common_widgets.dart';

/// Main home screen — Today view with summary, overdue, and upcoming
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(todayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final upcomingTasks = ref.watch(upcomingTasksProvider);
    final counts = ref.watch(taskCountsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayTasksProvider);
            ref.invalidate(overdueTasksProvider);
            ref.invalidate(upcomingTasksProvider);
            ref.invalidate(taskCountsProvider);
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // ─── Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        DateHelpers.getGreeting(),
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'بماذا نساعدك اليوم؟',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick stats row
                      counts.when(
                        data: (data) => _buildStatsRow(data),
                        loading: () => const SizedBox(height: 80),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),

                      // Quick action card
                      GestureDetector(
                        onTap: () {
                          // Same as FAB — open voice capture
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            boxShadow: AppTheme.glowShadow(
                              AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ماذا تريد أن أتذكر لك؟',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'اضغط وتحدث بصوتك',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Overdue Tasks ──────────────────────────
              overdueTasks.when(
                data: (tasks) {
                  if (tasks.isEmpty) return const SliverToBoxAdapter();
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: '⚠️ متأخرة',
                            count: tasks.length,
                            countColor: AppTheme.errorColor,
                          ),
                          ...tasks.map((task) => TaskCard(
                            task: task,
                            onTap: () => context.push('/task/${task.id}'),
                            onComplete: () => _completeTask(ref, task.id),
                            onSnooze: () => _showSnooze(context, ref, task.id),
                          )),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(),
              ),

              // ─── Today's Tasks ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: todayTasks.when(
                    data: (tasks) => Column(
                      children: [
                        SectionHeader(
                          title: '📅 اليوم',
                          count: tasks.length,
                        ),
                        if (tasks.isEmpty)
                          const EmptyState(
                            icon: Icons.wb_sunny_rounded,
                            title: 'لا مهام لليوم',
                            subtitle: 'اضغط على الميكروفون لإضافة مهمة',
                          )
                        else
                          ...tasks.map((task) => TaskCard(
                            task: task,
                            onTap: () => context.push('/task/${task.id}'),
                            onComplete: () => _completeTask(ref, task.id),
                          )),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => EmptyState(
                      icon: Icons.error_outline,
                      title: 'خطأ في التحميل',
                      subtitle: e.toString(),
                    ),
                  ),
                ),
              ),

              // ─── Upcoming ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: upcomingTasks.when(
                    data: (tasks) {
                      if (tasks.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          SectionHeader(
                            title: '📌 القادم',
                            count: tasks.length,
                            onSeeAll: () => context.go('/tasks'),
                          ),
                          ...tasks.take(5).map((task) => TaskCard(
                            task: task,
                            onTap: () => context.push('/task/${task.id}'),
                            onComplete: () => _completeTask(ref, task.id),
                          )),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, int> counts) {
    return Row(
      children: [
        _statCard('اليوم', '${counts['today'] ?? 0}', AppTheme.primaryColor),
        const SizedBox(width: 8),
        _statCard('متأخرة', '${counts['overdue'] ?? 0}', AppTheme.errorColor),
        const SizedBox(width: 8),
        _statCard('متابعات', '${counts['followup'] ?? 0}', AppTheme.warningColor),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _completeTask(WidgetRef ref, String taskId) async {
    await ref.read(todayTasksProvider.future);
    // In production, call SupabaseService.instance.completeTask(taskId)
    // then invalidate providers
    ref.invalidate(todayTasksProvider);
    ref.invalidate(overdueTasksProvider);
    ref.invalidate(taskCountsProvider);
  }

  void _showSnooze(BuildContext context, WidgetRef ref, String taskId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SnoozeSheet(
        onSnooze: (duration) {
          // Calculate new reminder time and snooze
          final newReminder = DateTime.now().add(duration);
          // SupabaseService.instance.snoozeTask(taskId, newReminder);
          ref.invalidate(overdueTasksProvider);
          ref.invalidate(todayTasksProvider);
          ref.invalidate(taskCountsProvider);
        },
      ),
    );
  }
}
