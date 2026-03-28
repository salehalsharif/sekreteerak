/// Task event model — audit trail for task lifecycle
class TaskEvent {
  final String id;
  final String taskId;
  final EventType event;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  const TaskEvent({
    required this.id,
    required this.taskId,
    required this.event,
    this.payload,
    required this.createdAt,
  });

  /// Arabic label for event type
  String get eventLabel {
    switch (event) {
      case EventType.created:
        return 'تم الإنشاء';
      case EventType.edited:
        return 'تم التعديل';
      case EventType.snoozed:
        return 'تم التأجيل';
      case EventType.completed:
        return 'تم الإنجاز';
      case EventType.missed:
        return 'فات الموعد';
      case EventType.rescheduled:
        return 'تم إعادة الجدولة';
    }
  }

  factory TaskEvent.fromJson(Map<String, dynamic> json) {
    return TaskEvent(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      event: EventType.values.firstWhere(
        (e) => e.name == json['event'],
        orElse: () => EventType.created,
      ),
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'event': event.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum EventType {
  created,
  edited,
  snoozed,
  completed,
  missed,
  rescheduled,
}
