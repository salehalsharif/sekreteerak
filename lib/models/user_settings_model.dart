/// User settings model
class UserSettings {
  final String id;
  final String userId;
  final int defaultReminderMinutes;
  final String workdayStart;
  final String workdayEnd;
  final String afterAsrTime;
  final String afterMaghribTime;
  final bool summaryEnabled;
  final String morningSummaryTime;
  final String eveningSummaryTime;

  const UserSettings({
    required this.id,
    required this.userId,
    this.defaultReminderMinutes = 30,
    this.workdayStart = '08:00',
    this.workdayEnd = '18:00',
    this.afterAsrTime = '15:30',
    this.afterMaghribTime = '18:30',
    this.summaryEnabled = true,
    this.morningSummaryTime = '07:00',
    this.eveningSummaryTime = '21:00',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      defaultReminderMinutes: json['default_reminder_minutes'] as int? ?? 30,
      workdayStart: json['workday_start'] as String? ?? '08:00',
      workdayEnd: json['workday_end'] as String? ?? '18:00',
      afterAsrTime: json['after_asr_time'] as String? ?? '15:30',
      afterMaghribTime: json['after_maghrib_time'] as String? ?? '18:30',
      summaryEnabled: json['summary_enabled'] as bool? ?? true,
      morningSummaryTime: json['morning_summary_time'] as String? ?? '07:00',
      eveningSummaryTime: json['evening_summary_time'] as String? ?? '21:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'default_reminder_minutes': defaultReminderMinutes,
      'workday_start': workdayStart,
      'workday_end': workdayEnd,
      'after_asr_time': afterAsrTime,
      'after_maghrib_time': afterMaghribTime,
      'summary_enabled': summaryEnabled,
      'morning_summary_time': morningSummaryTime,
      'evening_summary_time': eveningSummaryTime,
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    int? defaultReminderMinutes,
    String? workdayStart,
    String? workdayEnd,
    String? afterAsrTime,
    String? afterMaghribTime,
    bool? summaryEnabled,
    String? morningSummaryTime,
    String? eveningSummaryTime,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      workdayStart: workdayStart ?? this.workdayStart,
      workdayEnd: workdayEnd ?? this.workdayEnd,
      afterAsrTime: afterAsrTime ?? this.afterAsrTime,
      afterMaghribTime: afterMaghribTime ?? this.afterMaghribTime,
      summaryEnabled: summaryEnabled ?? this.summaryEnabled,
      morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
      eveningSummaryTime: eveningSummaryTime ?? this.eveningSummaryTime,
    );
  }
}
