import 'package:cloud_firestore/cloud_firestore.dart';

enum FocusMode { timer, sound, video }

class FocusSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final int durationMinutes;
  final String taskName;
  final FocusMode mode;
  final String? resourceId; // URL for video or asset path for sound
  final bool completed;

  FocusSession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.durationMinutes,
    this.taskName = 'Focus Session',
    this.mode = FocusMode.timer,
    this.resourceId,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'taskName': taskName,
      'mode': mode.toString().split('.').last,
      'resourceId': resourceId,
      'completed': completed,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map, String docId) {
    return FocusSession(
      id: docId,
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 25,
      taskName: map['taskName'] ?? 'Focus Session',
      mode: FocusMode.values.firstWhere(
        (e) => e.toString().split('.').last == map['mode'],
        orElse: () => FocusMode.timer,
      ),
      resourceId: map['resourceId'],
      completed: map['completed'] ?? false,
    );
  }
}
