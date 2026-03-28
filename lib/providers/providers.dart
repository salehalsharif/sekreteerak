import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/inbox_entry_model.dart';
import '../models/user_settings_model.dart';
import '../models/daily_briefing_model.dart';
import '../services/supabase_service.dart';

/// ──────────────────────────────────────────────────
/// Auth Provider
/// ──────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// ──────────────────────────────────────────────────
/// Tasks Providers
/// ──────────────────────────────────────────────────
final todayTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return await SupabaseService.instance.getTodayTasks();
});

final overdueTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return await SupabaseService.instance.getOverdueTasks();
});

final upcomingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return await SupabaseService.instance.getUpcomingTasks();
});

final allTasksProvider = FutureProvider.family<List<TaskModel>, TaskStatus?>((ref, status) async {
  return await SupabaseService.instance.getTasks(status: status);
});

final followupTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  return await SupabaseService.instance.getFollowups();
});

final taskDetailProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  return await SupabaseService.instance.getTask(taskId);
});

final taskCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await SupabaseService.instance.getTaskCounts();
});

/// ──────────────────────────────────────────────────
/// Inbox Provider
/// ──────────────────────────────────────────────────
final inboxProvider = FutureProvider<List<InboxEntry>>((ref) async {
  return await SupabaseService.instance.getInboxEntries();
});

/// ──────────────────────────────────────────────────
/// Settings Provider
/// ──────────────────────────────────────────────────
final userSettingsProvider = FutureProvider<UserSettings?>((ref) async {
  return await SupabaseService.instance.getUserSettings();
});

/// ──────────────────────────────────────────────────
/// Briefing Provider
/// ──────────────────────────────────────────────────
final todayBriefingProvider = FutureProvider<DailyBriefing?>((ref) async {
  return await SupabaseService.instance.getTodayBriefing();
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
