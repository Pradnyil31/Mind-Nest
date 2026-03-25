import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore_service.dart';
import '../../../services/meditation_analytics_service.dart';
import '../../../services/journal_service.dart';
import '../../../models/journal_entry.dart';
import '../../../config/motive_config.dart';
import '../../../core/logger.dart';
import 'calm_progress_service.dart';
import 'mood_tracking_service.dart';

/// Enhanced service for integrating calm features with the existing app ecosystem
/// Implements Requirements 11.1-11.9 for comprehensive ecosystem integration
class EcosystemIntegrationService {
  final FirebaseFirestore _db;
  final FirestoreService _firestore;
  final MeditationAnalyticsService _analytics;
  final JournalService _journal;
  final CalmProgressService _calmProgress;
  final MoodTrackingService _moodTracking;

  factory EcosystemIntegrationService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    MeditationAnalyticsService? meditationAnalytics,
    JournalService? journalService,
    CalmProgressService? calmProgressService,
    MoodTrackingService? moodTrackingService,
  }) {
    final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
    final resolvedFirestoreService =
        firestoreService ?? FirestoreService(firestore: resolvedFirestore);
    final resolvedMoodTracking =
        moodTrackingService ?? MoodTrackingService(firestore: resolvedFirestore);
    final resolvedCalmProgress = calmProgressService ??
        CalmProgressService(
          firestore: resolvedFirestore,
          firestoreService: resolvedFirestoreService,
          moodTrackingService: resolvedMoodTracking,
        );
    final resolvedAnalytics = meditationAnalytics ??
        MeditationAnalyticsService(
          firestore: resolvedFirestore,
          firestoreService: resolvedFirestoreService,
        );
    final resolvedJournalService = journalService ??
        JournalService(firestoreService: resolvedFirestoreService);

    return EcosystemIntegrationService._internal(
      firestore: resolvedFirestore,
      firestoreService: resolvedFirestoreService,
      meditationAnalytics: resolvedAnalytics,
      journalService: resolvedJournalService,
      calmProgressService: resolvedCalmProgress,
      moodTrackingService: resolvedMoodTracking,
    );
  }

  EcosystemIntegrationService._internal({
    required FirebaseFirestore firestore,
    required FirestoreService firestoreService,
    required MeditationAnalyticsService meditationAnalytics,
    required JournalService journalService,
    required CalmProgressService calmProgressService,
    required MoodTrackingService moodTrackingService,
  })  : _db = firestore,
        _firestore = firestoreService,
        _analytics = meditationAnalytics,
        _journal = journalService,
        _calmProgress = calmProgressService,
        _moodTracking = moodTrackingService;

  /// Integrate calm technique completion with daily routine system (Requirement 11.1)
  Future<void> contributeToDailyRoutine(
    String userId,
    String techniqueId,
    String techniqueName,
    int durationMinutes,
  ) async {
    try {
      // Log as activity completion for routine system
      await _firestore.logActivityCompletion(userId, 'calm_technique');

      // Update calm-specific progress
      await _updateCalmProgress(userId, techniqueId, durationMinutes);

      // Check if this contributes to daily routine completion
      await _checkDailyRoutineContribution(userId, techniqueName);

      appLogger.i('Calm technique completion integrated with daily routine');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error integrating calm completion with routine',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if calm technique contributes to daily routine activities
  Future<void> _checkDailyRoutineContribution(
    String userId,
    String techniqueName,
  ) async {
    try {
      // Get today's routine activities
      final userDoc = await _db
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final routineActivities = List<String>.from(
          data['routineActivities'] ?? [],
        );

        // Check if any routine activity matches calm technique usage
        final calmRelatedActivities = routineActivities.where((activity) {
          final activityLower = activity.toLowerCase();
          return activityLower.contains('calm') ||
              activityLower.contains('anxiety') ||
              activityLower.contains('stress') ||
              activityLower.contains('grounding') ||
              activityLower.contains('mindful');
        }).toList();

        // Mark matching activities as completed
        for (final activity in calmRelatedActivities) {
          await _firestore.logActivityCompletion(userId, activity);
          appLogger.i('Marked routine activity as complete: $activity');
        }
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Error checking daily routine contribution',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Integrate with existing streak system
  Future<void> updateStreakSystem(String userId, String activityType) async {
    try {
      // Use existing streak logic from routine system
      await _firestore.logActivityCompletion(userId, activityType);

      appLogger.i('Calm activity integrated with streak system: $activityType');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error updating streak system',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Contribute to unified dashboard and insights (Requirement 11.3)
  /// Enhanced with comprehensive calm progress data
  Future<Map<String, dynamic>> getCalmInsightsForDashboard(
    String userId,
  ) async {
    try {
      // Get comprehensive calm statistics
      final calmStats = await _calmProgress.getUserStats(userId);
      final recentActivity = await _getRecentCalmActivity(userId);
      final moodTrends = await _moodTracking.getMoodTrends(userId);

      // Get user's motive for personalized insights
      final userMotive = await _getUserMotive(userId);
      final motiveProfile = MotiveConfig.getProfile(userMotive);

      return {
        // Basic statistics
        'totalSessions': calmStats['totalSessions'] ?? 0,
        'totalMinutes': calmStats['totalMinutes'] ?? 0,
        'currentStreak': calmStats['currentStreak'] ?? 0,
        'averageMoodImprovement': calmStats['averageMoodImprovement'] ?? 0.0,

        // Enhanced insights
        'recentActivity': recentActivity,
        'lastUsed': calmStats['lastUsed'],
        'favoriteTechnique': calmStats['favoriteTechnique'],
        'weeklyProgress': await _getWeeklyCalmProgress(userId),
        'monthlyStats': calmStats['monthlyStats'] ?? [],

        // Motive-specific data
        'userMotive': userMotive,
        'motiveEmoji': motiveProfile?.emoji ?? '🌱',
        'motiveDisplayName': motiveProfile?.displayName ?? 'Wellness',
        'motiveInsights': calmStats['motiveInsights'] ?? {},

        // Mood tracking integration
        'moodTrends': moodTrends,
        'bestTechniques': moodTrends['bestTechniques'] ?? [],

        // Dashboard-specific formatting
        'displayTitle': _getDashboardTitle(calmStats, userMotive),
        'displayMessage': _getDashboardMessage(calmStats, userMotive),
        'progressColor': _getProgressColor(calmStats),
        'achievements': calmStats['motiveInsights']?['achievements'] ?? [],
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting calm insights for dashboard',
        error: e,
        stackTrace: stackTrace,
      );
      return _getEmptyDashboardInsights(userId);
    }
  }

  /// Get dashboard title based on progress and motive
  String _getDashboardTitle(Map<String, dynamic> stats, String? motive) {
    final totalSessions = stats['totalSessions'] as int? ?? 0;
    final currentStreak = stats['currentStreak'] as int? ?? 0;
    final avgImprovement = stats['averageMoodImprovement'] as double? ?? 0.0;
    final motiveProfile = MotiveConfig.getProfile(motive);
    final emoji = motiveProfile?.emoji ?? '🌱';

    if (currentStreak >= 7) {
      return '$emoji ${currentStreak}-Day Calm Streak!';
    } else if (totalSessions >= 25) {
      return '$emoji Calm Practice Master';
    } else if (avgImprovement >= 3.0) {
      return '$emoji Mood Improvement Champion';
    } else if (totalSessions >= 10) {
      return '$emoji Building Calm Habits';
    } else if (totalSessions > 0) {
      return '$emoji Calm Journey Started';
    } else {
      return '$emoji Ready for Calm?';
    }
  }

  /// Get dashboard message based on progress and motive
  String _getDashboardMessage(Map<String, dynamic> stats, String? motive) {
    final totalSessions = stats['totalSessions'] as int? ?? 0;
    final currentStreak = stats['currentStreak'] as int? ?? 0;
    final avgImprovement = stats['averageMoodImprovement'] as double? ?? 0.0;

    if (currentStreak >= 7) {
      return 'Amazing consistency! Your ${motive?.toLowerCase() ?? 'wellness'} journey is thriving.';
    } else if (avgImprovement >= 3.0) {
      return 'Your techniques are working! Average improvement: ${avgImprovement.toStringAsFixed(1)} points.';
    } else if (totalSessions >= 10) {
      return 'Great progress! You\'ve completed $totalSessions calm sessions.';
    } else if (totalSessions > 0) {
      return 'Keep going! Every session brings you closer to your goals.';
    } else {
      return 'Start your calm practice today with personalized techniques.';
    }
  }

  /// Get progress color based on statistics
  String _getProgressColor(Map<String, dynamic> stats) {
    final currentStreak = stats['currentStreak'] as int? ?? 0;
    final avgImprovement = stats['averageMoodImprovement'] as double? ?? 0.0;
    final totalSessions = stats['totalSessions'] as int? ?? 0;

    if (currentStreak >= 7 || avgImprovement >= 3.0) {
      return '#10B981'; // Green - Excellent
    } else if (currentStreak >= 3 || totalSessions >= 10) {
      return '#F59E0B'; // Amber - Good
    } else if (totalSessions > 0) {
      return '#3B82F6'; // Blue - Getting started
    } else {
      return '#6B7280'; // Gray - Not started
    }
  }

  /// Get empty dashboard insights for new users
  Future<Map<String, dynamic>> _getEmptyDashboardInsights(String userId) async {
    final userMotive = await _getUserMotive(userId);
    final motiveProfile = MotiveConfig.getProfile(userMotive);

    return {
      'totalSessions': 0,
      'totalMinutes': 0,
      'currentStreak': 0,
      'averageMoodImprovement': 0.0,
      'recentActivity': <Map<String, dynamic>>[],
      'lastUsed': null,
      'favoriteTechnique': null,
      'weeklyProgress': <String, int>{},
      'monthlyStats': <Map<String, dynamic>>[],
      'userMotive': userMotive,
      'motiveEmoji': motiveProfile?.emoji ?? '🌱',
      'motiveDisplayName': motiveProfile?.displayName ?? 'Wellness',
      'motiveInsights': {},
      'moodTrends': {},
      'bestTechniques': <Map<String, dynamic>>[],
      'displayTitle': '${motiveProfile?.emoji ?? '🌱'} Ready for Calm?',
      'displayMessage':
          'Start your calm practice today with personalized techniques.',
      'progressColor': '#6B7280',
      'achievements': <Map<String, dynamic>>[],
    };
  }

  /// Connect with existing journaling feature for reflection prompts (Requirement 11.5)
  /// Enhanced with mood-based and technique-specific prompts
  Future<List<String>> getCalmReflectionPrompts(
    String userId,
    String techniqueId, {
    int? preMoodRating,
    int? postMoodRating,
  }) async {
    try {
      final technique = await _getTechniqueDetails(techniqueId);
      final userMotive = await _getUserMotive(userId);
      final moodImprovement = (preMoodRating != null && postMoodRating != null)
          ? postMoodRating - preMoodRating
          : null;

      return _generateEnhancedReflectionPrompts(
        technique,
        userMotive,
        moodImprovement,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        'Error generating calm reflection prompts',
        error: e,
        stackTrace: stackTrace,
      );
      return _getDefaultReflectionPrompts();
    }
  }

  /// Create a journal entry with calm technique reflection
  Future<void> createCalmReflectionEntry(
    String userId,
    String techniqueId,
    String techniqueName,
    int? moodImprovement,
    String reflectionContent,
  ) async {
    try {
      final userMotive = await _getUserMotive(userId);
      final motiveProfile = MotiveConfig.getProfile(userMotive);

      final entry = JournalEntry(
        id: '', // Will be set by the service
        userId: userId,
        title: 'Calm Practice Reflection: $techniqueName',
        content: reflectionContent,
        mood: _getMoodFromImprovement(moodImprovement),
        timestamp: DateTime.now(),
        tags: [
          'calm',
          'technique',
          techniqueName.toLowerCase().replaceAll(' ', '_'),
          if (userMotive != null) userMotive.toLowerCase(),
          if (moodImprovement != null && moodImprovement > 0) 'improvement',
          if (moodImprovement != null && moodImprovement < 0) 'challenge',
        ],
      );

      await _journal.addEntry(entry);

      appLogger.i(
        'Created calm reflection journal entry for technique: $techniqueName',
      );
    } catch (e, stackTrace) {
      appLogger.e(
        'Error creating calm reflection entry',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get mood string from improvement score
  String _getMoodFromImprovement(int? improvement) {
    if (improvement == null) return 'Neutral';
    if (improvement >= 3) return 'Great';
    if (improvement >= 1) return 'Good';
    if (improvement == 0) return 'Neutral';
    if (improvement >= -2) return 'Okay';
    return 'Challenging';
  }

  /// Generate enhanced reflection prompts based on technique and mood data
  List<String> _generateEnhancedReflectionPrompts(
    Map<String, dynamic> technique,
    String? motive,
    int? moodImprovement,
  ) {
    final prompts = <String>[];

    // Mood-based prompts
    if (moodImprovement != null) {
      if (moodImprovement > 0) {
        prompts.add(
          'What specifically helped improve your mood during this technique?',
        );
        prompts.add('How can you remember this feeling when you need it most?');
      } else if (moodImprovement < 0) {
        prompts.add('What made this technique challenging today?');
        prompts.add(
          'What might help this technique work better for you next time?',
        );
      } else {
        prompts.add(
          'Even though your mood stayed the same, what did you notice during the practice?',
        );
      }
    }

    // Technique-specific prompts
    final techniqueType = technique['type'] as String? ?? 'general';
    switch (techniqueType) {
      case 'grounding':
        prompts.add(
          'Which of your senses felt most grounded during this practice?',
        );
        prompts.add('What physical sensations did you notice?');
        break;
      case 'breathing':
        prompts.add('How did your breathing change throughout the practice?');
        prompts.add(
          'What did you notice about your body as you focused on breathing?',
        );
        break;
      case 'visualization':
        prompts.add('What images or scenes came most easily to you?');
        prompts.add(
          'How vivid were the visualizations, and how did they make you feel?',
        );
        break;
      case 'affirmation':
        prompts.add('Which affirmations resonated most strongly with you?');
        prompts.add('How did speaking these words to yourself feel?');
        break;
    }

    // Motive-specific prompts
    switch (motive) {
      case 'Sleep':
        prompts.add('How relaxed does your body feel now?');
        prompts.add('What thoughts about sleep are different now?');
        break;
      case 'Stress':
        prompts.add('What stress did you release during this practice?');
        prompts.add('How can you carry this calm feeling into your day?');
        break;
      case 'Anxiety':
        prompts.add('What anxious thoughts became quieter?');
        prompts.add('How grounded and present do you feel right now?');
        break;
      case 'Focus':
        prompts.add('How clear and focused does your mind feel?');
        prompts.add('What will you focus your attention on next?');
        break;
      case 'Habit Building':
        prompts.add('How does this practice support your larger goals?');
        prompts.add('What habit patterns are you noticing in yourself?');
        break;
    }

    // General reflection prompts
    prompts.addAll([
      'What surprised you most about this practice?',
      'Would you use this technique again? Why or why not?',
      'What would you tell someone else about this technique?',
    ]);

    // Return a curated selection of 4-6 prompts
    prompts.shuffle();
    return prompts.take(6).toList();
  }

  /// Get default reflection prompts when personalization fails
  List<String> _getDefaultReflectionPrompts() {
    return [
      'How did this calm technique make you feel?',
      'What thoughts came up during the practice?',
      'Would you use this technique again?',
      'What did you notice about your breathing or body?',
      'How might this practice help you in daily life?',
    ];
  }

  /// Integrate with existing notification system for calm reminders (Requirement 11.4)
  /// Enhanced with motive-specific and intelligent scheduling
  Future<void> scheduleCalmReminders(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final appPreferences = await getAppPreferences(userId);
      final userMotive = appPreferences['primaryMotive'] as String?;
      final quietHours = appPreferences['quietHours'] as Map<String, dynamic>?;

      // Only schedule if notifications are enabled app-wide
      if (appPreferences['notificationsEnabled'] != true) {
        appLogger.i(
          'Skipping calm reminders - notifications disabled app-wide',
        );
        return;
      }

      final enhancedPreferences = {
        'enabled': preferences['enabled'] ?? true,
        'frequency': preferences['frequency'] ?? 'daily',
        'preferredTime':
            preferences['preferredTime'] ?? _getOptimalReminderTime(userMotive),
        'motiveSpecific': preferences['motiveSpecific'] ?? true,
        'userMotive': userMotive,
        'quietHours': quietHours,
        'reminderTypes': {
          'dailyPractice': preferences['dailyPractice'] ?? true,
          'streakCelebration': preferences['streakCelebration'] ?? true,
          'moodCheckIn': preferences['moodCheckIn'] ?? true,
          'emergencySupport': preferences['emergencySupport'] ?? false,
        },
        'motiveSpecificMessages': _getMotiveReminderMessages(userMotive),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('users')
          .doc(userId)
          .collection('calm_preferences')
          .doc('notifications')
          .set(enhancedPreferences, SetOptions(merge: true));

      appLogger.i('Enhanced calm reminder preferences updated');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error scheduling calm reminders',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get optimal reminder time based on user's motive
  String _getOptimalReminderTime(String? motive) {
    switch (motive) {
      case 'Sleep':
        return '20:00'; // Evening for sleep preparation
      case 'Stress':
        return '12:00'; // Midday for stress relief
      case 'Anxiety':
        return '09:00'; // Morning for anxiety management
      case 'Focus':
        return '08:00'; // Early morning for focus preparation
      case 'Habit Building':
        return '07:00'; // Early morning for habit reinforcement
      default:
        return '09:00'; // Default morning time
    }
  }

  /// Get motive-specific reminder messages
  Map<String, List<String>> _getMotiveReminderMessages(String? motive) {
    final motiveProfile = MotiveConfig.getProfile(motive);
    final emoji = motiveProfile?.emoji ?? '🌱';

    switch (motive) {
      case 'Sleep':
        return {
          'dailyPractice': [
            '$emoji Time for your evening calm practice',
            '$emoji Prepare your mind for restful sleep',
            '$emoji Wind down with a calming technique',
          ],
          'streakCelebration': [
            '$emoji Amazing! ${motiveProfile?.displayName} streak continues!',
            '$emoji Your sleep habits are getting stronger!',
          ],
          'moodCheckIn': [
            '$emoji How are you feeling before sleep?',
            '$emoji Ready to track your evening mood?',
          ],
        };
      case 'Stress':
        return {
          'dailyPractice': [
            '$emoji Take a moment to release today\'s stress',
            '$emoji Your calm practice is waiting',
            '$emoji Time to reset and recharge',
          ],
          'streakCelebration': [
            '$emoji Stress management streak going strong!',
            '$emoji You\'re building amazing resilience!',
          ],
          'moodCheckIn': [
            '$emoji How\'s your stress level today?',
            '$emoji Ready to check in with yourself?',
          ],
        };
      case 'Anxiety':
        return {
          'dailyPractice': [
            '$emoji Ground yourself with a calm technique',
            '$emoji You\'ve got this - take a mindful moment',
            '$emoji Your anxiety toolkit is ready',
          ],
          'streakCelebration': [
            '$emoji Anxiety management streak continues!',
            '$emoji You\'re building incredible strength!',
          ],
          'moodCheckIn': [
            '$emoji How are you feeling right now?',
            '$emoji Ready to check in with your emotions?',
          ],
        };
      case 'Focus':
        return {
          'dailyPractice': [
            '$emoji Sharpen your focus with a calm technique',
            '$emoji Prepare your mind for deep work',
            '$emoji Time to center your attention',
          ],
          'streakCelebration': [
            '$emoji Focus practice streak is amazing!',
            '$emoji Your concentration skills are growing!',
          ],
          'moodCheckIn': [
            '$emoji How clear is your mind today?',
            '$emoji Ready to assess your focus level?',
          ],
        };
      case 'Habit Building':
        return {
          'dailyPractice': [
            '$emoji Consistency builds success - practice time!',
            '$emoji Another step in your habit journey',
            '$emoji Your future self will thank you',
          ],
          'streakCelebration': [
            '$emoji Habit building streak is incredible!',
            '$emoji You\'re creating lasting change!',
          ],
          'moodCheckIn': [
            '$emoji How motivated are you feeling?',
            '$emoji Ready to track your progress?',
          ],
        };
      default:
        return {
          'dailyPractice': [
            '$emoji Time for your calm practice',
            '$emoji Take a moment for yourself',
            '$emoji Your wellness journey continues',
          ],
          'streakCelebration': [
            '$emoji Wellness streak going strong!',
            '$emoji You\'re building great habits!',
          ],
          'moodCheckIn': [
            '$emoji How are you feeling today?',
            '$emoji Ready to check in with yourself?',
          ],
        };
    }
  }

  /// Respect existing app preferences for themes, notifications, and privacy
  /// Enhanced with comprehensive preference integration
  Future<Map<String, dynamic>> getAppPreferences(String userId) async {
    try {
      final userDoc = await _db
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return {
          // Theme preferences
          'theme': data['theme'] ?? 'system',
          'primaryMotive': data['primaryMotive'],

          // Notification preferences
          'notificationsEnabled': data['notificationsEnabled'] ?? true,
          'reminderFrequency': data['reminderFrequency'] ?? 'daily',
          'quietHours':
              data['quietHours'] ?? {'start': '22:00', 'end': '07:00'},

          // Privacy preferences
          'privacyMode': data['privacyMode'] ?? false,
          'dataSharing': data['dataSharing'] ?? true,
          'analyticsEnabled': data['analyticsEnabled'] ?? true,

          // Accessibility preferences
          'highContrast': data['highContrast'] ?? false,
          'reducedMotion': data['reducedMotion'] ?? false,
          'audioGuidanceOnly': data['audioGuidanceOnly'] ?? false,
          'largeText': data['largeText'] ?? false,
          'voiceControlEnabled': data['voiceControlEnabled'] ?? false,

          // Calm-specific preferences
          'calmRemindersEnabled': data['calmRemindersEnabled'] ?? true,
          'moodTrackingEnabled': data['moodTrackingEnabled'] ?? true,
          'progressSharingEnabled': data['progressSharingEnabled'] ?? true,
        };
      }

      return _getDefaultPreferences();
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting app preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return _getDefaultPreferences();
    }
  }

  /// Ensure compatibility with existing app preferences and themes (Requirement 11.6)
  /// Enhanced with comprehensive preference integration
  Future<void> applyCalmThemeCompatibility(String userId) async {
    try {
      final preferences = await getAppPreferences(userId);
      final theme = preferences['theme'] as String?;
      final userMotive = preferences['primaryMotive'] as String?;
      final motiveProfile = MotiveConfig.getProfile(userMotive);

      // Create comprehensive calm theme preferences
      final calmThemePreferences = {
        'inheritFromApp': true,
        'appTheme': theme,
        'userMotive': userMotive,
        'motiveColors': motiveProfile != null
            ? {
                'emoji': motiveProfile.emoji,
                'displayName': motiveProfile.displayName,
              }
            : null,
        'calmSpecificOverrides': {
          // Respect app theme but add calm-specific enhancements
          'soundscapeVisualization': preferences['reducedMotion'] != true,
          'ambientSoundEnabled': preferences['notificationsEnabled'] == true,
          'moodTrackingEnabled': preferences['privacyMode'] != true,
          'progressSharingEnabled': preferences['dataSharing'] == true,
        },
        'accessibilitySettings': {
          'highContrast': preferences['highContrast'] ?? false,
          'reducedMotion': preferences['reducedMotion'] ?? false,
          'audioGuidanceOnly': preferences['audioGuidanceOnly'] ?? false,
          'largeText': preferences['largeText'] ?? false,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('users')
          .doc(userId)
          .collection('calm_preferences')
          .doc('theme')
          .set(calmThemePreferences, SetOptions(merge: true));

      appLogger.i('Enhanced calm theme compatibility applied');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error applying calm theme compatibility',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get default preferences for new users
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'theme': 'system',
      'primaryMotive': null,
      'notificationsEnabled': true,
      'reminderFrequency': 'daily',
      'quietHours': {'start': '22:00', 'end': '07:00'},
      'privacyMode': false,
      'dataSharing': true,
      'analyticsEnabled': true,
      'highContrast': false,
      'reducedMotion': false,
      'audioGuidanceOnly': false,
      'largeText': false,
      'voiceControlEnabled': false,
      'calmRemindersEnabled': true,
      'moodTrackingEnabled': true,
      'progressSharingEnabled': true,
    };
  }

  /// Update calm-specific preferences while respecting app-wide settings
  Future<void> updateCalmPreferences(
    String userId,
    Map<String, dynamic> calmPreferences,
  ) async {
    try {
      final appPreferences = await getAppPreferences(userId);

      // Ensure calm preferences don't conflict with app-wide privacy settings
      final sanitizedPreferences = <String, dynamic>{};

      calmPreferences.forEach((key, value) {
        switch (key) {
          case 'moodTrackingEnabled':
            // Respect privacy mode
            sanitizedPreferences[key] =
                value && (appPreferences['privacyMode'] != true);
            break;
          case 'progressSharingEnabled':
            // Respect data sharing preference
            sanitizedPreferences[key] =
                value && (appPreferences['dataSharing'] == true);
            break;
          case 'calmRemindersEnabled':
            // Respect notifications preference
            sanitizedPreferences[key] =
                value && (appPreferences['notificationsEnabled'] == true);
            break;
          default:
            sanitizedPreferences[key] = value;
        }
      });

      await _db
          .collection('users')
          .doc(userId)
          .collection('calm_preferences')
          .doc('settings')
          .set({
            ...sanitizedPreferences,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      appLogger.i('Calm preferences updated with app compatibility');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error updating calm preferences',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get navigation links to existing features without duplication (Requirement 11.7)
  Map<String, NavigationLink> getExistingFeatureLinks() {
    return {
      'breathing': NavigationLink(
        title: 'Breathing Exercises',
        description: 'Structured breathing patterns and techniques',
        route: '/breathing',
        icon: 'air',
        category: 'wellness',
      ),
      'meditation': NavigationLink(
        title: 'Meditation Library',
        description: 'Guided meditations and mindfulness practices',
        route: '/meditation',
        icon: 'self_improvement',
        category: 'wellness',
      ),
      'journaling': NavigationLink(
        title: 'Journaling',
        description: 'Reflect on your calm practice and insights',
        route: '/journaling',
        icon: 'edit_note',
        category: 'reflection',
      ),
    };
  }

  /// Get comprehensive ecosystem integration status
  Future<Map<String, dynamic>> getEcosystemIntegrationStatus(
    String userId,
  ) async {
    try {
      final calmStats = await _calmProgress.getUserStats(userId);
      final appPreferences = await getAppPreferences(userId);
      final todayUsage = await _getTodayUsageStatus(userId);

      return {
        'calmIntegration': {
          'totalSessions': calmStats['totalSessions'] ?? 0,
          'currentStreak': calmStats['currentStreak'] ?? 0,
          'lastUsed': calmStats['lastUsed'],
          'isActive': (calmStats['totalSessions'] as int? ?? 0) > 0,
        },
        'routineIntegration': {
          'contributesToDaily': true,
          'streakIntegrated': true,
          'badgeSystemConnected': true,
        },
        'dashboardIntegration': {
          'progressVisible': appPreferences['dataSharing'] == true,
          'insightsEnabled': appPreferences['analyticsEnabled'] == true,
          'motivePersonalized': appPreferences['primaryMotive'] != null,
        },
        'journalingIntegration': {
          'reflectionPromptsEnabled': true,
          'autoEntryCreation': appPreferences['privacyMode'] != true,
          'moodTrackingLinked': appPreferences['moodTrackingEnabled'] == true,
        },
        'preferencesCompatibility': {
          'themeRespected': true,
          'notificationsRespected':
              appPreferences['notificationsEnabled'] == true,
          'privacyRespected': appPreferences['privacyMode'] == true,
          'accessibilitySupported': true,
        },
        'todayUsage': todayUsage,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting ecosystem integration status',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get today's usage status across all integrated features
  Future<Map<String, bool>> _getTodayUsageStatus(String userId) async {
    try {
      final hasCalmToday = await _calmProgress.hasCompletedTechniqueToday(
        userId,
      );
      final hasMeditatedToday = await _analytics.hasMeditatedToday(userId);

      // Check if user has journaled today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final journalSnapshot = await _db
          .collection('journal_entries')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      final hasJournaledToday = journalSnapshot.docs.isNotEmpty;

      return {
        'calm': hasCalmToday,
        'meditation': hasMeditatedToday,
        'journaling': hasJournaledToday,
        'breathing':
            false, // Would integrate with breathing analytics if available
      };
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting today usage status',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'calm': false,
        'meditation': false,
        'journaling': false,
        'breathing': false,
      };
    }
  }

  /// Private helper methods

  Future<void> _updateCalmProgress(
    String userId,
    String techniqueId,
    int durationMinutes,
  ) async {
    final progressRef = _db
        .collection('users')
        .doc(userId)
        .collection('calm_progress')
        .doc('summary');

    await progressRef.set({
      'totalSessions': FieldValue.increment(1),
      'totalMinutes': FieldValue.increment(durationMinutes),
      'lastTechniqueId': techniqueId,
      'lastUsed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _getCalmStats(String userId) async {
    final progressDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('calm_progress')
        .doc('summary')
        .get();

    if (progressDoc.exists) {
      return progressDoc.data() as Map<String, dynamic>;
    }

    return {'totalSessions': 0, 'totalMinutes': 0, 'currentStreak': 0};
  }

  Future<List<Map<String, dynamic>>> _getRecentCalmActivity(
    String userId,
  ) async {
    final recentSessions = await _db
        .collection('calm_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(5)
        .get();

    return recentSessions.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  Future<Map<String, int>> _getWeeklyCalmProgress(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final weekSessions = await _db
        .collection('calm_sessions')
        .where('userId', isEqualTo: userId)
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
        )
        .get();

    final progress = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      progress[dayKey] = 0;
    }

    for (final doc in weekSessions.docs) {
      final data = doc.data();
      final timestamp = (data['completedAt'] as Timestamp).toDate();
      final dayKey =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      progress[dayKey] = (progress[dayKey] ?? 0) + 1;
    }

    return progress;
  }

  Future<Map<String, dynamic>> _getTechniqueDetails(String techniqueId) async {
    // This would fetch technique details from the calm techniques collection
    // For now, return basic structure with enhanced data
    return {
      'id': techniqueId,
      'category': 'grounding',
      'type': 'grounding', // Will be used for reflection prompts
      'name': techniqueId.replaceAll('_', ' ').replaceAll('-', ' '),
    };
  }

  Future<String?> _getUserMotive(String userId) async {
    final userDoc = await _db
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      return data['primaryMotive'] as String?;
    }

    return null;
  }

  List<String> _generateReflectionPrompts(
    Map<String, dynamic> technique,
    String? motive,
  ) {
    final basePrompts = [
      'How did this technique make you feel?',
      'What thoughts came up during the practice?',
      'Would you use this technique again?',
    ];

    // Add motive-specific prompts
    switch (motive) {
      case 'Sleep':
        basePrompts.add('How relaxed do you feel now?');
        basePrompts.add('What might help you sleep better tonight?');
        break;
      case 'Stress':
        basePrompts.add('What stress did you release during this practice?');
        basePrompts.add('How can you carry this calm feeling forward?');
        break;
      case 'Anxiety':
        basePrompts.add('What anxious thoughts became quieter?');
        basePrompts.add('How grounded do you feel right now?');
        break;
      case 'Focus':
        basePrompts.add('How clear does your mind feel?');
        basePrompts.add('What will you focus on next?');
        break;
      case 'Habit Building':
        basePrompts.add('How does this practice support your goals?');
        basePrompts.add('What habit are you building through this?');
        break;
    }

    return basePrompts;
  }
}

/// Navigation link model for existing features
class NavigationLink {
  final String title;
  final String description;
  final String route;
  final String icon;
  final String category;

  NavigationLink({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.category,
  });
}
