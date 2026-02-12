import 'package:cloud_firestore/cloud_firestore.dart';

enum MeditationType { guided, timer, breathing }

class MeditationSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final int durationMinutes;
  final MeditationType type;
  final String? meditationId; // ID of guided meditation if applicable
  final bool completed;

  MeditationSession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.durationMinutes,
    this.type = MeditationType.timer,
    this.meditationId,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'type': type.toString().split('.').last,
      'meditationId': meditationId,
      'completed': completed,
    };
  }

  factory MeditationSession.fromMap(Map<String, dynamic> map, String docId) {
    return MeditationSession(
      id: docId,
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 5,
      type: MeditationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MeditationType.timer,
      ),
      meditationId: map['meditationId'],
      completed: map['completed'] ?? false,
    );
  }
}
