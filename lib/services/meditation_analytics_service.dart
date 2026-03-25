import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import 'firestore_service.dart';

class MeditationAnalyticsService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  static const int _calendarWindowDays = 30;

  MeditationAnalyticsService({FirebaseFirestore? firestore, FirestoreService? firestoreService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService =
            firestoreService ?? FirestoreService(firestore: firestore ?? FirebaseFirestore.instance);

  CollectionReference get _sessionsCollection => _firestore.collection('meditation_sessions');

  DocumentReference _userStatsDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('meditation_stats').doc('summary');
  }

  DateTime _dayOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  String _dayKey(DateTime dateTime) {
    final day = _dayOnly(dateTime);
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  DateTime? _parseDayKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// Calculate current meditation streak for a user.
  Future<int> getCurrentStreak(String userId) async {
    try {
      final now = DateTime.now();
      final today = _dayOnly(now);
      final yesterday = today.subtract(const Duration(days: 1));

      // Fast path: summary metadata maintained on every session completion.
      final summary = await _userStatsDoc(userId).get();
      if (summary.exists) {
        final data = summary.data() as Map<String, dynamic>;
        final currentStreak = (data['currentStreak'] as int?) ?? 0;
        final lastDay = _parseDayKey(data['lastMeditationDay'] as String?);
        if (lastDay != null) {
          if (lastDay == today || lastDay == yesterday) {
            return currentStreak;
          }
          return 0;
        }
      }

      // Legacy fallback for users without summary streak metadata.
      final lookback = now.subtract(const Duration(days: 45));
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(lookback))
          .orderBy('startTime', descending: true)
          .limit(120)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final uniqueDays = <DateTime>[];
      final seen = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startTime = data['startTime'];
        if (startTime is! Timestamp) continue;

        final day = _dayOnly(startTime.toDate());
        final key = _dayKey(day);
        if (seen.add(key)) {
          uniqueDays.add(day);
        }
      }

      if (uniqueDays.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final sessionDay in uniqueDays) {
        if (lastDate == null) {
          final daysDiff = today.difference(sessionDay).inDays;
          if (daysDiff > 1) return 0;
          streak = 1;
          lastDate = sessionDay;
        } else {
          final daysDiff = lastDate.difference(sessionDay).inDays;
          if (daysDiff == 1) {
            streak++;
            lastDate = sessionDay;
          } else if (daysDiff == 0) {
            continue;
          } else {
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

  /// Check if user has meditated today.
  Future<bool> hasMeditatedToday(String userId) async {
    try {
      final now = DateTime.now();
      final today = _dayOnly(now);

      // Fast path from summary metadata.
      final summary = await _userStatsDoc(userId).get();
      if (summary.exists) {
        final data = summary.data() as Map<String, dynamic>;
        final lastDay = _parseDayKey(data['lastMeditationDay'] as String?);
        if (lastDay != null) {
          return lastDay == today;
        }
      }

      final startOfDay = today;
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.e('Error checking today\'s meditation', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get meditation calendar data for the last 30 days.
  Future<Map<DateTime, int>> getMeditationCalendar(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWindow = _dayOnly(now).subtract(const Duration(days: _calendarWindowDays));
      final endOfWindow = _dayOnly(now).add(const Duration(days: 1));

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWindow))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfWindow))
          .orderBy('startTime', descending: true)
          .limit(200)
          .get();

      final calendar = <DateTime, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startTime = data['startTime'];
        if (startTime is! Timestamp) continue;

        final day = _dayOnly(startTime.toDate());
        calendar[day] = (calendar[day] ?? 0) + 1;
      }

      return calendar;
    } catch (e, stackTrace) {
      appLogger.e('Error getting meditation calendar', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Update user's meditation statistics with O(1) streak maintenance.
  Future<void> updateStats(String userId, int durationMinutes) async {
    try {
      final statsRef = _userStatsDoc(userId);
      final today = _dayOnly(DateTime.now());
      final todayKey = _dayKey(today);
      final yesterdayKey = _dayKey(today.subtract(const Duration(days: 1)));

      await _firestore.runTransaction((txn) async {
        final snapshot = await txn.get(statsRef);
        final data = snapshot.exists ? snapshot.data() as Map<String, dynamic> : <String, dynamic>{};

        final totalSessions = (data['totalSessions'] as int?) ?? 0;
        final totalMinutes = (data['totalMinutes'] as int?) ?? 0;
        final currentStreak = (data['currentStreak'] as int?) ?? 0;
        final longestStreak = (data['longestStreak'] as int?) ?? 0;
        final lastDayKey = data['lastMeditationDay'] as String?;

        int nextStreak;
        if (lastDayKey == todayKey) {
          nextStreak = currentStreak > 0 ? currentStreak : 1;
        } else if (lastDayKey == yesterdayKey) {
          nextStreak = (currentStreak > 0 ? currentStreak : 1) + 1;
        } else {
          nextStreak = 1;
        }

        final nextLongest = nextStreak > longestStreak ? nextStreak : longestStreak;

        txn.set(
          statsRef,
          {
            'totalSessions': totalSessions + 1,
            'totalMinutes': totalMinutes + durationMinutes,
            'lastMeditationDate': FieldValue.serverTimestamp(),
            'lastMeditationDay': todayKey,
            'currentStreak': nextStreak,
            'longestStreak': nextLongest,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // Log completion for badge system after a full session.
      await _firestoreService.logActivityCompletion(userId, 'meditation');
    } catch (e, stackTrace) {
      appLogger.e('Error updating meditation stats', error: e, stackTrace: stackTrace);
    }
  }

  /// Get user's meditation statistics.
  Future<Map<String, dynamic>> getStats(String userId) async {
    try {
      final snapshot = await _userStatsDoc(userId).get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return {
          'totalSessions': (data['totalSessions'] as int?) ?? 0,
          'totalMinutes': (data['totalMinutes'] as int?) ?? 0,
          'currentStreak': (data['currentStreak'] as int?) ?? 0,
          'longestStreak': (data['longestStreak'] as int?) ?? 0,
          'lastMeditationDay': data['lastMeditationDay'],
          'lastMeditationDate': data['lastMeditationDate'],
        };
      }
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    } catch (e, stackTrace) {
      appLogger.e('Error getting meditation stats', error: e, stackTrace: stackTrace);
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }
  }
}
