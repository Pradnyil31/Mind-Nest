import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import 'firestore_service.dart';

class MeditationAnalyticsService {
  final FirebaseFirestore _firestore;

  MeditationAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _sessionsCollection => _firestore.collection('meditation_sessions');
  
  DocumentReference _userStatsDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('meditation_stats').doc('summary');
  }

  /// Calculate current meditation streak for a user
  Future<int> getCurrentStreak(String userId) async {
    try {
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return 0;
      
      final validSessions = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['completed'] == true && data['startTime'] != null;
      }).toList();
      
      validSessions.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final timeA = (dataA['startTime'] as Timestamp).toDate();
        final timeB = (dataB['startTime'] as Timestamp).toDate();
        return timeB.compareTo(timeA); // descending
      });

      if (validSessions.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int streak = 0;
      DateTime? lastDate;

      for (var doc in validSessions) {
        final data = doc.data() as Map<String, dynamic>;
        final sessionDate = (data['startTime'] as Timestamp).toDate();
        final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);

        if (lastDate == null) {
          // First session - check if it's today or yesterday
          final daysDiff = today.difference(sessionDay).inDays;
          if (daysDiff > 1) return 0; // Too old, no current streak
          streak = 1;
          lastDate = sessionDay;
        } else {
          // Check if this session is the day before the last counted day
          final daysDiff = lastDate.difference(sessionDay).inDays;
          if (daysDiff == 1) {
            streak++;
            lastDate = sessionDay;
          } else if (daysDiff == 0) {
            // Same day, don't increment streak but continue checking
            continue;
          } else {
            // Gap in streak, stop counting
            break;
          }
        }
      }

      return streak;
    } catch (e, stackTrace) {
      appLogger.e('Error calculating streak', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Check if user has meditated today
  Future<bool> hasMeditatedToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .get();
          
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['completed'] == true && data['startTime'] != null) {
          final sessionDate = (data['startTime'] as Timestamp).toDate();
          if (sessionDate.isAfter(startOfDay) || sessionDate.isAtSameMomentAs(startOfDay)) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e, stackTrace) {
      appLogger.e('Error checking today\'s meditation', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get meditation calendar data for the last 30 days
  Future<Map<DateTime, int>> getMeditationCalendar(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .get();

      Map<DateTime, int> calendar = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['completed'] == true && data['startTime'] != null) {
          final sessionDate = (data['startTime'] as Timestamp).toDate();
          if (sessionDate.isAfter(thirtyDaysAgo) || sessionDate.isAtSameMomentAs(thirtyDaysAgo)) {
            final day = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
            calendar[day] = (calendar[day] ?? 0) + 1;
          }
        }
      }

      return calendar;
    } catch (e, stackTrace) {
      appLogger.e('Error getting meditation calendar', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Update user's meditation statistics
  Future<void> updateStats(String userId, int durationMinutes) async {
    try {
      final statsRef = _userStatsDoc(userId);
      final snapshot = await statsRef.get();

      if (!snapshot.exists) {
        // Create initial stats
        await statsRef.set({
          'totalSessions': 1,
          'totalMinutes': durationMinutes,
          'lastMeditationDate': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing stats
        await statsRef.update({
          'totalSessions': FieldValue.increment(1),
          'totalMinutes': FieldValue.increment(durationMinutes),
          'lastMeditationDate': FieldValue.serverTimestamp(),
        });
      }

      // Log completion for badge system — only fires after a full session
      FirestoreService().logActivityCompletion(userId, 'meditation');
    } catch (e, stackTrace) {
      appLogger.e('Error updating meditation stats', error: e, stackTrace: stackTrace);
    }
  }

  /// Get user's meditation statistics
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final snapshot = await _userStatsDoc(userId).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
      };
    } catch (e, stackTrace) {
      appLogger.e('Error getting meditation stats', error: e, stackTrace: stackTrace);
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
      };
    }
  }
}
