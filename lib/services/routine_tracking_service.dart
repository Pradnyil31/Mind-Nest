import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine_completion.dart';
import '../core/logger.dart';

class RoutineTrackingService {
  final FirebaseFirestore _firestore;

  RoutineTrackingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _completionsCollection =>
      _firestore.collection('routine_completions');

  /// Mark an activity as complete for today
  Future<void> markActivityComplete(
    String userId,
    String activity,
    List<String> allActivities,
  ) async {
    try {
      final today = DateTime.now();
      final dateId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get today's completion or create a new one
      final docRef = _completionsCollection.doc('${userId}_$dateId');
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing
        final data = doc.data() as Map<String, dynamic>;
        final completed = List<String>.from(data['completedActivities'] ?? []);
        
        if (!completed.contains(activity)) {
          completed.add(activity);
          await docRef.update({
            'completedActivities': completed,
          });
        }
      } else {
        // Create new
        final completion = RoutineCompletion(
          id: '${userId}_$dateId',
          userId: userId,
          date: DateTime(today.year, today.month, today.day),
          completedActivities: [activity],
          totalActivities: allActivities.length,
        );
        await docRef.set(completion.toMap());
      }
    } catch (e, stackTrace) {
      appLogger.e('Error marking activity complete', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Unmark an activity (if user unchecks)
  Future<void> unmarkActivityComplete(
    String userId,
    String activity,
  ) async {
    try {
      final today = DateTime.now();
      final dateId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final docRef = _completionsCollection.doc('${userId}_$dateId');
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final completed = List<String>.from(data['completedActivities'] ?? []);
        
        if (completed.contains(activity)) {
          completed.remove(activity);
          await docRef.update({
            'completedActivities': completed,
          });
        }
      }
    } catch (e, stackTrace) {
      appLogger.e('Error unmarking activity', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }



  /// Get today's completed activities as a Stream
  Stream<List<String>> getTodayCompletedActivitiesStream(String userId) {
    try {
      final today = DateTime.now();
      final dateId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return _completionsCollection.doc('${userId}_$dateId').snapshots().map((doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['completedActivities'] ?? []);
        }
        return <String>[];
      });
    } catch (e, stackTrace) {
      appLogger.e('Error getting today\'s activities stream', error: e, stackTrace: stackTrace);
      return Stream.value([]);
    }
  }

  /// Get today's completed activities
  Future<List<String>> getTodayCompletedActivities(String userId) async {
    try {
      final today = DateTime.now();
      final dateId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _completionsCollection.doc('${userId}_$dateId').get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['completedActivities'] ?? []);
      }
      return [];
    } catch (e, stackTrace) {
      appLogger.e('Error getting today\'s activities', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get completions for the past week
  Future<List<RoutineCompletion>> getWeekCompletions(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _completionsCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => RoutineCompletion.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e, stackTrace) {
      appLogger.e('Error getting week completions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get current streak (consecutive days with at least 1 activity)
  Future<int> getCompletionStreak(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startWindow = today.subtract(const Duration(days: 365));

      final snapshot = await _completionsCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startWindow))
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              today.add(const Duration(days: 1)),
            ),
          )
          .orderBy('date', descending: true)
          .limit(400)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final activeDays = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final completed = List<String>.from(data['completedActivities'] ?? []);
        if (completed.isEmpty) continue;

        final ts = data['date'];
        if (ts is! Timestamp) continue;
        final d = ts.toDate();
        final dayKey =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        activeDays.add(dayKey);
      }

      var streak = 0;
      var cursor = today;
      while (true) {
        final dayKey =
            '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
        if (!activeDays.contains(dayKey)) {
          break;
        }
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e, stackTrace) {
      appLogger.e('Error calculating streak', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Returns active weekdays (1=Mon..7=Sun) with any completion in current week.
  Future<Set<int>> getActiveDaysThisWeek(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday % 7));

      final snapshot = await _completionsCollection
          .where('userId', isEqualTo: userId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .orderBy('date', descending: true)
          .limit(40)
          .get();

      final activeDays = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final completed = List<String>.from(data['completedActivities'] ?? []);
        if (completed.isEmpty) continue;

        final ts = data['date'];
        if (ts is! Timestamp) continue;
        activeDays.add(ts.toDate().weekday);
      }

      return activeDays;
    } catch (e, stackTrace) {
      appLogger.e('Error getting active days this week', error: e, stackTrace: stackTrace);
      return <int>{};
    }
  }

  /// True when user has completed at least one routine activity today.
  Future<bool> hasAnyCompletedActivityToday(String userId) async {
    final completed = await getTodayCompletedActivities(userId);
    return completed.isNotEmpty;
  }

  /// Get all routine completion docs for a user ordered by date (asc).
  Future<List<RoutineCompletion>> getAllCompletions(String userId) async {
    try {
      final snapshot = await _completionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => RoutineCompletion.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      appLogger.e('Error getting all completions', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Returns today's completion counts.
  Future<Map<String, int>> getTodayCompletionSummary(String userId) async {
    try {
      final today = DateTime.now();
      final dateId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _completionsCollection.doc('${userId}_$dateId').get();
      if (!doc.exists) {
        return {'completed': 0, 'total': 0};
      }

      final data = doc.data() as Map<String, dynamic>;
      final completed = List<String>.from(data['completedActivities'] ?? []).length;
      final total = (data['totalActivities'] as int?) ?? 0;
      return {'completed': completed, 'total': total};
    } catch (e, stackTrace) {
      appLogger.e('Error getting today completion summary', error: e, stackTrace: stackTrace);
      return {'completed': 0, 'total': 0};
    }
  }
}
