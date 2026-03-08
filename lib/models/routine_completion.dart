class RoutineCompletion {
  final String id;
  final String userId;
  final DateTime date;
  final List<String> completedActivities;
  final int totalActivities;

  RoutineCompletion({
    required this.id,
    required this.userId,
    required this.date,
    required this.completedActivities,
    required this.totalActivities,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'completedActivities': completedActivities,
      'totalActivities': totalActivities,
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map, String docId) {
    return RoutineCompletion(
      id: docId,
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] as String),
      completedActivities: List<String>.from(map['completedActivities'] ?? []),
      totalActivities: map['totalActivities'] ?? 0,
    );
  }
}
