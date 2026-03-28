import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/common_widgets.dart';

/// Tasks list screen with filter tabs
class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'الكل'),
    Tab(text: 'قيد الانتظار'),
    Tab(text: 'مكتملة'),
    Tab(text: 'مؤجلة'),
  ];

  TaskStatus? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = null;
            break;
          case 1:
            _currentFilter = TaskStatus.pending;
            break;
          case 2:
            _currentFilter = TaskStatus.done;
            break;
          case 3:
            _currentFilter = TaskStatus.snoozed;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider(_currentFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المهام',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/inbox'),
            icon: const Icon(Icons.inbox_rounded),
            tooltip: 'الوارد',
          ),
          IconButton(
            onPressed: () => context.push('/calendar'),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'التقويم',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      ),
      body: tasks.when(
        data: (taskList) {
          if (taskList.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'لا توجد مهام',
              subtitle: 'أضف مهمة جديدة بالضغط على الميكروفون',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allTasksProvider(_currentFilter));
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final task = taskList[index];
                return TaskCard(
                  task: task,
                  onTap: () => context.push('/task/${task.id}'),
                  onComplete: () {
                    // Complete task
                    ref.invalidate(allTasksProvider(_currentFilter));
                  },
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
