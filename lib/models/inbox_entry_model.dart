/// Inbox entry model — raw voice/text captured inputs
class InboxEntry {
  final String id;
  final String userId;
  final String? rawText;
  final SourceType source;
  final String? originalAudioUrl;
  final Map<String, dynamic>? parsedJson;
  final ParseStatus status;
  final DateTime createdAt;

  const InboxEntry({
    required this.id,
    required this.userId,
    this.rawText,
    this.source = SourceType.voice,
    this.originalAudioUrl,
    this.parsedJson,
    this.status = ParseStatus.pending,
    required this.createdAt,
  });

  /// Whether parsing is complete
  bool get isParsed => status == ParseStatus.parsed;

  /// Whether parsing failed
  bool get isFailed => status == ParseStatus.failed;

  factory InboxEntry.fromJson(Map<String, dynamic> json) {
    return InboxEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      rawText: json['raw_text'] as String?,
      source: SourceType.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => SourceType.voice,
      ),
      originalAudioUrl: json['original_audio_url'] as String?,
      parsedJson: json['parsed_json'] as Map<String, dynamic>?,
      status: ParseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ParseStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'raw_text': rawText,
      'source': source.name,
      'original_audio_url': originalAudioUrl,
      'parsed_json': parsedJson,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum SourceType { voice, text }

enum ParseStatus { pending, parsed, failed }
