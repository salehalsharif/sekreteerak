import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'package:uuid/uuid.dart';

/// Local storage service for offline task management.
/// Uses SharedPreferences to store tasks when Supabase is not configured.
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance =>
      _instance ??= LocalStorageService._();
  LocalStorageService._();

  static const _tasksKey = 'local_tasks';
  static const _uuid = Uuid();

  /// Get all tasks from local storage
  Future<List<TaskModel>> getAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson
        .map((json) => TaskModel.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  /// Get today's tasks
  Future<List<TaskModel>> getTodayTasks() async {
    final all = await getAllTasks();
    final now = DateTime.now();
    return all.where((t) {
      if (t.status == TaskStatus.cancelled) return false;
      if (t.dueDate == null) return true; // undated go to today
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  /// Get overdue tasks
  Future<List<TaskModel>> getOverdueTasks() async {
    final all = await getAllTasks();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return all.where((t) {
      if (t.status != TaskStatus.pending || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(today);
    }).toList();
  }

  /// Get upcoming tasks (next 7 days, excluding today)
  Future<List<TaskModel>> getUpcomingTasks() async {
    final all = await getAllTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekLater = today.add(const Duration(days: 7));
    return all.where((t) {
      if (t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isAfter(today) && due.isBefore(weekLater);
    }).toList();
  }

  /// Get followup tasks
  Future<List<TaskModel>> getFollowups() async {
    final all = await getAllTasks();
    return all.where((t) => t.itemType == ItemType.followup).toList();
  }

  /// Get task counts
  Future<Map<String, int>> getTaskCounts() async {
    final today = await getTodayTasks();
    final overdue = await getOverdueTasks();
    final followups = await getFollowups();
    return {
      'today': today.length,
      'overdue': overdue.length,
      'followup': followups.length,
    };
  }

  /// Create/save a task
  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    final task = TaskModel(
      id: id,
      userId: 'local',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      itemType: _parseItemType(data['item_type'] as String?),
      status: TaskStatus.pending,
      priority: _parsePriority(data['priority'] as String?),
      dueDate: data['due_date'] != null
          ? DateTime.parse(data['due_date'] as String)
          : now,
      dueTime: data['due_time'] as String?,
      linkedPerson: data['linked_person'] as String?,
      recurrenceRule: data['recurrence_rule'] as String?,
      createdAt: now,
      updatedAt: now,
    );

    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    tasksJson.add(jsonEncode(task.toJson()));
    await prefs.setStringList(_tasksKey, tasksJson);

    return task;
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    await _updateTaskStatus(taskId, TaskStatus.done);
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    final tasks = tasksJson
        .map((json) => TaskModel.fromJson(jsonDecode(json)))
        .where((t) => t.id != taskId)
        .toList();
    await prefs.setStringList(
      _tasksKey,
      tasks.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  Future<void> _updateTaskStatus(String taskId, TaskStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    final tasks = tasksJson
        .map((json) => TaskModel.fromJson(jsonDecode(json)))
        .toList();

    final updated = tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          completedAt: status == TaskStatus.done ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();

    await prefs.setStringList(
      _tasksKey,
      updated.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  ItemType _parseItemType(String? value) {
    if (value == null) return ItemType.task;
    return ItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemType.task,
    );
  }

  PriorityLevel _parsePriority(String? value) {
    if (value == null) return PriorityLevel.medium;
    return PriorityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PriorityLevel.medium,
    );
  }
}
