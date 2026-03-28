import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/inbox_entry_model.dart';
import '../models/user_settings_model.dart';
import '../models/daily_briefing_model.dart';
import '../services/supabase_service.dart';
import '../services/ai_parse_service.dart';

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
  try { return await SupabaseService.instance.getTodayTasks(); } catch (_) { return []; }
});

final overdueTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await SupabaseService.instance.getOverdueTasks(); } catch (_) { return []; }
});

final upcomingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await SupabaseService.instance.getUpcomingTasks(); } catch (_) { return []; }
});

final allTasksProvider = FutureProvider.family<List<TaskModel>, TaskStatus?>((ref, status) async {
  try { return await SupabaseService.instance.getTasks(status: status); } catch (_) { return []; }
});

final followupTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  try { return await SupabaseService.instance.getFollowups(); } catch (_) { return []; }
});

final taskDetailProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  try { return await SupabaseService.instance.getTask(taskId); } catch (_) { return null; }
});

final taskCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  try { return await SupabaseService.instance.getTaskCounts(); } catch (_) { return {'today': 0, 'overdue': 0, 'followup': 0}; }
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

/// ──────────────────────────────────────────────────
/// AI Parse Provider
/// ──────────────────────────────────────────────────

/// The text currently being submitted for parsing
final pendingParseTextProvider = StateProvider<String>((ref) => '');

/// Whether a parse operation is in progress
final isParsingProvider = StateProvider<bool>((ref) => false);

/// Result of last successful parse
final lastParseResultProvider = StateProvider<ParseResult?>((ref) => null);

/// Error message from last parse (null if none)
final parseErrorProvider = StateProvider<String?>((ref) => null);
