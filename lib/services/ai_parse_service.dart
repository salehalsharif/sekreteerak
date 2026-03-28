import '../services/supabase_service.dart';

/// AI Parse Service — bridges voice/text input to structured task data
/// Uses Supabase Edge Function which internally calls the configured AI provider.
/// The Flutter side is provider-agnostic: it does NOT know if DeepSeek or OpenAI is used.
class AiParseService {
  static AiParseService? _instance;
  static AiParseService get instance => _instance ??= AiParseService._();
  AiParseService._();

  final _supabase = SupabaseService.instance;

  /// Parse raw Arabic text into structured task data.
  /// Creates an inbox entry, calls the Edge Function, and stores metadata.
  Future<ParseResult> parseInput({
    required String rawText,
    String source = 'voice',
    String? audioUrl,
  }) async {
    try {
      // Step 1: Create inbox entry
      final entry = await _supabase.createInboxEntry({
        'raw_text': rawText,
        'source': source,
        'original_audio_url': audioUrl,
        'status': 'pending',
      });

      // Step 2: Call edge function
      final result = await _supabase.parseVoiceInput(
        rawText: rawText,
        source: source,
        audioUrl: audioUrl,
      );

      final success = result['success'] as bool? ?? false;

      if (!success) {
        // Store failure metadata
        await _supabase.updateInboxEntry(entry.id, {
          'status': 'failed',
          'parse_error': result['error'] as String? ?? 'Unknown error',
          'provider': result['provider'] as String?,
          'prompt_version': result['prompt_version'] as String?,
          'parse_attempts': result['parse_attempts'] as int? ?? 0,
          'parse_latency_ms': result['parse_latency_ms'] as int?,
          'parsed_at': DateTime.now().toIso8601String(),
        });
        throw ParseException(
          result['error'] as String? ?? 'فشل تحليل النص',
        );
      }

      final parsed = result['parsed'] as Map<String, dynamic>;

      // Step 3: Store success metadata
      await _supabase.updateInboxEntry(entry.id, {
        'parsed_json': parsed,
        'status': 'parsed',
        'provider': result['provider'] as String?,
        'model': result['model'] as String?,
        'prompt_version': result['prompt_version'] as String?,
        'parse_attempts': result['parse_attempts'] as int? ?? 1,
        'parse_latency_ms': result['parse_latency_ms'] as int?,
        'parsed_at': DateTime.now().toIso8601String(),
      });

      return ParseResult(
        entryId: entry.id,
        title: parsed['title'] as String? ?? rawText,
        itemType: parsed['item_type'] as String? ?? 'task',
        dueDate: parsed['due_date'] as String?,
        dueTime: parsed['due_time'] as String?,
        priority: parsed['priority'] as String? ?? 'medium',
        linkedPerson: parsed['linked_person'] as String?,
        recurrenceRule: parsed['recurrence_rule'] as String?,
        isFollowup: parsed['is_followup'] as bool? ?? false,
        notes: parsed['notes'] as String? ?? '',
        reminderOffsetMinutes: parsed['reminder_offset_minutes'] as int? ?? 30,
        confirmationText: result['confirmation_text'] as String? ??
            parsed['confirmation_text'] as String? ??
            'تم إضافة المهمة',
        rawParsedJson: parsed,
        // Metadata — provider-agnostic on the Flutter side
        provider: result['provider'] as String?,
        model: result['model'] as String?,
        promptVersion: result['prompt_version'] as String?,
        parseAttempts: result['parse_attempts'] as int? ?? 1,
        parseLatencyMs: result['parse_latency_ms'] as int?,
      );
    } on ParseException {
      rethrow;
    } catch (e) {
      throw ParseException('فشل تحليل النص: $e');
    }
  }

  /// Create a task from a ParseResult
  Future<void> createTaskFromParsed(ParseResult result) async {
    final taskData = <String, dynamic>{
      'title': result.title,
      'item_type': result.itemType,
      'priority': result.priority,
      'source_entry_id': result.entryId,
    };

    if (result.dueDate != null) {
      taskData['due_date'] = result.dueDate;
    }
    if (result.dueTime != null) {
      taskData['due_time'] = result.dueTime;
    }
    if (result.linkedPerson != null) {
      taskData['linked_person'] = result.linkedPerson;
    }
    if (result.recurrenceRule != null) {
      taskData['recurrence_rule'] = result.recurrenceRule;
    }
    if (result.notes.isNotEmpty) {
      taskData['description'] = result.notes;
    }

    // Calculate reminder_at from due_date + due_time - offset
    if (result.dueDate != null && result.dueTime != null) {
      final dueDt = DateTime.parse('${result.dueDate}T${result.dueTime}:00');
      final reminderAt = dueDt.subtract(
        Duration(minutes: result.reminderOffsetMinutes),
      );
      taskData['reminder_at'] = reminderAt.toIso8601String();
    }

    await _supabase.createTask(taskData);
  }
}

/// Result from AI parsing — includes observability metadata
class ParseResult {
  final String entryId;
  final String title;
  final String itemType;
  final String? dueDate;
  final String? dueTime;
  final String priority;
  final String? linkedPerson;
  final String? recurrenceRule;
  final bool isFollowup;
  final String notes;
  final int reminderOffsetMinutes;
  final String confirmationText;
  final Map<String, dynamic> rawParsedJson;

  // ── Observability metadata ──
  final String? provider;
  final String? model;
  final String? promptVersion;
  final int parseAttempts;
  final int? parseLatencyMs;

  const ParseResult({
    required this.entryId,
    required this.title,
    required this.itemType,
    this.dueDate,
    this.dueTime,
    required this.priority,
    this.linkedPerson,
    this.recurrenceRule,
    this.isFollowup = false,
    this.notes = '',
    this.reminderOffsetMinutes = 30,
    required this.confirmationText,
    required this.rawParsedJson,
    this.provider,
    this.model,
    this.promptVersion,
    this.parseAttempts = 1,
    this.parseLatencyMs,
  });

  /// Create a mutable copy for editing in the preview screen
  Map<String, dynamic> toEditableMap() {
    return {
      'title': title,
      'item_type': itemType,
      'due_date': dueDate,
      'due_time': dueTime,
      'priority': priority,
      'linked_person': linkedPerson,
      'recurrence_rule': recurrenceRule,
      'notes': notes,
      'reminder_offset_minutes': reminderOffsetMinutes,
    };
  }

  /// Debug/analytics summary
  Map<String, dynamic> toMetadataMap() {
    return {
      'provider': provider,
      'model': model,
      'prompt_version': promptVersion,
      'parse_attempts': parseAttempts,
      'parse_latency_ms': parseLatencyMs,
    };
  }
}

class ParseException implements Exception {
  final String message;
  const ParseException(this.message);

  @override
  String toString() => message;
}
