import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logger.dart';
import '../models/mood_session.dart';

/// Service for tracking user mood before and after calm techniques
/// Provides mood improvement calculation and trend analysis
class MoodTrackingService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference get _moodSessionsCollection =>
      _firestore.collection('mood_sessions');

  /// Record pre-technique mood rating
  /// Creates a new mood session with initial rating
  Future<String> recordPreMood(
    String userId,
    String techniqueId,
    int rating,
  ) async {
    try {
      if (rating < 1 || rating > 10) {
        throw ArgumentError('Mood rating must be between 1 and 10');
      }

      final sessionData = {
        'userId': userId,
        'techniqueId': techniqueId,
        'preMoodRating': rating,
        'startTime': FieldValue.serverTimestamp(),
        'postMoodRating': null,
        'endTime': null,
        'moodImprovement': null,
      };

      final docRef = await _moodSessionsCollection.add(sessionData);

      appLogger.i(
        'Pre-mood rating recorded: $rating for technique $techniqueId',
      );
      return docRef.id;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error recording pre-mood rating',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Record post-technique mood rating and calculate improvement
  Future<void> recordPostMood(String sessionId, int rating) async {
    try {
      if (rating < 1 || rating > 10) {
        throw ArgumentError('Mood rating must be between 1 and 10');
      }

      // Get the existing session to calculate improvement
      final sessionDoc = await _moodSessionsCollection.doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Mood session not found: $sessionId');
      }

      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final preMoodRating = sessionData['preMoodRating'] as int?;

      if (preMoodRating == null) {
        throw Exception('Pre-mood rating not found for session: $sessionId');
      }

      final moodImprovement = rating - preMoodRating;

      await _moodSessionsCollection.doc(sessionId).update({
        'postMoodRating': rating,
        'endTime': FieldValue.serverTimestamp(),
        'moodImprovement': moodImprovement,
      });

      appLogger.i(
        'Post-mood rating recorded: $rating (improvement: $moodImprovement)',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        'Error recording post-mood rating',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get mood trends and statistics for a user
  Future<Map<String, dynamic>> getMoodTrends(String userId) async {
    try {
      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .where('moodImprovement', isNotEqualTo: null)
          .orderBy('moodImprovement')
          .orderBy('startTime', descending: true)
          .limit(50) // Last 50 completed sessions
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalSessions': 0,
          'averageImprovement': 0.0,
          'improvementTrend': <Map<String, dynamic>>[],
          'bestTechniques': <Map<String, dynamic>>[],
          'recentSessions': <Map<String, dynamic>>[],
        };
      }

      final sessions = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Calculate average improvement
      final improvements = sessions
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final averageImprovement = improvements.isNotEmpty
          ? improvements.reduce((a, b) => a + b) / improvements.length
          : 0.0;

      // Calculate improvement trend (last 10 sessions)
      final recentSessions = sessions.take(10).toList();
      final improvementTrend = recentSessions
          .map(
            (session) => {
              'date': (session['startTime'] as Timestamp?)
                  ?.toDate()
                  .toIso8601String(),
              'improvement': session['moodImprovement'],
              'preMood': session['preMoodRating'],
              'postMood': session['postMoodRating'],
            },
          )
          .toList();

      // Find best techniques by average improvement
      final techniqueImprovements = <String, List<int>>{};
      for (final session in sessions) {
        final techniqueId = session['techniqueId'] as String;
        final improvement = session['moodImprovement'] as int;

        techniqueImprovements[techniqueId] =
            (techniqueImprovements[techniqueId] ?? [])..add(improvement);
      }

      final bestTechniques =
          techniqueImprovements.entries.map((entry) {
            final avgImprovement =
                entry.value.reduce((a, b) => a + b) / entry.value.length;
            return {
              'techniqueId': entry.key,
              'averageImprovement': avgImprovement,
              'sessionCount': entry.value.length,
            };
          }).toList()..sort(
            (a, b) => (b['averageImprovement'] as double).compareTo(
              a['averageImprovement'] as double,
            ),
          );

      return {
        'totalSessions': sessions.length,
        'averageImprovement': averageImprovement,
        'improvementTrend': improvementTrend,
        'bestTechniques': bestTechniques.take(5).toList(),
        'recentSessions': recentSessions.take(5).toList(),
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting mood trends',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'totalSessions': 0,
        'averageImprovement': 0.0,
        'improvementTrend': <Map<String, dynamic>>[],
        'bestTechniques': <Map<String, dynamic>>[],
        'recentSessions': <Map<String, dynamic>>[],
      };
    }
  }

  /// Get average mood improvement for a specific user
  Future<double> getAverageMoodImprovement(String userId) async {
    try {
      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .where('moodImprovement', isNotEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final improvements = snapshot.docs
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['moodImprovement'] as int,
          )
          .toList();

      return improvements.reduce((a, b) => a + b) / improvements.length;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting average mood improvement',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Get technique effectiveness based on mood improvement data
  Future<Map<String, double>> getTechniqueEffectiveness(String userId) async {
    try {
      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .where('moodImprovement', isNotEqualTo: null)
          .get();

      final techniqueImprovements = <String, List<int>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final techniqueId = data['techniqueId'] as String;
        final improvement = data['moodImprovement'] as int;

        techniqueImprovements[techniqueId] =
            (techniqueImprovements[techniqueId] ?? [])..add(improvement);
      }

      // Calculate average effectiveness for each technique
      final effectiveness = <String, double>{};
      techniqueImprovements.forEach((techniqueId, improvements) {
        final average =
            improvements.reduce((a, b) => a + b) / improvements.length;
        effectiveness[techniqueId] = average;
      });

      return effectiveness;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting technique effectiveness',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get recent mood sessions for a user
  Stream<List<MoodSession>> getRecentSessions(String userId, {int limit = 10}) {
    return _moodSessionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MoodSession.fromFirestore(doc))
              .toList(),
        );
  }

  /// Check if user has any mood tracking data
  Future<bool> hasAnyMoodData(String userId) async {
    try {
      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error checking mood data existence',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Delete all mood data for a user (for privacy compliance)
  Future<void> deleteUserMoodData(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      appLogger.i('Deleted all mood data for user: $userId');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error deleting user mood data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get mood improvement statistics for the last N days
  Future<Map<String, dynamic>> getMoodStatsForPeriod(
    String userId,
    int days,
  ) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _moodSessionsCollection
          .where('userId', isEqualTo: userId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .where('moodImprovement', isNotEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'sessionsCount': 0,
          'averageImprovement': 0.0,
          'bestDay': null,
          'totalImprovement': 0,
        };
      }

      final sessions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final improvements = sessions
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final totalImprovement = improvements.reduce((a, b) => a + b);
      final averageImprovement = totalImprovement / improvements.length;

      // Find best day (day with highest total improvement)
      final dailyImprovements = <String, int>{};
      for (final session in sessions) {
        final startTime = (session['startTime'] as Timestamp).toDate();
        final dateKey = '${startTime.year}-${startTime.month}-${startTime.day}';
        final improvement = session['moodImprovement'] as int;

        dailyImprovements[dateKey] =
            (dailyImprovements[dateKey] ?? 0) + improvement;
      }

      String? bestDay;
      int bestDayImprovement = 0;
      dailyImprovements.forEach((date, improvement) {
        if (improvement > bestDayImprovement) {
          bestDay = date;
          bestDayImprovement = improvement;
        }
      });

      return {
        'sessionsCount': sessions.length,
        'averageImprovement': averageImprovement,
        'bestDay': bestDay,
        'totalImprovement': totalImprovement,
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting mood stats for period',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'sessionsCount': 0,
        'averageImprovement': 0.0,
        'bestDay': null,
        'totalImprovement': 0,
      };
    }
  }
}
