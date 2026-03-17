import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../core/logger.dart';
import 'firestore_service.dart';
import 'routine_tracking_service.dart';
import 'meditation_analytics_service.dart';

class BadgeProgress {
  final double progressPercentage; // 0.0 to 1.0
  final int current;
  final int target;

  BadgeProgress({
    required this.progressPercentage,
    required this.current,
    required this.target,
  });
}

class BadgeService {
  final FirebaseFirestore _firestore;
  late final FirestoreService _firestoreService;
  late final RoutineTrackingService _routineService;
  late final MeditationAnalyticsService _meditationAnalytics;

  BadgeService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    RoutineTrackingService? routineService,
    MeditationAnalyticsService? meditationAnalytics,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _firestoreService = firestoreService ?? FirestoreService(firestore: _firestore);
    _routineService = routineService ?? RoutineTrackingService(firestore: _firestore);
    _meditationAnalytics = meditationAnalytics ?? MeditationAnalyticsService(firestore: _firestore);
  }

  /// Gets the IDs of all badges the user has already earned
  Future<Set<String>> getEarnedBadgeIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('badges')
          .doc(userId)
          .collection('earned')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      appLogger.e('Error getting earned badges', error: e);
      return {};
    }
  }

  /// Calculates the live progress for all locked badges
  Future<Map<String, BadgeProgress>> getAllBadgesProgress(String userId) async {
    final Map<String, BadgeProgress> progressMap = {};
    
    try {
      // 1. First Step (1 routine completed)
      final firstStepTarget = 1;
      final weekCompletions = await _routineService.getWeekCompletions(userId);
      final hasCompletedRoutine = weekCompletions.isNotEmpty;
      progressMap['first_step'] = BadgeProgress(
        progressPercentage: hasCompletedRoutine ? 1.0 : 0.0,
        current: hasCompletedRoutine ? 1 : 0,
        target: firstStepTarget,
      );

      // 2. Week Warrior (7-day streak)
      final streakTarget = 7;
      final streak = await _routineService.getCompletionStreak(userId);
      progressMap['week_warrior'] = BadgeProgress(
        progressPercentage: (streak / streakTarget).clamp(0.0, 1.0),
        current: streak,
        target: streakTarget,
      );

      // 3. Perfect Week (7 perfect days in a row)
      final perfectTarget = 7;
      int perfectDays = 0;
      if (weekCompletions.length >= 7) {
        perfectDays = weekCompletions.where((c) => c.completedActivities.length == c.totalActivities && c.totalActivities > 0).length;
      } else {
        perfectDays = weekCompletions.where((c) => c.completedActivities.length == c.totalActivities && c.totalActivities > 0).length;
      }
      progressMap['perfect_week'] = BadgeProgress(
        progressPercentage: (perfectDays / perfectTarget).clamp(0.0, 1.0),
        current: perfectDays,
        target: perfectTarget,
      );

      // 4. Meditation Master (10 meditations)
      final medTarget = 10;
      final medCount = await _firestoreService.getActivityCompletionCount(userId, 'meditation');
      progressMap['meditation_master'] = BadgeProgress(
        progressPercentage: (medCount / medTarget).clamp(0.0, 1.0),
        current: medCount,
        target: medTarget,
      );

      // 5. Journal Warrior (15 journals)
      final journalTarget = 15;
      final journalCount = await _firestoreService.getActivityCompletionCount(userId, 'journaling');
      progressMap['journal_warrior'] = BadgeProgress(
        progressPercentage: (journalCount / journalTarget).clamp(0.0, 1.0),
        current: journalCount,
        target: journalTarget,
      );

      // 6. Goal Crusher (3 goals achieved)
      final goalTarget = 3;
      final goalsCount = await _getCompletedGoalsCount(userId);
      progressMap['goal_crusher'] = BadgeProgress(
        progressPercentage: (goalsCount / goalTarget).clamp(0.0, 1.0),
        current: goalsCount,
        target: goalTarget,
      );

    } catch (e, stackTrace) {
      appLogger.e('Error calculating badge progress', error: e, stackTrace: stackTrace);
    }
    
    return progressMap;
  }

  /// Evaluates progress against thresholds and awards any newly earned badges.
  /// Returns a list of newly earned badges to be displayed by the UI.
  Future<List<Badge>> checkAndAwardBadges(String userId) async {
    try {
      final newBadges = <Badge>[];
      final earnedBadgeIds = await getEarnedBadgeIds(userId);
      final allProgress = await getAllBadgesProgress(userId);

      for (final badge in Badge.allBadges) {
        // Skip if already earned
        if (earnedBadgeIds.contains(badge.id)) continue;

        // Check if progress reached 100%
        final progress = allProgress[badge.id];
        if (progress != null && progress.progressPercentage >= 1.0) {
          await _awardBadge(userId, badge);
          newBadges.add(badge.copyWith(earnedDate: DateTime.now()));
        }
      }

      return newBadges;
    } catch (e, stackTrace) {
      appLogger.e('Error checking and awarding badges', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // ---- Private Helpers ----

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
      appLogger.e('Error writing awarded badge to Firestore', error: e, stackTrace: stackTrace);
    }
  }
}
