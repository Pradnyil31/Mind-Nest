class DailyCheckIn {
  final String id;
  final String userId;
  final DateTime date;
  final String mood;
  final int sleepQuality; // 1-10
  final int energyLevel; // 1-10
  final List<String> activeGoalsChecked;
  final String notes;

  DailyCheckIn({
    required this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.sleepQuality,
    required this.energyLevel,
    this.activeGoalsChecked = const [],
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'mood': mood,
      'sleepQuality': sleepQuality,
      'energyLevel': energyLevel,
      'activeGoalsChecked': activeGoalsChecked,
      'notes': notes,
    };
  }

  factory DailyCheckIn.fromMap(Map<String, dynamic> map, String docId) {
    return DailyCheckIn(
      id: docId,
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] ?? '',
      sleepQuality: map['sleepQuality'] ?? 5,
      energyLevel: map['energyLevel'] ?? 5,
      activeGoalsChecked: List<String>.from(map['activeGoalsChecked'] ?? []),
      notes: map['notes'] ?? '',
    );
  }
}
