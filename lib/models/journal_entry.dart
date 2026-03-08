class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String mood;
  final DateTime timestamp;
  final List<String> tags;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map, String docId) {
    return JournalEntry(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      mood: map['mood'] ?? 'Neutral',
      timestamp: DateTime.parse(map['timestamp'] as String),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? mood,
    DateTime? timestamp,
    List<String>? tags,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
    );
  }
}
