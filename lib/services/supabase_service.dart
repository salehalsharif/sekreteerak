import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/inbox_entry_model.dart';
import '../models/user_settings_model.dart';
import '../models/daily_briefing_model.dart';
import '../models/task_event_model.dart';

/// Central service for all Supabase database operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── Auth ──────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Tasks ─────────────────────────────────────────

  /// Get all tasks for the current user
  Future<List<TaskModel>> getTasks({
    TaskStatus? status,
    ItemType? itemType,
  }) async {
    var query = _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId!);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (itemType != null) {
      query = query.eq('item_type', itemType.name);
    }

    final data = await query.order('due_date', ascending: true);
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get today's tasks
  Future<List<TaskModel>> getTodayTasks() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId!)
        .eq('due_date', today)
        .neq('status', 'cancelled')
        .order('due_time', ascending: true);
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get overdue tasks
  Future<List<TaskModel>> getOverdueTasks() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId!)
        .eq('status', 'pending')
        .lt('due_date', today)
        .order('due_date', ascending: true);
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get follow-up tasks
  Future<List<TaskModel>> getFollowups() async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId!)
        .eq('item_type', 'followup')
        .eq('status', 'pending')
        .order('due_date', ascending: true);
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get upcoming tasks (future)
  Future<List<TaskModel>> getUpcomingTasks() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('tasks')
        .select()
        .eq('user_id', currentUserId!)
        .eq('status', 'pending')
        .gt('due_date', today)
        .order('due_date', ascending: true)
        .limit(20);
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  /// Get a single task by ID
  Future<TaskModel?> getTask(String taskId) async {
    final data = await _client
        .from('tasks')
        .select()
        .eq('id', taskId)
        .maybeSingle();
    return data != null ? TaskModel.fromJson(data) : null;
  }

  /// Create a new task
  Future<TaskModel> createTask(Map<String, dynamic> taskData) async {
    taskData['user_id'] = currentUserId;
    final data = await _client
        .from('tasks')
        .insert(taskData)
        .select()
        .single();

    // Log creation event
    await _logTaskEvent(data['id'], EventType.created);

    return TaskModel.fromJson(data);
  }

  /// Update a task
  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> updates) async {
    final data = await _client
        .from('tasks')
        .update(updates)
        .eq('id', taskId)
        .select()
        .single();

    await _logTaskEvent(taskId, EventType.edited, payload: updates);

    return TaskModel.fromJson(data);
  }

  /// Mark task as done
  Future<void> completeTask(String taskId) async {
    await _client
        .from('tasks')
        .update({
          'status': 'done',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);

    await _logTaskEvent(taskId, EventType.completed);
  }

  /// Snooze task
  Future<void> snoozeTask(String taskId, DateTime newReminderAt) async {
    await _client
        .from('tasks')
        .update({
          'status': 'snoozed',
          'reminder_at': newReminderAt.toIso8601String(),
        })
        .eq('id', taskId);

    await _logTaskEvent(taskId, EventType.snoozed, payload: {
      'new_reminder_at': newReminderAt.toIso8601String(),
    });
  }

  /// Reschedule task
  Future<void> rescheduleTask(String taskId, DateTime newDate, String? newTime) async {
    final updates = <String, dynamic>{
      'due_date': newDate.toIso8601String().split('T').first,
      'status': 'pending',
    };
    if (newTime != null) {
      updates['due_time'] = newTime;
    }

    await _client
        .from('tasks')
        .update(updates)
        .eq('id', taskId);

    await _logTaskEvent(taskId, EventType.rescheduled, payload: updates);
  }

  /// Cancel task
  Future<void> cancelTask(String taskId) async {
    await _client
        .from('tasks')
        .update({'status': 'cancelled'})
        .eq('id', taskId);
  }

  // ─── Inbox ─────────────────────────────────────────

  /// Get all inbox entries
  Future<List<InboxEntry>> getInboxEntries() async {
    final data = await _client
        .from('inbox_entries')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((json) => InboxEntry.fromJson(json)).toList();
  }

  /// Create inbox entry
  Future<InboxEntry> createInboxEntry(Map<String, dynamic> entryData) async {
    entryData['user_id'] = currentUserId;
    final data = await _client
        .from('inbox_entries')
        .insert(entryData)
        .select()
        .single();
    return InboxEntry.fromJson(data);
  }

  /// Update inbox entry with parsed result
  Future<void> updateInboxEntry(String entryId, Map<String, dynamic> updates) async {
    await _client
        .from('inbox_entries')
        .update(updates)
        .eq('id', entryId);
  }

  // ─── Settings ──────────────────────────────────────

  /// Get user settings
  Future<UserSettings?> getUserSettings() async {
    final data = await _client
        .from('user_settings')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();
    return data != null ? UserSettings.fromJson(data) : null;
  }

  /// Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> updates) async {
    await _client
        .from('user_settings')
        .update(updates)
        .eq('user_id', currentUserId!);
  }

  // ─── Daily Briefings ──────────────────────────────

  /// Get today's briefing
  Future<DailyBriefing?> getTodayBriefing() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _client
        .from('daily_briefings')
        .select()
        .eq('user_id', currentUserId!)
        .eq('brief_date', today)
        .maybeSingle();
    return data != null ? DailyBriefing.fromJson(data) : null;
  }

  // ─── Edge Functions ────────────────────────────────

  /// Call the parse-voice-input Edge Function
  Future<Map<String, dynamic>> parseVoiceInput({
    required String rawText,
    required String source,
    String? audioUrl,
  }) async {
    final settings = await getUserSettings();
    final response = await _client.functions.invoke(
      'parse-voice-input',
      body: {
        'raw_text': rawText,
        'source': source,
        'audio_url': audioUrl,
        'user_timezone': 'Asia/Riyadh',
        'current_datetime': DateTime.now().toIso8601String(),
        'user_settings': {
          'after_asr_time': settings?.afterAsrTime ?? '15:30',
          'after_maghrib_time': settings?.afterMaghribTime ?? '18:30',
        },
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Call the generate-briefing Edge Function
  Future<Map<String, dynamic>> generateBriefing({
    required String briefingType,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await _client.functions.invoke(
      'generate-briefing',
      body: {
        'user_id': currentUserId,
        'briefing_type': briefingType,
        'date': today,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Task Events ──────────────────────────────────

  /// Get events for a task
  Future<List<TaskEvent>> getTaskEvents(String taskId) async {
    final data = await _client
        .from('task_events')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false);
    return data.map((json) => TaskEvent.fromJson(json)).toList();
  }

  /// Internal: log a task event
  Future<void> _logTaskEvent(
    String taskId,
    EventType event, {
    Map<String, dynamic>? payload,
  }) async {
    await _client.from('task_events').insert({
      'task_id': taskId,
      'event': event.name,
      'payload': payload,
    });
  }

  // ─── Stats ─────────────────────────────────────────

  /// Get task counts for the home screen
  Future<Map<String, int>> getTaskCounts() async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final todayCount = await _client
        .from('tasks')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('due_date', today)
        .neq('status', 'cancelled')
        .count(CountOption.exact);

    final overdueCount = await _client
        .from('tasks')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('status', 'pending')
        .lt('due_date', today)
        .count(CountOption.exact);

    final followupCount = await _client
        .from('tasks')
        .select('id')
        .eq('user_id', currentUserId!)
        .eq('item_type', 'followup')
        .eq('status', 'pending')
        .count(CountOption.exact);

    return {
      'today': todayCount.count,
      'overdue': overdueCount.count,
      'followup': followupCount.count,
    };
  }
}
