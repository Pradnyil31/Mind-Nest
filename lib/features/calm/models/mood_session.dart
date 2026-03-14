import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a mood tracking session for a calm technique
/// Tracks pre/post mood ratings and calculates improvement
class MoodSession {
  final String id;
  final String userId;
  final String techniqueId;
  final int? preMoodRating;
  final int? postMoodRating;
  final DateTime startTime;
  final DateTime? endTime;
  final int? moodImprovement;

  const MoodSession({
    required this.id,
    required this.userId,
    required this.techniqueId,
    this.preMoodRating,
    this.postMoodRating,
    required this.startTime,
    this.endTime,
    this.moodImprovement,
  });

  /// Create MoodSession from Firestore document
  factory MoodSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MoodSession(
      id: doc.id,
      userId: data['userId'] as String,
      techniqueId: data['techniqueId'] as String,
      preMoodRating: data['preMoodRating'] as int?,
      postMoodRating: data['postMoodRating'] as int?,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      moodImprovement: data['moodImprovement'] as int?,
    );
  }

  /// Convert MoodSession to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'techniqueId': techniqueId,
      'preMoodRating': preMoodRating,
      'postMoodRating': postMoodRating,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'moodImprovement': moodImprovement,
    };
  }

  /// Check if the session is complete (has both pre and post ratings)
  bool get isComplete => preMoodRating != null && postMoodRating != null;

  /// Get the duration of the session if completed
  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  /// Get mood improvement as a percentage (0-100%)
  /// Positive values indicate improvement, negative indicate worsening
  double? get improvementPercentage {
    if (moodImprovement == null || preMoodRating == null) return null;

    // Calculate improvement as percentage of possible improvement
    // If pre-mood was 3 and post-mood is 7, improvement is 4 out of possible 7 (10-3)
    if (moodImprovement! > 0) {
      final possibleImprovement = 10 - preMoodRating!;
      return possibleImprovement > 0
          ? (moodImprovement! / possibleImprovement) * 100
          : 0.0;
    } else if (moodImprovement! < 0) {
      // For negative improvement, calculate as percentage of possible decline
      final possibleDecline = preMoodRating! - 1;
      return possibleDecline > 0
          ? (moodImprovement!.abs() / possibleDecline) * 100
          : 0.0;
    }

    return 0.0; // No change
  }

  /// Get a human-readable description of the mood change
  String get improvementDescription {
    if (moodImprovement == null) return 'Incomplete session';

    if (moodImprovement! > 3) {
      return 'Significant improvement';
    } else if (moodImprovement! > 0) {
      return 'Mild improvement';
    } else if (moodImprovement! == 0) {
      return 'No change';
    } else if (moodImprovement! > -3) {
      return 'Slight decline';
    } else {
      return 'Significant decline';
    }
  }

  /// Copy with method for creating modified instances
  MoodSession copyWith({
    String? id,
    String? userId,
    String? techniqueId,
    int? preMoodRating,
    int? postMoodRating,
    DateTime? startTime,
    DateTime? endTime,
    int? moodImprovement,
  }) {
    return MoodSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      techniqueId: techniqueId ?? this.techniqueId,
      preMoodRating: preMoodRating ?? this.preMoodRating,
      postMoodRating: postMoodRating ?? this.postMoodRating,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      moodImprovement: moodImprovement ?? this.moodImprovement,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodSession &&
        other.id == id &&
        other.userId == userId &&
        other.techniqueId == techniqueId &&
        other.preMoodRating == preMoodRating &&
        other.postMoodRating == postMoodRating &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.moodImprovement == moodImprovement;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      techniqueId,
      preMoodRating,
      postMoodRating,
      startTime,
      endTime,
      moodImprovement,
    );
  }

  @override
  String toString() {
    return 'MoodSession(id: $id, userId: $userId, techniqueId: $techniqueId, '
        'preMoodRating: $preMoodRating, postMoodRating: $postMoodRating, '
        'startTime: $startTime, endTime: $endTime, '
        'moodImprovement: $moodImprovement)';
  }
}
