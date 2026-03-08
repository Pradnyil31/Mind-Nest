
import '../core/logger.dart';

class MeditationAnalyticsService {
  // TODO: Implement Supabase integration for meditation analytics
  
  /// Calculate current meditation streak for a user
  Future<int> getCurrentStreak(String userId) async {
    // Stub - returns 0
    return 0;
  }

  /// Check if user has meditated today
  Future<bool> hasMeditatedToday(String userId) async {
    // Stub
    return false;
  }

  /// Get meditation calendar data
  Future<Map<DateTime, int>> getMeditationCalendar(String userId) async {
    // Stub
    return {};
  }

  /// Get meditation statistics
  Future<Map<String, dynamic>> getStats(String userId) async {
    return {
      'totalSessions': 0,
      'totalMinutes': 0,
      'currentStreak': 0,
    };
  }

  /// Update meditation statistics
  Future<void> updateStats(String userId, int durationMinutes) async {
    // TODO: Connect to Supabase
  }
}

  /// Calculate current meditation streak for a user
  Future<int> getCurrentStreak(String userId) async {
    try {
      final sessions = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .get();

      if (sessions.docs.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int streak = 0;
      DateTime? lastDate;

      for (var doc in sessions.docs) {
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
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
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
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      Map<DateTime, int> calendar = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final sessionDate = (data['startTime'] as Timestamp).toDate();
        final day = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
        
        calendar[day] = (calendar[day] ?? 0) + 1;
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
