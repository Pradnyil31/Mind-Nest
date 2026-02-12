import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final DateTime? earnedDate;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    this.earnedDate,
  });

  // Predefined badges
  static final List<Badge> allBadges = [
    Badge(
      id: 'first_step',
      name: 'First Step',
      description: 'Completed your first routine',
      emoji: '🌟',
    ),
    Badge(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Completed 7 days in a row',
      emoji: '🔥',
    ),
    Badge(
      id: 'perfect_week',
      name: 'Perfect Week',
      description: 'All activities completed for a week',
      emoji: '⭐',
    ),
    Badge(
      id: 'meditation_master',
      name: 'Meditation Master',
      description: 'Meditated 10 times',
      emoji: '🧘',
    ),
    Badge(
      id: 'journal_warrior',
      name: 'Journal Warrior',
      description: 'Created 15 journal entries',
      emoji: '📓',
    ),
    Badge(
      id: 'goal_crusher',
      name: 'Goal Crusher',
      description: 'Achieved 3 goals',
      emoji: '🎯',
    ),
  ];

  Map<String, dynamic> toMap() {
    return {
      'badgeId': id,
      'badgeName': name,
      'description': description,
      'emoji': emoji,
      'earnedDate': earnedDate != null ? Timestamp.fromDate(earnedDate!) : null,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['badgeId'] ?? '',
      name: map['badgeName'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '🏆',
      earnedDate: map['earnedDate'] != null ? (map['earnedDate'] as Timestamp).toDate() : null,
    );
  }

  Badge copyWith({String? name, String? emoji, DateTime? earnedDate}) {
    return Badge(
      id: id,
      name: name ?? this.name,
      description: description,
      emoji: emoji ?? this.emoji,
      earnedDate: earnedDate ?? this.earnedDate,
    );
  }
}
