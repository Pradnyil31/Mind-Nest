import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logger.dart';
import '../../../services/firestore_service.dart';
import '../../../config/motive_config.dart';
import 'mood_tracking_service.dart';

class CalmProgressService {
  final FirebaseFirestore? _providedFirestore;
  final FirestoreService? _providedFirestoreService;
  final MoodTrackingService? _providedMoodTrackingService;

  CalmProgressService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    MoodTrackingService? moodTrackingService,
  }) : _providedFirestore = firestore,
       _providedFirestoreService = firestoreService,
       _providedMoodTrackingService = moodTrackingService;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  late final FirestoreService _firestoreService =
      _providedFirestoreService ??
      FirestoreService(firestore: _providedFirestore);

  late final MoodTrackingService _moodTrackingService =
      _providedMoodTrackingService ??
      MoodTrackingService(firestore: _providedFirestore);

  CollectionReference get _sessionsCollection =>
      _firestore.collection('calm_sessions');

  /// Start a technique session with pre-mood rating
  /// Returns the mood session ID for later completion
  Future<String> startTechniqueSession({
    required String userId,
    required String techniqueId,
    required int preMoodRating,
  }) async {
    try {
      final moodSessionId = await _moodTrackingService.recordPreMood(
        userId,
        techniqueId,
        preMoodRating,
      );

      appLogger.i('Started technique session with pre-mood: $preMoodRating');
      return moodSessionId;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error starting technique session',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Complete a technique session with post-mood rating
  Future<void> completeTechniqueSession({
    required String userId,
    required String moodSessionId,
    required String techniqueId,
    required String techniqueName,
    required int durationMinutes,
    required int postMoodRating,
  }) async {
    try {
      // Record post-mood rating
      await _moodTrackingService.recordPostMood(moodSessionId, postMoodRating);

      // Get the specific mood session that was just completed
      final moodSessionDoc = await _firestore
          .collection('mood_sessions')
          .doc(moodSessionId)
          .get();

      if (moodSessionDoc.exists) {
        final sessionData = moodSessionDoc.data() as Map<String, dynamic>;
        final moodImprovement = sessionData['moodImprovement'] as int?;
        final preMoodRating = sessionData['preMoodRating'] as int?;

        // Log completion in calm_sessions collection for existing analytics
        await logTechniqueCompletion(
          userId: userId,
          techniqueId: techniqueId,
          techniqueName: techniqueName,
          durationMinutes: durationMinutes,
          preMoodRating: preMoodRating,
          postMoodRating: postMoodRating,
        );

        appLogger.i(
          'Completed technique session: $techniqueName (improvement: $moodImprovement)',
        );
      } else {
        // Fallback if session not found - log without mood data
        await logTechniqueCompletion(
          userId: userId,
          techniqueId: techniqueId,
          techniqueName: techniqueName,
          durationMinutes: durationMinutes,
          preMoodRating: null,
          postMoodRating: postMoodRating,
        );

        appLogger.w('Mood session not found: $moodSessionId');
      }

      // Check and award badges after completion
      await checkAndAwardBadges(userId);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error completing technique session',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Log completion of a calm technique
  Future<void> logTechniqueCompletion({
    required String userId,
    required String techniqueId,
    required String techniqueName,
    required int durationMinutes,
    int? preMoodRating,
    int? postMoodRating,
  }) async {
    // Online path — direct Firestore save
    try {
      final sessionData = {
        'userId': userId,
        'techniqueId': techniqueId,
        'techniqueName': techniqueName,
        'durationMinutes': durationMinutes,
        'completedAt': FieldValue.serverTimestamp(),
        'preMoodRating': preMoodRating,
        'postMoodRating': postMoodRating,
        'moodImprovement': (preMoodRating != null && postMoodRating != null)
            ? postMoodRating - preMoodRating
            : null,
      };

      await _sessionsCollection.add(sessionData);

      // Log for badge system
      await _firestoreService.logActivityCompletion(userId, 'calm_technique');

      appLogger.i('Calm technique completion logged: $techniqueName');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error logging calm technique completion',
        error: e,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  /// Get user's calm technique usage statistics with motive-specific insights
  /// Enhanced for task 3.3: comprehensive user statistics dashboard
  Future<Map<String, dynamic>> getUserStats(
    String userId, {
    String? userMotive,
  }) async {
    try {
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getEmptyStatsWithMotiveInsights(userId, userMotive);
      }

      final sessions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Calculate basic statistics
      final totalSessions = sessions.length;
      final totalMinutes = sessions.fold<int>(
        0,
        (total, session) => total + (session['durationMinutes'] as int? ?? 0),
      );

      // Get mood improvement from MoodTrackingService for more accurate data
      final averageMoodImprovement = await _moodTrackingService
          .getAverageMoodImprovement(userId);

      // Find favorite technique
      final techniqueCount = <String, int>{};
      for (final session in sessions) {
        final technique = session['techniqueName'] as String?;
        if (technique != null) {
          techniqueCount[technique] = (techniqueCount[technique] ?? 0) + 1;
        }
      }

      final favoriteTechnique = techniqueCount.isNotEmpty
          ? techniqueCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : null;

      // Calculate current streak with motive-appropriate messaging
      final currentStreak = await _calculateCurrentStreak(userId);
      final streakMessage = _getMotiveSpecificStreakMessage(
        userMotive,
        currentStreak,
      );

      // Get detailed mood trends
      final moodTrends = await _moodTrackingService.getMoodTrends(userId);

      // Generate advanced analytics
      final advancedAnalytics = await _generateAdvancedAnalytics(
        userId,
        sessions,
      );

      // Generate motive-specific insights
      final motiveInsights = await _generateMotiveSpecificInsights(
        userId,
        userMotive,
        sessions,
        currentStreak,
        averageMoodImprovement,
      );

      // Create technique usage pattern analysis
      final usagePatterns = await _analyzeUsagePatterns(sessions, userMotive);

      // Generate weekly and monthly statistics (Requirements 6.2)
      final weeklyStats = await _calculateWeeklyStats(sessions);
      final monthlyStats = await _calculateMonthlyStats(sessions);

      return {
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'averageMoodImprovement': averageMoodImprovement,
        'favoriteTechnique': favoriteTechnique,
        'currentStreak': currentStreak,
        'streakMessage': streakMessage,
        'moodTrends': moodTrends,
        'advancedAnalytics': advancedAnalytics,
        'motiveInsights': motiveInsights,
        'usagePatterns': usagePatterns,
        'weeklyStats': weeklyStats,
        'monthlyStats': monthlyStats,
        'userMotive': userMotive,
        'motiveProfile': MotiveConfig.getProfile(userMotive),
      };
    } catch (e, stackTrace) {
      appLogger.e('Error getting calm stats', error: e, stackTrace: stackTrace);
      return _getEmptyStatsWithMotiveInsights(userId, userMotive);
    }
  }

  /// Get empty stats structure with motive insights for new users
  Future<Map<String, dynamic>> _getEmptyStatsWithMotiveInsights(
    String userId,
    String? userMotive,
  ) async {
    final motiveProfile = MotiveConfig.getProfile(userMotive);
    final streakMessage = _getMotiveSpecificStreakMessage(userMotive, 0);

    return {
      'totalSessions': 0,
      'totalMinutes': 0,
      'averageMoodImprovement': 0.0,
      'favoriteTechnique': null,
      'currentStreak': 0,
      'streakMessage': streakMessage,
      'moodTrends': await _moodTrackingService.getMoodTrends(userId),
      'advancedAnalytics': {
        'weeklyProgress': <Map<String, dynamic>>[],
        'monthlyTrends': <Map<String, dynamic>>[],
        'techniqueComparison': <Map<String, dynamic>>[],
      },
      'motiveInsights': {
        'welcomeMessage': _getMotiveWelcomeMessage(userMotive),
        'recommendedTechniques': MotiveConfig.getCalmTechniquePriorities(
          userMotive,
        ),
        'motivationalMessage': _getMotivationalMessage(userMotive),
        'nextSteps': _getNextStepsForNewUser(userMotive),
      },
      'usagePatterns': {
        'preferredTimes': <String>[],
        'techniqueDistribution': <Map<String, dynamic>>[],
        'effectivenessRanking': <Map<String, dynamic>>[],
        'motiveAlignment': 0.0,
      },
      'weeklyStats': <Map<String, dynamic>>[],
      'monthlyStats': <Map<String, dynamic>>[],
      'userMotive': userMotive,
      'motiveProfile': motiveProfile,
    };
  }

  /// Generate motive-specific insights for user dashboard
  Future<Map<String, dynamic>> _generateMotiveSpecificInsights(
    String userId,
    String? userMotive,
    List<Map<String, dynamic>> sessions,
    int currentStreak,
    double averageMoodImprovement,
  ) async {
    try {
      final motiveProfile = MotiveConfig.getProfile(userMotive);
      final insights = <String>[];
      final achievements = <Map<String, dynamic>>[];

      // Welcome message using MotiveConfig.getInsightMessage() patterns (Requirement 20.1)
      final welcomeMessage = _getMotiveWelcomeMessage(userMotive);

      // Streak insights with motive-appropriate messaging (Requirement 20.2)
      if (currentStreak > 0) {
        final streakMessage = MotiveConfig.getInsightMessage(
          userMotive,
          'streak',
          count: currentStreak,
        );
        insights.add(streakMessage);
      }

      // Technique effectiveness insights
      final effectiveness = await _moodTrackingService
          .getTechniqueEffectiveness(userId);
      if (effectiveness.isNotEmpty) {
        final bestTechnique = effectiveness.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );

        if (bestTechnique.value > 2.0) {
          insights.add(
            '🌟 ${bestTechnique.key} is your most effective technique with an average improvement of ${bestTechnique.value.toStringAsFixed(1)} points!',
          );
        }
      }

      // Motive-specific progress insights
      if (averageMoodImprovement > 1.5) {
        final encouragementMessage = MotiveConfig.getInsightMessage(
          userMotive,
          'encouragement',
        );
        insights.add(encouragementMessage);
      }

      // Generate motive-specific achievements
      achievements.addAll(
        await _generateMotiveAchievements(
          userMotive,
          sessions.length,
          currentStreak,
          averageMoodImprovement,
        ),
      );

      return {
        'welcomeMessage': welcomeMessage,
        'insights': insights,
        'achievements': achievements,
        'motiveEmoji': motiveProfile?.emoji ?? '🌱',
        'motiveDisplayName': motiveProfile?.displayName ?? 'Wellness',
        'recommendedTechniques': MotiveConfig.getCalmTechniquePriorities(
          userMotive,
        ),
        'motivationalMessage': _getMotivationalMessage(userMotive),
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error generating motive-specific insights',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'welcomeMessage': 'Welcome to your calm practice! 🌱',
        'insights': <String>[],
        'achievements': <Map<String, dynamic>>[],
        'motiveEmoji': '🌱',
        'motiveDisplayName': 'Wellness',
        'recommendedTechniques': ['Breathing', 'Meditation'],
        'motivationalMessage': 'Keep up the great work!',
      };
    }
  }

  /// Get motive-specific welcome message using MotiveConfig patterns
  String _getMotiveWelcomeMessage(String? userMotive) {
    final motiveProfile = MotiveConfig.getProfile(userMotive);
    if (motiveProfile != null) {
      return '${motiveProfile.emoji} Welcome to your ${motiveProfile.displayName} journey!';
    }
    return '🌱 Welcome to your wellness journey!';
  }

  /// Get motive-specific streak message with appropriate messaging
  String _getMotiveSpecificStreakMessage(String? userMotive, int streak) {
    if (streak == 0) {
      final motiveProfile = MotiveConfig.getProfile(userMotive);
      if (motiveProfile != null) {
        return '${motiveProfile.emoji} Ready to start your ${motiveProfile.displayName.toLowerCase()} streak?';
      }
      return '🌱 Ready to start your wellness streak?';
    }

    return MotiveConfig.getInsightMessage(userMotive, 'streak', count: streak);
  }

  /// Get motivational message based on user's motive
  String _getMotivationalMessage(String? userMotive) {
    final motiveProfile = MotiveConfig.getProfile(userMotive);
    if (motiveProfile != null) {
      switch (userMotive) {
        case 'Sleep':
          return 'Quality rest leads to quality days! 🌙';
        case 'Stress':
          return 'Every breath brings you closer to calm! 🧘';
        case 'Anxiety':
          return 'You are stronger than your worries! 💜';
        case 'Focus':
          return 'Clarity comes with consistent practice! 🎯';
        case 'Habit Building':
          return 'Small steps create big changes! 🔥';
        default:
          return 'Your wellness journey is unique and valuable! 🌱';
      }
    }
    return 'Your wellness journey is unique and valuable! 🌱';
  }

  /// Generate motive-specific achievements
  Future<List<Map<String, dynamic>>> _generateMotiveAchievements(
    String? userMotive,
    int totalSessions,
    int currentStreak,
    double averageMoodImprovement,
  ) async {
    final achievements = <Map<String, dynamic>>[];
    final motiveProfile = MotiveConfig.getProfile(userMotive);
    final emoji = motiveProfile?.emoji ?? '🌱';

    // Session milestones with motive-specific messaging
    if (totalSessions >= 10 && totalSessions < 15) {
      achievements.add({
        'title': 'Getting Started',
        'description':
            '10 ${motiveProfile?.displayName.toLowerCase() ?? 'wellness'} sessions completed',
        'icon': emoji,
        'type': 'session_milestone',
      });
    } else if (totalSessions >= 25 && totalSessions < 30) {
      achievements.add({
        'title': 'Building Momentum',
        'description':
            '25 ${motiveProfile?.displayName.toLowerCase() ?? 'wellness'} sessions completed',
        'icon': emoji,
        'type': 'session_milestone',
      });
    } else if (totalSessions >= 50 && totalSessions < 55) {
      achievements.add({
        'title': 'Dedicated Practitioner',
        'description':
            '50 ${motiveProfile?.displayName.toLowerCase() ?? 'wellness'} sessions completed',
        'icon': emoji,
        'type': 'session_milestone',
      });
    }

    // Streak milestones with motive-specific celebration messages (Requirement 20.2)
    if (currentStreak == 7) {
      final message = MotiveConfig.getInsightMessage(userMotive, 'milestone');
      achievements.add({
        'title': 'Week Warrior',
        'description': message,
        'icon': '🔥',
        'type': 'streak_milestone',
      });
    } else if (currentStreak == 30) {
      final message = MotiveConfig.getInsightMessage(userMotive, 'milestone');
      achievements.add({
        'title': 'Monthly Master',
        'description': message,
        'icon': '🏆',
        'type': 'streak_milestone',
      });
    }

    // Effectiveness achievements
    if (averageMoodImprovement >= 3.0) {
      achievements.add({
        'title': 'Mood Master',
        'description': 'Achieving excellent mood improvements!',
        'icon': '✨',
        'type': 'effectiveness_milestone',
      });
    }

    return achievements;
  }

  /// Analyze technique usage patterns with motive alignment
  Future<Map<String, dynamic>> _analyzeUsagePatterns(
    List<Map<String, dynamic>> sessions,
    String? userMotive,
  ) async {
    try {
      // Analyze preferred times of day
      final timePatterns = _analyzeTimePatterns(sessions);

      // Analyze technique distribution
      final techniqueDistribution = _analyzeTechniqueDistribution(sessions);

      // Rank techniques by effectiveness
      final effectivenessRanking = await _rankTechniquesByEffectiveness(
        sessions,
      );

      // Calculate motive alignment score
      final motiveAlignment = _calculateMotiveAlignment(sessions, userMotive);

      return {
        'preferredTimes': timePatterns,
        'techniqueDistribution': techniqueDistribution,
        'effectivenessRanking': effectivenessRanking,
        'motiveAlignment': motiveAlignment,
        'totalSessions': sessions.length,
        'analysisDate': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error analyzing usage patterns',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'preferredTimes': <String>[],
        'techniqueDistribution': <Map<String, dynamic>>[],
        'effectivenessRanking': <Map<String, dynamic>>[],
        'motiveAlignment': 0.0,
        'totalSessions': 0,
        'analysisDate': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Analyze time patterns for technique usage
  List<String> _analyzeTimePatterns(List<Map<String, dynamic>> sessions) {
    final timeSlots = <String, int>{
      'Morning (6-12)': 0,
      'Afternoon (12-18)': 0,
      'Evening (18-24)': 0,
      'Night (0-6)': 0,
    };

    for (final session in sessions) {
      final completedAt = (session['completedAt'] as Timestamp).toDate();
      final hour = completedAt.hour;

      if (hour >= 6 && hour < 12) {
        timeSlots['Morning (6-12)'] = timeSlots['Morning (6-12)']! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeSlots['Afternoon (12-18)'] = timeSlots['Afternoon (12-18)']! + 1;
      } else if (hour >= 18 && hour < 24) {
        timeSlots['Evening (18-24)'] = timeSlots['Evening (18-24)']! + 1;
      } else {
        timeSlots['Night (0-6)'] = timeSlots['Night (0-6)']! + 1;
      }
    }

    // Return time slots sorted by usage frequency
    final sortedSlots = timeSlots.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSlots.map((e) => e.key).toList();
  }

  /// Analyze technique distribution and usage frequency
  List<Map<String, dynamic>> _analyzeTechniqueDistribution(
    List<Map<String, dynamic>> sessions,
  ) {
    final techniqueCount = <String, int>{};
    final techniqueMinutes = <String, int>{};

    for (final session in sessions) {
      final technique = session['techniqueName'] as String?;
      final minutes = session['durationMinutes'] as int? ?? 0;

      if (technique != null) {
        techniqueCount[technique] = (techniqueCount[technique] ?? 0) + 1;
        techniqueMinutes[technique] =
            (techniqueMinutes[technique] ?? 0) + minutes;
      }
    }

    return techniqueCount.entries
        .map(
          (entry) => {
            'technique': entry.key,
            'sessionCount': entry.value,
            'totalMinutes': techniqueMinutes[entry.key] ?? 0,
            'percentage': sessions.isNotEmpty
                ? (entry.value / sessions.length * 100).round()
                : 0,
            'averageMinutes': entry.value > 0
                ? ((techniqueMinutes[entry.key] ?? 0) / entry.value).round()
                : 0,
          },
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['sessionCount'] as int).compareTo(a['sessionCount'] as int),
      );
  }

  /// Rank techniques by effectiveness (mood improvement)
  Future<List<Map<String, dynamic>>> _rankTechniquesByEffectiveness(
    List<Map<String, dynamic>> sessions,
  ) async {
    final techniqueImprovements = <String, List<int>>{};

    for (final session in sessions) {
      final technique = session['techniqueName'] as String?;
      final improvement = session['moodImprovement'] as int?;

      if (technique != null && improvement != null) {
        techniqueImprovements[technique] ??= [];
        techniqueImprovements[technique]!.add(improvement);
      }
    }

    final effectivenessRanking =
        techniqueImprovements.entries.map((entry) {
          final improvements = entry.value;
          final averageImprovement = improvements.isNotEmpty
              ? improvements.reduce((a, b) => a + b) / improvements.length
              : 0.0;

          return {
            'technique': entry.key,
            'averageImprovement': averageImprovement,
            'sessionCount': improvements.length,
            'totalImprovement': improvements.fold<int>(
              0,
              (acc, val) => acc + val,
            ),
            'effectivenessScore':
                averageImprovement * improvements.length, // Weight by usage
          };
        }).toList()..sort(
          (a, b) => (b['effectivenessScore'] as double).compareTo(
            a['effectivenessScore'] as double,
          ),
        );

    return effectivenessRanking;
  }

  /// Calculate how well user's technique usage aligns with their motive
  double _calculateMotiveAlignment(
    List<Map<String, dynamic>> sessions,
    String? userMotive,
  ) {
    if (userMotive == null || sessions.isEmpty) return 0.0;

    final prioritizedTechniques = MotiveConfig.getCalmTechniquePriorities(
      userMotive,
    );
    if (prioritizedTechniques.isEmpty) return 0.0;

    int alignedSessions = 0;
    for (final session in sessions) {
      final technique = session['techniqueName'] as String?;
      if (technique != null && prioritizedTechniques.contains(technique)) {
        alignedSessions++;
      }
    }

    return (alignedSessions / sessions.length * 100).clamp(0.0, 100.0);
  }

  /// Calculate weekly statistics (Requirement 6.2)
  Future<List<Map<String, dynamic>>> _calculateWeeklyStats(
    List<Map<String, dynamic>> sessions,
  ) async {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int week = 0; week < 4; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      final weekSessions = sessions.where((session) {
        final completedAt = (session['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(weekStart) && completedAt.isBefore(weekEnd);
      }).toList();

      final sessionCount = weekSessions.length;
      final totalMinutes = weekSessions.fold<int>(
        0,
        (total, session) => total + (session['durationMinutes'] as int? ?? 0),
      );

      final moodImprovements = weekSessions
          .where((s) => s['moodImprovement'] != null)
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final avgMoodImprovement = moodImprovements.isNotEmpty
          ? moodImprovements.reduce((a, b) => a + b) / moodImprovements.length
          : 0.0;

      weeklyData.add({
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
        'sessionCount': sessionCount,
        'totalMinutes': totalMinutes,
        'averageMoodImprovement': avgMoodImprovement,
        'weekNumber': week + 1,
        'weekLabel': 'Week ${week + 1}',
      });
    }

    return weeklyData.reversed.toList();
  }

  /// Calculate monthly statistics (Requirement 6.2)
  Future<List<Map<String, dynamic>>> _calculateMonthlyStats(
    List<Map<String, dynamic>> sessions,
  ) async {
    final monthlyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int month = 0; month < 6; month++) {
      final monthStart = DateTime(now.year, now.month - month, 1);
      final monthEnd = DateTime(now.year, now.month - month + 1, 1);

      final monthSessions = sessions.where((session) {
        final completedAt = (session['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(monthStart) &&
            completedAt.isBefore(monthEnd);
      }).toList();

      final sessionCount = monthSessions.length;
      final totalMinutes = monthSessions.fold<int>(
        0,
        (total, session) => total + (session['durationMinutes'] as int? ?? 0),
      );

      final moodImprovements = monthSessions
          .where((s) => s['moodImprovement'] != null)
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final avgMoodImprovement = moodImprovements.isNotEmpty
          ? moodImprovements.reduce((a, b) => a + b) / moodImprovements.length
          : 0.0;

      monthlyData.add({
        'month': monthStart.month,
        'year': monthStart.year,
        'monthName': _getMonthName(monthStart.month),
        'sessionCount': sessionCount,
        'totalMinutes': totalMinutes,
        'averageMoodImprovement': avgMoodImprovement,
        'monthLabel': '${_getMonthName(monthStart.month)} ${monthStart.year}',
      });
    }

    return monthlyData.reversed.toList();
  }

  /// Get next steps recommendations for new users
  List<String> _getNextStepsForNewUser(String? userMotive) {
    final prioritizedTechniques = MotiveConfig.getCalmTechniquePriorities(
      userMotive,
    );
    final motiveProfile = MotiveConfig.getProfile(userMotive);

    final nextSteps = <String>[];

    if (prioritizedTechniques.isNotEmpty) {
      nextSteps.add('Try your first ${prioritizedTechniques.first} technique');
    }

    if (motiveProfile != null) {
      nextSteps.add(
        'Explore ${motiveProfile.displayName.toLowerCase()} focused activities',
      );
      nextSteps.add('Set a daily practice reminder');
    }

    nextSteps.add('Track your mood before and after sessions');

    return nextSteps;
  }

  /// Generate advanced analytics for user stats
  Future<Map<String, dynamic>> _generateAdvancedAnalytics(
    String userId,
    List<Map<String, dynamic>> sessions,
  ) async {
    try {
      // Weekly progress (last 4 weeks)
      final weeklyProgress = await _calculateWeeklyProgress(sessions);

      // Monthly trends (last 6 months)
      final monthlyTrends = await _calculateMonthlyTrends(sessions);

      // Technique comparison with effectiveness scores
      final techniqueComparison = await _calculateTechniqueComparison(
        userId,
        sessions,
      );

      return {
        'weeklyProgress': weeklyProgress,
        'monthlyTrends': monthlyTrends,
        'techniqueComparison': techniqueComparison,
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error generating advanced analytics',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'weeklyProgress': <Map<String, dynamic>>[],
        'monthlyTrends': <Map<String, dynamic>>[],
        'techniqueComparison': <Map<String, dynamic>>[],
      };
    }
  }

  /// Calculate weekly progress for the last 4 weeks
  Future<List<Map<String, dynamic>>> _calculateWeeklyProgress(
    List<Map<String, dynamic>> sessions,
  ) async {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int week = 0; week < 4; week++) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));

      final weekSessions = sessions.where((session) {
        final completedAt = (session['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(weekStart) && completedAt.isBefore(weekEnd);
      }).toList();

      final sessionCount = weekSessions.length;
      final totalMinutes = weekSessions.fold<int>(
        0,
        (total, session) => total + (session['durationMinutes'] as int? ?? 0),
      );

      final moodImprovements = weekSessions
          .where((s) => s['moodImprovement'] != null)
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final avgMoodImprovement = moodImprovements.isNotEmpty
          ? moodImprovements.reduce((a, b) => a + b) / moodImprovements.length
          : 0.0;

      weeklyData.add({
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
        'sessionCount': sessionCount,
        'totalMinutes': totalMinutes,
        'averageMoodImprovement': avgMoodImprovement,
        'weekNumber': week + 1,
      });
    }

    return weeklyData.reversed.toList();
  }

  /// Calculate monthly trends for the last 6 months
  Future<List<Map<String, dynamic>>> _calculateMonthlyTrends(
    List<Map<String, dynamic>> sessions,
  ) async {
    final monthlyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int month = 0; month < 6; month++) {
      final monthStart = DateTime(now.year, now.month - month, 1);
      final monthEnd = DateTime(now.year, now.month - month + 1, 1);

      final monthSessions = sessions.where((session) {
        final completedAt = (session['completedAt'] as Timestamp).toDate();
        return completedAt.isAfter(monthStart) &&
            completedAt.isBefore(monthEnd);
      }).toList();

      final sessionCount = monthSessions.length;
      final totalMinutes = monthSessions.fold<int>(
        0,
        (total, session) => total + (session['durationMinutes'] as int? ?? 0),
      );

      final moodImprovements = monthSessions
          .where((s) => s['moodImprovement'] != null)
          .map((s) => s['moodImprovement'] as int)
          .toList();

      final avgMoodImprovement = moodImprovements.isNotEmpty
          ? moodImprovements.reduce((a, b) => a + b) / moodImprovements.length
          : 0.0;

      monthlyData.add({
        'month': monthStart.month,
        'year': monthStart.year,
        'monthName': _getMonthName(monthStart.month),
        'sessionCount': sessionCount,
        'totalMinutes': totalMinutes,
        'averageMoodImprovement': avgMoodImprovement,
      });
    }

    return monthlyData.reversed.toList();
  }

  /// Calculate technique comparison with effectiveness and usage
  Future<List<Map<String, dynamic>>> _calculateTechniqueComparison(
    String userId,
    List<Map<String, dynamic>> sessions,
  ) async {
    final techniqueData = <String, Map<String, dynamic>>{};
    final effectiveness = await _moodTrackingService.getTechniqueEffectiveness(
      userId,
    );

    // Group sessions by technique
    for (final session in sessions) {
      final technique = session['techniqueName'] as String?;
      if (technique != null) {
        techniqueData[technique] ??= {
          'name': technique,
          'sessionCount': 0,
          'totalMinutes': 0,
          'moodImprovements': <int>[],
        };

        techniqueData[technique]!['sessionCount'] =
            (techniqueData[technique]!['sessionCount'] as int) + 1;
        techniqueData[technique]!['totalMinutes'] =
            (techniqueData[technique]!['totalMinutes'] as int) +
            (session['durationMinutes'] as int? ?? 0);

        final moodImprovement = session['moodImprovement'] as int?;
        if (moodImprovement != null) {
          (techniqueData[technique]!['moodImprovements'] as List<int>).add(
            moodImprovement,
          );
        }
      }
    }

    // Calculate comparison metrics
    final comparisonData = techniqueData.entries.map((entry) {
      final technique = entry.key;
      final data = entry.value;
      final improvements = data['moodImprovements'] as List<int>;

      final avgImprovement = improvements.isNotEmpty
          ? improvements.reduce((a, b) => a + b) / improvements.length
          : 0.0;

      final effectivenessScore = effectiveness[technique] ?? 0.0;

      return {
        'technique': technique,
        'sessionCount': data['sessionCount'],
        'totalMinutes': data['totalMinutes'],
        'averageImprovement': avgImprovement,
        'effectivenessScore': effectivenessScore,
        'usagePercentage':
            (data['sessionCount'] as int) / sessions.length * 100,
      };
    }).toList();

    // Sort by effectiveness score
    comparisonData.sort(
      (a, b) => (b['effectivenessScore'] as double).compareTo(
        a['effectivenessScore'] as double,
      ),
    );

    return comparisonData;
  }

  /// Get month name from month number
  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month];
  }

  /// Calculate current streak of calm technique usage
  Future<int> _calculateCurrentStreak(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int streak = 0;

      // Check each day going backwards
      for (int i = 0; i < 365; i++) {
        // Max 365 days to prevent infinite loop
        final checkDate = today.subtract(Duration(days: i));
        final nextDay = checkDate.add(const Duration(days: 1));

        final daySnapshot = await _sessionsCollection
            .where('userId', isEqualTo: userId)
            .where(
              'completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(checkDate),
            )
            .where('completedAt', isLessThan: Timestamp.fromDate(nextDay))
            .limit(1)
            .get();

        if (daySnapshot.docs.isNotEmpty) {
          streak++;
        } else {
          // If this is day 0 (today) and no session, streak is 0
          // If this is any other day, we've found the end of the streak
          break;
        }
      }

      return streak;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error calculating calm streak',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Get technique effectiveness data for recommendations with advanced analytics
  Future<Map<String, double>> getTechniqueEffectiveness(String userId) async {
    try {
      // Use MoodTrackingService for more accurate effectiveness data
      return await _moodTrackingService.getTechniqueEffectiveness(userId);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting technique effectiveness',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get advanced technique effectiveness with cross-motive tracking
  /// Returns effectiveness scores, confidence levels, and cross-motive comparisons
  Future<Map<String, dynamic>> getAdvancedTechniqueEffectiveness(
    String userId,
    String? currentMotive,
  ) async {
    try {
      // Get basic effectiveness data
      final basicEffectiveness = await _moodTrackingService
          .getTechniqueEffectiveness(userId);

      // Get all user sessions for detailed analysis
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('moodImprovement', isNotEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'effectiveness': <String, double>{},
          'confidence': <String, double>{},
          'sessionCounts': <String, int>{},
          'crossMotiveComparison': <String, Map<String, double>>{},
          'trendAnalysis': <String, Map<String, dynamic>>{},
        };
      }

      final sessions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Calculate confidence levels based on session count
      final sessionCounts = <String, int>{};
      final confidenceLevels = <String, double>{};

      for (final session in sessions) {
        final techniqueName = session['techniqueName'] as String?;
        if (techniqueName != null) {
          sessionCounts[techniqueName] =
              (sessionCounts[techniqueName] ?? 0) + 1;
        }
      }

      // Calculate confidence: more sessions = higher confidence
      sessionCounts.forEach((technique, cnt) {
        // Confidence ranges from 0.1 (1 session) to 1.0 (10+ sessions)
        confidenceLevels[technique] = (cnt / 10.0).clamp(0.1, 1.0);
      });

      // Cross-motive effectiveness comparison
      final crossMotiveComparison = await _calculateCrossMotiveEffectiveness(
        userId,
        sessions,
      );

      // Trend analysis for each technique
      final trendAnalysis = await _calculateTechniqueTrends(sessions);

      return {
        'effectiveness': basicEffectiveness,
        'confidence': confidenceLevels,
        'sessionCounts': sessionCounts,
        'crossMotiveComparison': crossMotiveComparison,
        'trendAnalysis': trendAnalysis,
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting advanced technique effectiveness',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'effectiveness': <String, double>{},
        'confidence': <String, double>{},
        'sessionCounts': <String, int>{},
        'crossMotiveComparison': <String, Map<String, double>>{},
        'trendAnalysis': <String, Map<String, dynamic>>{},
      };
    }
  }

  /// Calculate cross-motive effectiveness comparison
  Future<Map<String, Map<String, double>>> _calculateCrossMotiveEffectiveness(
    String userId,
    List<Map<String, dynamic>> sessions,
  ) async {
    try {
      final crossMotiveData = <String, Map<String, double>>{};

      // Group sessions by technique and motive
      final techniqueMotiveGroups = <String, Map<String, List<int>>>{};

      for (final session in sessions) {
        final techniqueName = session['techniqueName'] as String?;
        final motive = session['motive'] as String?;
        final improvement = session['moodImprovement'] as int?;

        if (techniqueName != null && improvement != null) {
          techniqueMotiveGroups[techniqueName] ??= {};
          final motiveKey = motive ?? 'unknown';
          techniqueMotiveGroups[techniqueName]![motiveKey] ??= [];
          techniqueMotiveGroups[techniqueName]![motiveKey]!.add(improvement);
        }
      }

      // Calculate average effectiveness per motive for each technique
      techniqueMotiveGroups.forEach((technique, motiveGroups) {
        crossMotiveData[technique] = {};
        motiveGroups.forEach((motive, improvements) {
          final average =
              improvements.reduce((a, b) => a + b) / improvements.length;
          crossMotiveData[technique]![motive] = average;
        });
      });

      return crossMotiveData;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error calculating cross-motive effectiveness',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Calculate technique trend analysis over time
  Future<Map<String, Map<String, dynamic>>> _calculateTechniqueTrends(
    List<Map<String, dynamic>> sessions,
  ) async {
    try {
      final trendData = <String, Map<String, dynamic>>{};

      // Group sessions by technique and sort by date
      final techniqueGroups = <String, List<Map<String, dynamic>>>{};

      for (final session in sessions) {
        final techniqueName = session['techniqueName'] as String?;
        if (techniqueName != null) {
          techniqueGroups[techniqueName] ??= [];
          techniqueGroups[techniqueName]!.add(session);
        }
      }

      // Calculate trends for each technique
      techniqueGroups.forEach((technique, techniqueSessions) {
        // Sort by completion date
        techniqueSessions.sort((a, b) {
          final aTime = (a['completedAt'] as Timestamp).toDate();
          final bTime = (b['completedAt'] as Timestamp).toDate();
          return aTime.compareTo(bTime);
        });

        // Calculate trend metrics
        final improvements = techniqueSessions
            .map((s) => s['moodImprovement'] as int)
            .toList();

        if (improvements.length >= 3) {
          // Calculate trend direction (improving, stable, declining)
          final firstHalf = improvements
              .take(improvements.length ~/ 2)
              .toList();
          final secondHalf = improvements
              .skip(improvements.length ~/ 2)
              .toList();

          final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
          final secondAvg =
              secondHalf.reduce((a, b) => a + b) / secondHalf.length;

          final trendDirection = secondAvg - firstAvg;
          String trendLabel;
          if (trendDirection > 0.5) {
            trendLabel = 'improving';
          } else if (trendDirection < -0.5) {
            trendLabel = 'declining';
          } else {
            trendLabel = 'stable';
          }

          trendData[technique] = {
            'direction': trendLabel,
            'change': trendDirection,
            'recentAverage': secondAvg,
            'overallAverage':
                improvements.reduce((a, b) => a + b) / improvements.length,
            'sessionCount': improvements.length,
            'lastUsed': (techniqueSessions.last['completedAt'] as Timestamp)
                .toDate()
                .toIso8601String(),
          };
        }
      });

      return trendData;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error calculating technique trends',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get visual progress chart data for the last 30 days
  Future<Map<String, dynamic>> getProgressChartData(
    String userId, {
    int days = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('completedAt')
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'dailyActivity': <Map<String, dynamic>>[],
          'moodTrends': <Map<String, dynamic>>[],
          'techniqueUsage': <Map<String, dynamic>>[],
          'streakData': <Map<String, dynamic>>[],
        };
      }

      final sessions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Daily activity chart data
      final dailyActivity = _generateDailyActivityChart(sessions, days);

      // Mood trends chart data
      final moodTrends = _generateMoodTrendsChart(sessions);

      // Technique usage distribution
      final techniqueUsage = _generateTechniqueUsageChart(sessions);

      // Streak visualization data
      final streakData = await _generateStreakChart(userId, days);

      return {
        'dailyActivity': dailyActivity,
        'moodTrends': moodTrends,
        'techniqueUsage': techniqueUsage,
        'streakData': streakData,
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting progress chart data',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'dailyActivity': <Map<String, dynamic>>[],
        'moodTrends': <Map<String, dynamic>>[],
        'techniqueUsage': <Map<String, dynamic>>[],
        'streakData': <Map<String, dynamic>>[],
      };
    }
  }

  /// Generate daily activity chart data
  List<Map<String, dynamic>> _generateDailyActivityChart(
    List<Map<String, dynamic>> sessions,
    int days,
  ) {
    final dailyData = <String, Map<String, dynamic>>{};
    final now = DateTime.now();

    // Initialize all days with zero values
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyData[dateKey] = {
        'date': dateKey,
        'sessionCount': 0,
        'totalMinutes': 0,
        'averageMoodImprovement': 0.0,
      };
    }

    // Populate with actual session data
    for (final session in sessions) {
      final completedAt = (session['completedAt'] as Timestamp).toDate();
      final dateKey =
          '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';

      if (dailyData.containsKey(dateKey)) {
        dailyData[dateKey]!['sessionCount'] =
            (dailyData[dateKey]!['sessionCount'] as int) + 1;
        dailyData[dateKey]!['totalMinutes'] =
            (dailyData[dateKey]!['totalMinutes'] as int) +
            (session['durationMinutes'] as int? ?? 0);

        final moodImprovement = session['moodImprovement'] as int?;
        if (moodImprovement != null) {
          final currentAvg =
              dailyData[dateKey]!['averageMoodImprovement'] as double;
          final sessionCount = dailyData[dateKey]!['sessionCount'] as int;
          dailyData[dateKey]!['averageMoodImprovement'] =
              ((currentAvg * (sessionCount - 1)) + moodImprovement) /
              sessionCount;
        }
      }
    }

    return dailyData.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Generate mood trends chart data
  List<Map<String, dynamic>> _generateMoodTrendsChart(
    List<Map<String, dynamic>> sessions,
  ) {
    final moodData = <Map<String, dynamic>>[];

    for (final session in sessions) {
      final completedAt = (session['completedAt'] as Timestamp).toDate();
      final preMood = session['preMoodRating'] as int?;
      final postMood = session['postMoodRating'] as int?;
      final improvement = session['moodImprovement'] as int?;

      if (preMood != null && postMood != null && improvement != null) {
        moodData.add({
          'date': completedAt.toIso8601String(),
          'preMood': preMood,
          'postMood': postMood,
          'improvement': improvement,
          'technique': session['techniqueName'],
        });
      }
    }

    return moodData
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Generate technique usage distribution chart data
  List<Map<String, dynamic>> _generateTechniqueUsageChart(
    List<Map<String, dynamic>> sessions,
  ) {
    final techniqueCount = <String, int>{};
    final techniqueMinutes = <String, int>{};

    for (final session in sessions) {
      final technique = session['techniqueName'] as String?;
      final minutes = session['durationMinutes'] as int? ?? 0;

      if (technique != null) {
        techniqueCount[technique] = (techniqueCount[technique] ?? 0) + 1;
        techniqueMinutes[technique] =
            (techniqueMinutes[technique] ?? 0) + minutes;
      }
    }

    return techniqueCount.entries
        .map(
          (entry) => {
            'technique': entry.key,
            'sessionCount': entry.value,
            'totalMinutes': techniqueMinutes[entry.key] ?? 0,
            'percentage': (entry.value / sessions.length * 100).round(),
          },
        )
        .toList()
      ..sort(
        (a, b) =>
            (b['sessionCount'] as int).compareTo(a['sessionCount'] as int),
      );
  }

  /// Generate streak visualization data
  Future<Map<String, dynamic>> _generateStreakChart(
    String userId,
    int days,
  ) async {
    try {
      final streakData = <Map<String, dynamic>>[];
      final now = DateTime.now();
      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final nextDay = date.add(const Duration(days: 1));

        final daySnapshot = await _sessionsCollection
            .where('userId', isEqualTo: userId)
            .where(
              'completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(date),
            )
            .where('completedAt', isLessThan: Timestamp.fromDate(nextDay))
            .limit(1)
            .get();

        final hasActivity = daySnapshot.docs.isNotEmpty;

        if (hasActivity) {
          tempStreak++;
          if (i == 0) currentStreak = tempStreak; // Today's streak
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 0;
        }

        streakData.add({
          'date':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'hasActivity': hasActivity,
          'streakDay': hasActivity ? tempStreak : 0,
        });
      }

      // Check if temp streak is the longest
      if (tempStreak > longestStreak) longestStreak = tempStreak;

      return {
        'dailyStreak': streakData.reversed.toList(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error generating streak chart',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'dailyStreak': <Map<String, dynamic>>[],
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }
  }

  /// Get motive-specific insights and achievements (Enhanced for task 3.3)
  Future<Map<String, dynamic>> getMotiveSpecificInsights(
    String userId,
    String? currentMotive,
  ) async {
    try {
      // Use the enhanced getUserStats method
      final stats = await getUserStats(userId, userMotive: currentMotive);

      // Return the motive insights from the enhanced stats
      return stats['motiveInsights'] as Map<String, dynamic>? ??
          {
            'welcomeMessage': 'Welcome to your calm practice! 🌱',
            'insights': <String>[],
            'achievements': <Map<String, dynamic>>[],
            'motiveEmoji': '🌱',
            'motiveDisplayName': 'Wellness',
            'recommendedTechniques': ['Breathing', 'Meditation'],
            'motivationalMessage': 'Keep up the great work!',
          };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting motive-specific insights',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'welcomeMessage': 'Welcome to your calm practice! 🌱',
        'insights': <String>[],
        'achievements': <Map<String, dynamic>>[],
        'motiveEmoji': '🌱',
        'motiveDisplayName': 'Wellness',
        'recommendedTechniques': ['Breathing', 'Meditation'],
        'motivationalMessage': 'Keep up the great work!',
      };
    }
  }

  /// Integrate with badge system for calm achievements
  Future<void> checkAndAwardBadges(String userId) async {
    try {
      final stats = await getUserStats(userId);
      final totalSessions = stats['totalSessions'] as int;
      final totalMinutes = stats['totalMinutes'] as int;
      final currentStreak = stats['currentStreak'] as int;

      // Award session-based badges
      if (totalSessions >= 10) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_10_sessions',
        );
      }
      if (totalSessions >= 25) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_25_sessions',
        );
      }
      if (totalSessions >= 50) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_50_sessions',
        );
      }

      // Award time-based badges
      if (totalMinutes >= 60) {
        // 1 hour
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_1_hour',
        );
      }
      if (totalMinutes >= 300) {
        // 5 hours
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_5_hours',
        );
      }

      // Award streak-based badges
      if (currentStreak >= 3) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_3_day_streak',
        );
      }
      if (currentStreak >= 7) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_7_day_streak',
        );
      }
      if (currentStreak >= 30) {
        await _firestoreService.logActivityCompletion(
          userId,
          'calm_technique_30_day_streak',
        );
      }

      // Award effectiveness-based badges
      final effectiveness = await getTechniqueEffectiveness(userId);
      if (effectiveness.isNotEmpty) {
        final avgEffectiveness =
            effectiveness.values.reduce((a, b) => a + b) / effectiveness.length;

        if (avgEffectiveness >= 3.0) {
          await _firestoreService.logActivityCompletion(
            userId,
            'calm_technique_high_effectiveness',
          );
        }
      }

      appLogger.i('Badge check completed for user: $userId');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error checking and awarding badges',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get recent calm sessions for analytics
  Stream<List<Map<String, dynamic>>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) {
    return _sessionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              )
              .toList(),
        );
  }

  /// Check if user completed a calm technique today
  Future<bool> hasCompletedTechniqueToday(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where('completedAt', isLessThan: Timestamp.fromDate(tomorrow))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.e(
        'Error checking today\'s calm completion',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
