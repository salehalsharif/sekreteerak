import 'local_storage_service.dart';

/// AI Parse Service — bridges voice/text input to structured task data.
/// Currently operates in LOCAL mode: parses text locally and saves to SharedPreferences.
/// When Supabase is configured, it will use the Edge Function for AI-powered parsing.
class AiParseService {
  static AiParseService? _instance;
  static AiParseService get instance => _instance ??= AiParseService._();
  AiParseService._();

  final _localStorage = LocalStorageService.instance;

  /// Parse raw Arabic text into structured task data.
  /// In local mode, does basic keyword extraction instead of calling AI.
  Future<ParseResult> parseInput({
    required String rawText,
    String source = 'voice',
    String? audioUrl,
  }) async {
    final text = rawText.trim();

    // Basic local parsing: extract keywords
    final title = text;
    String itemType = 'task';
    String priority = 'medium';
    String? dueDate;
    String? dueTime;
    String? linkedPerson;
    bool isFollowup = false;

    // Detect item type from keywords
    if (_containsAny(text, ['موعد', 'اجتماع', 'مقابلة'])) {
      itemType = 'meeting';
    } else if (_containsAny(text, ['تابع', 'متابعة', 'راجع'])) {
      itemType = 'followup';
      isFollowup = true;
    } else if (_containsAny(text, ['ذكرني', 'تذكير', 'لا تنسى'])) {
      itemType = 'reminder';
    } else if (_containsAny(text, ['فكرة', 'اقتراح'])) {
      itemType = 'idea';
    } else if (_containsAny(text, ['اشتري', 'مشتريات', 'شراء'])) {
      itemType = 'shopping';
    }

    // Detect priority
    if (_containsAny(text, ['عاجل', 'ضروري', 'مهم جداً', 'أولوية'])) {
      priority = 'high';
    } else if (_containsAny(text, ['بسيط', 'عادي', 'لو سمحت'])) {
      priority = 'low';
    }

    // Detect date
    final now = DateTime.now();
    if (_containsAny(text, ['اليوم'])) {
      dueDate = _formatDate(now);
    } else if (_containsAny(text, ['بكرة', 'بكرا', 'غداً', 'غدا'])) {
      dueDate = _formatDate(now.add(const Duration(days: 1)));
    } else if (_containsAny(text, ['بعد بكرة', 'بعد بكرا'])) {
      dueDate = _formatDate(now.add(const Duration(days: 2)));
    } else {
      // Default: today
      dueDate = _formatDate(now);
    }

    // Detect time (basic patterns)
    final timeMatch = RegExp(r'الساعة?\s*(\d{1,2})').firstMatch(text);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      dueTime = '${hour.toString().padLeft(2, '0')}:00';
    }

    // Detect linked person (after "مع")
    final personMatch = RegExp(r'مع\s+(\S+)').firstMatch(text);
    if (personMatch != null) {
      linkedPerson = personMatch.group(1);
    }

    // Build confirmation
    String confirmation = '✅ تمت إضافة: $title';

    return ParseResult(
      entryId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      itemType: itemType,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      linkedPerson: linkedPerson,
      isFollowup: isFollowup,
      confirmationText: confirmation,
      rawParsedJson: {
        'title': title,
        'item_type': itemType,
        'priority': priority,
        'due_date': dueDate,
        'due_time': dueTime,
        'linked_person': linkedPerson,
      },
    );
  }

  /// Create a task from a ParseResult — saves locally
  Future<void> createTaskFromParsed(ParseResult result) async {
    final taskData = <String, dynamic>{
      'title': result.title,
      'item_type': result.itemType,
      'priority': result.priority,
    };

    if (result.dueDate != null) taskData['due_date'] = result.dueDate;
    if (result.dueTime != null) taskData['due_time'] = result.dueTime;
    if (result.linkedPerson != null) taskData['linked_person'] = result.linkedPerson;
    if (result.recurrenceRule != null) taskData['recurrence_rule'] = result.recurrenceRule;
    if (result.notes.isNotEmpty) taskData['description'] = result.notes;

    await _localStorage.createTask(taskData);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Result from parsing
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

  // Observability metadata (optional)
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

  Map<String, dynamic> toEditableMap() {
    return {
      'title': title,
      'item_type': itemType,
      'due_date': dueDate,
      'due_time': dueTime,
      'priority': priority,
      'linked_person': linkedPerson,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMetadataMap() {
    return {
      'provider': provider ?? 'local',
      'parse_attempts': parseAttempts,
    };
  }
}

class ParseException implements Exception {
  final String message;
  const ParseException(this.message);

  @override
  String toString() => message;
}
