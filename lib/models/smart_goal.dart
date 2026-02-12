import 'package:cloud_firestore/cloud_firestore.dart';

class SmartGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime deadline;
  final int colorValue; // Store int value of color
  final bool isCompleted;

  SmartGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.deadline,
    required this.colorValue,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'deadline': Timestamp.fromDate(deadline),
      'colorValue': colorValue,
      'isCompleted': isCompleted,
    };
  }

  factory SmartGoal.fromMap(Map<String, dynamic> map, String docId) {
    return SmartGoal(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetValue: (map['targetValue'] ?? 0).toDouble(),
      currentValue: (map['currentValue'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      colorValue: map['colorValue'] ?? 0xFF4CAF50, // Default Green
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  SmartGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? deadline,
    int? colorValue,
    bool? isCompleted,
  }) {
    return SmartGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
