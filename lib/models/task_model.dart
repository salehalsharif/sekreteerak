/// Task model representing a task/meeting/followup/reminder/idea/shopping item
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final ItemType itemType;
  final TaskStatus status;
  final PriorityLevel priority;
  final DateTime? dueDate;
  final String? dueTime; // HH:MM format
  final DateTime? reminderAt;
  final String? recurrenceRule;
  final String? linkedPerson;
  final String? sourceEntryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.itemType = ItemType.task,
    this.status = TaskStatus.pending,
    this.priority = PriorityLevel.medium,
    this.dueDate,
    this.dueTime,
    this.reminderAt,
    this.recurrenceRule,
    this.linkedPerson,
    this.sourceEntryId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Whether the task is overdue
  bool get isOverdue {
    if (status != TaskStatus.pending || dueDate == null) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  /// Whether the task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Arabic label for the item type
  String get itemTypeLabel {
    switch (itemType) {
      case ItemType.task:
        return 'مهمة';
      case ItemType.meeting:
        return 'موعد';
      case ItemType.followup:
        return 'متابعة';
      case ItemType.reminder:
        return 'تذكير';
      case ItemType.idea:
        return 'فكرة';
      case ItemType.shopping:
        return 'مشتريات';
    }
  }

  /// Arabic label for priority
  String get priorityLabel {
    switch (priority) {
      case PriorityLevel.high:
        return 'عالية';
      case PriorityLevel.medium:
        return 'متوسطة';
      case PriorityLevel.low:
        return 'منخفضة';
    }
  }

  /// Arabic label for status
  String get statusLabel {
    switch (status) {
      case TaskStatus.pending:
        return 'قيد الانتظار';
      case TaskStatus.done:
        return 'مكتملة';
      case TaskStatus.snoozed:
        return 'مؤجلة';
      case TaskStatus.cancelled:
        return 'ملغاة';
    }
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      itemType: ItemType.values.firstWhere(
        (e) => e.name == json['item_type'],
        orElse: () => ItemType.task,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: PriorityLevel.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => PriorityLevel.medium,
      ),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      dueTime: json['due_time'] as String?,
      reminderAt: json['reminder_at'] != null
          ? DateTime.parse(json['reminder_at'] as String)
          : null,
      recurrenceRule: json['recurrence_rule'] as String?,
      linkedPerson: json['linked_person'] as String?,
      sourceEntryId: json['source_entry_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'item_type': itemType.name,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'due_time': dueTime,
      'reminder_at': reminderAt?.toIso8601String(),
      'recurrence_rule': recurrenceRule,
      'linked_person': linkedPerson,
      'source_entry_id': sourceEntryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ItemType? itemType,
    TaskStatus? status,
    PriorityLevel? priority,
    DateTime? dueDate,
    String? dueTime,
    DateTime? reminderAt,
    String? recurrenceRule,
    String? linkedPerson,
    String? sourceEntryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminderAt: reminderAt ?? this.reminderAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      linkedPerson: linkedPerson ?? this.linkedPerson,
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Task item types
enum ItemType {
  task,
  meeting,
  followup,
  reminder,
  idea,
  shopping,
}

/// Task status values
enum TaskStatus {
  pending,
  done,
  snoozed,
  cancelled,
}

/// Priority levels
enum PriorityLevel {
  low,
  medium,
  high,
}
