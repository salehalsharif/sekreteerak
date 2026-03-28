import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/ai_parse_service.dart';

/// ──────────────────────────────────────────────────
/// Tasks Providers (Local Storage)
/// ──────────────────────────────────────────────────
final todayTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await LocalStorageService.instance.getTodayTasks(); } catch (_) { return []; }
});

final overdueTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await LocalStorageService.instance.getOverdueTasks(); } catch (_) { return []; }
});

final upcomingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await LocalStorageService.instance.getUpcomingTasks(); } catch (_) { return []; }
});

final allTasksProvider = FutureProvider.family<List<TaskModel>, TaskStatus?>((ref, status) async {
  try {
    final all = await LocalStorageService.instance.getAllTasks();
    if (status == null) return all;
    return all.where((t) => t.status == status).toList();
  } catch (_) { return []; }
});

final followupTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await LocalStorageService.instance.getFollowups(); } catch (_) { return []; }
});

final taskDetailProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  try {
    final all = await LocalStorageService.instance.getAllTasks();
    return all.firstWhere((t) => t.id == taskId);
  } catch (_) { return null; }
});

final taskCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  try { return await LocalStorageService.instance.getTaskCounts(); } catch (_) { return {'today': 0, 'overdue': 0, 'followup': 0}; }
});

/// ──────────────────────────────────────────────────
/// Bottom Nav index
/// ──────────────────────────────────────────────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// ──────────────────────────────────────────────────
/// Voice recording state
/// ──────────────────────────────────────────────────
final isRecordingProvider = StateProvider<bool>((ref) => false);
final transcribedTextProvider = StateProvider<String>((ref) => '');

/// ──────────────────────────────────────────────────
/// AI Parse Provider
/// ──────────────────────────────────────────────────
final pendingParseTextProvider = StateProvider<String>((ref) => '');
final isParsingProvider = StateProvider<bool>((ref) => false);
final lastParseResultProvider = StateProvider<ParseResult?>((ref) => null);
final parseErrorProvider = StateProvider<String?>((ref) => null);
