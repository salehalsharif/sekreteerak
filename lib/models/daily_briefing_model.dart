/// Daily briefing model
class DailyBriefing {
  final String id;
  final String userId;
  final DateTime briefDate;
  final String? morningSummary;
  final String? eveningSummary;
  final DateTime generatedAt;

  const DailyBriefing({
    required this.id,
    required this.userId,
    required this.briefDate,
    this.morningSummary,
    this.eveningSummary,
    required this.generatedAt,
  });

  factory DailyBriefing.fromJson(Map<String, dynamic> json) {
    return DailyBriefing(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      briefDate: DateTime.parse(json['brief_date'] as String),
      morningSummary: json['morning_summary'] as String?,
      eveningSummary: json['evening_summary'] as String?,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brief_date': briefDate.toIso8601String().split('T').first,
      'morning_summary': morningSummary,
      'evening_summary': eveningSummary,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}
