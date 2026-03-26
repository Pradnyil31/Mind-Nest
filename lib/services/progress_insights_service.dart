import '../models/routine_completion.dart';
import '../models/badge.dart';
import 'routine_tracking_service.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';

class ProgressInsightsService {
  final RoutineTrackingService _routineService;
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  ProgressInsightsService({
    RoutineTrackingService? routineService,
    FirestoreService? firestoreService,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _routineService = routineService ?? RoutineTrackingService(firestore: firestore ?? FirebaseFirestore.instance),
        _firestoreService = firestoreService ?? FirestoreService(firestore: firestore ?? FirebaseFirestore.instance);

  /// Get trend direction based on recent activity
  Future<String> getTrendDirection(String userId) async {
    try {
      final weekCompletions = await _routineService.getWeekCompletions(userId);
      
      if (weekCompletions.isEmpty) {
        return 'needs_attention';
      }

      // Calculate average activities per day
      final totalActivities = weekCompletions.fold<int>(
        0,
        (sum, completion) => sum + completion.completedActivities.length,
      );
      
      final avgPerDay = totalActivities / 7;

      // Determine trend
      if (avgPerDay >= 3) {
        return 'improving';
      } else if (avgPerDay >= 1.5) {
        return 'stable';
      } else {
        return 'needs_attention';
      }
    } catch (e, stackTrace) {
      appLogger.e('Error getting trend direction', error: e, stackTrace: stackTrace);
      return 'stable';
    }
  }

  /// Get weekly highlights (achievements)
  Future<List<String>> getWeeklyHighlights(String userId) async {
    try {
      final highlights = <String>[];
      
      // Get routine completions
      final weekCompletions = await _routineService.getWeekCompletions(userId);
      final totalActivities = weekCompletions.fold<int>(
        0,
        (sum, completion) => sum + completion.completedActivities.length,
      );
      
      if (totalActivities > 0) {
        highlights.add('🎯 Completed $totalActivities activities this week');
      }

      // Get meditation count
      final meditationCount = await _getMeditationCountThisWeek(userId);
      if (meditationCount > 0) {
        highlights.add('🧘 Meditated $meditationCount times');
      }

      // Get journal count
      final journalCount = await _getJournalCountThisWeek(userId);
      if (journalCount > 0) {
        highlights.add('📓 Journaled $journalCount times');
      }

      // Get streak
      final streak = await _routineService.getCompletionStreak(userId);
      if (streak > 0) {
        highlights.add('🔥 $streak-day streak active!');
      }

      return highlights;
    } catch (e, stackTrace) {
      appLogger.e('Error getting weekly highlights', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Generate encouraging message based on user's motive
  Future<String> generateEncouragingMessage(String userId, {String? userMotive}) async {
    try {
      final streak = await _routineService.getCompletionStreak(userId);
      final highlights = await getWeeklyHighlights(userId);

      // Use motive-aware messages where streak is high
      if (streak >= 7 && userMotive != null) {
        // Import MotiveConfig messages
        final streakMessages = {
          'Sleep': '🌙 $streak nights of better sleep habits!',
          'Stress': '💆 $streak days of stress management!',
          'Anxiety': '🌊 $streak days of building calm!',
          'Focus': '🎯 $streak days of mental clarity!',
          'Habit Building': '📈 $streak days of consistency!',
        };
        return streakMessages[userMotive] ?? '🌟 Amazing! $streak days in a row!';
      }
      else if (streak >= 7) {
        return '🌟 Amazing! $streak days in a row! You\'re building incredible habits!';
      } else if (streak >= 3) {
        return '💪 $streak days strong! Keep the momentum going!';
      } else if (highlights.length >= 3) {
        return '✨ You\'re doing great this week! Keep it up!';
      } else if (highlights.isNotEmpty) {
        return '📈 Every step counts! You\'re making progress!';
      } else {
        return '💚 Today is a new opportunity. Start small!';
      }
    } catch (e, stackTrace) {
      appLogger.e('Error generating message', error: e, stackTrace: stackTrace);
      return '✨ Keep going! Every day is progress!';
    }
  }

  /// Detect eligible badges
  Future<List<Badge>> detectNewBadges(String userId) async {
    try {
      final newBadges = <Badge>[];
      final earnedBadges = await _getEarnedBadgeIds(userId);

      // Check each badge
      for (final badge in Badge.allBadges) {
        if (!earnedBadges.contains(badge.id)) {
          final isEligible = await _checkBadgeEligibility(userId, badge.id);
          if (isEligible) {
            // Award the badge
            await _awardBadge(userId, badge);
            newBadges.add(badge.copyWith(earnedDate: DateTime.now()));
          }
        }
      }

      return newBadges;
    } catch (e, stackTrace) {
      appLogger.e('Error detecting badges', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Helper methods

  Future<int> _getMeditationCountThisWeek(String userId) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('meditation_sessions')
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getJournalCountThisWeek(String userId) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('journal_entries')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<String>> _getEarnedBadgeIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('badges')
          .doc(userId)
          .collection('earned')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> _checkBadgeEligibility(String userId, String badgeId) async {
    try {
      switch (badgeId) {
        case 'first_step':
          final completions = await _routineService.getWeekCompletions(userId);
          return completions.isNotEmpty;
        
        case 'week_warrior':
          final streak = await _routineService.getCompletionStreak(userId);
          return streak >= 7;
        
        case 'perfect_week':
          final weekCompletions = await _routineService.getWeekCompletions(userId);
          return weekCompletions.length >= 7 &&
              weekCompletions.every((c) => c.completedActivities.length == c.totalActivities);
        
        case 'meditation_master':
          // Fast single-document read using activity_stats (no full collection scan)
          final count = await _getActivityCompletionCount(userId, 'meditation');
          return count >= 10;
        
        case 'journal_warrior':
          // Fast single-document read using activity_stats (no full collection scan)
          final count = await _getActivityCompletionCount(userId, 'journaling');
          return count >= 15;
        
        case 'goal_crusher':
          final goalsCount = await _getCompletedGoalsCount(userId);
          return goalsCount >= 3;
        
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Fast single-document read from activity_stats — used by badge system.
  /// Much cheaper than full collection scans.
  Future<int> _getActivityCompletionCount(String userId, String activityKey) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activity_stats')
          .doc(activityKey)
          .get();
      if (doc.exists) {
        return (doc.data()?['completionCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getCompletedGoalsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('smart_goals')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _awardBadge(String userId, Badge badge) async {
    try {
      await _firestore
          .collection('badges')
          .doc(userId)
          .collection('earned')
          .doc(badge.id)
          .set(badge.copyWith(earnedDate: DateTime.now()).toMap());
    } catch (e, stackTrace) {
      appLogger.e('Error awarding badge', error: e, stackTrace: stackTrace);
    }
  }

  /// Get completion history for charting - Returns map of dates to completion percentages
  Future<Map<DateTime, double>> getCompletionHistory(String userId, int days) async {
    try {
      final history = <DateTime, double>{};
      final now = DateTime.now();
      
      // Get all completions for the date range in one query
      final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('routine_completions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      // Create a map for quick lookup
      final Map<String, RoutineCompletion> completionMap = {};
      for (var doc in snapshot.docs) {
         final completion = RoutineCompletion.fromMap(doc.data(), doc.id);
         final dateStr = "${completion.date.year}-${completion.date.month}-${completion.date.day}";
         completionMap[dateStr] = completion;
      }
      
      // Fill in all days (even zero ones)
      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dateStr = "${date.year}-${date.month}-${date.day}";
        
        double percentage = 0.0;
        if (completionMap.containsKey(dateStr)) {
           final completion = completionMap[dateStr]!;
           if (completion.totalActivities > 0) {
             percentage = (completion.completedActivities.length / completion.totalActivities) * 100;
             if (percentage > 100) percentage = 100; // Cap at 100%
           }
        }
        history[date] = percentage;
      }
      
      return history;
    } catch (e, stackTrace) {
      appLogger.e('Error getting completion history', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Get activity breakdown for the specified period
  Future<Map<String, int>> getActivityBreakdown(String userId, int days) async {
    try {
      final breakdown = <String, int>{};
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection('routine_completions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedActivities = List<String>.from(data['completedActivities'] ?? []);
        
        // Count each activity
        for (final activity in completedActivities) {
          if (activity.isNotEmpty) {
            breakdown[activity] = (breakdown[activity] ?? 0) + 1;
          }
        }
      }
      
      return breakdown;
    } catch (e, stackTrace) {
      appLogger.e('Error getting activity breakdown', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  Future<int> _getCompletionsForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await _firestore
        .collection('routine_completions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    
    // Count total completed activities across all documents for this day
    int totalCompletions = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final activities = List<String>.from(data['completedActivities'] ?? []);
      totalCompletions += activities.length;
    }
    
    return totalCompletions;
  }

  Future<int> _getTotalActivitiesForDate(String userId, DateTime date) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final routineActivities = List<String>.from(data['routineActivities'] ?? []);
      return routineActivities.isNotEmpty ? routineActivities.length : 5;
    }
    
    return 5;
  }
}
