import '../../../core/logger.dart';
import 'ecosystem_integration_service.dart';
import 'calm_progress_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Complete integration workflow for calm technique completion
/// Handles all ecosystem integrations in a single coordinated flow
class CompleteIntegrationWorkflow {
  final EcosystemIntegrationService _ecosystemService;
  final CalmProgressService _calmProgress;
  final FirebaseFirestore _db;

  CompleteIntegrationWorkflow({
    EcosystemIntegrationService? ecosystemService,
    CalmProgressService? calmProgressService,
    FirebaseFirestore? firestore,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _ecosystemService = ecosystemService ??
            EcosystemIntegrationService(
              firestore: firestore ?? FirebaseFirestore.instance,
            ),
        _calmProgress = calmProgressService ??
            CalmProgressService(
              firestore: firestore ?? FirebaseFirestore.instance,
            );
  /// Execute complete integration workflow when a calm technique is completed
  /// This is the main entry point for all ecosystem integrations
  Future<void> executeCompleteIntegration({
    required String userId,
    required String techniqueId,
    required String techniqueName,
    required int durationMinutes,
    required String moodSessionId,
    required int postMoodRating,
    bool createJournalEntry = false,
    String? reflectionContent,
  }) async {
    try {
      appLogger.i(
        'Starting complete integration workflow for technique: $techniqueName',
      );

      // Step 1: Complete the technique session with mood tracking
      await _calmProgress.completeTechniqueSession(
        userId: userId,
        moodSessionId: moodSessionId,
        techniqueId: techniqueId,
        techniqueName: techniqueName,
        durationMinutes: durationMinutes,
        postMoodRating: postMoodRating,
      );

      // Step 2: Integrate with daily routine system (Requirement 11.1)
      await _ecosystemService.contributeToDailyRoutine(
        userId,
        techniqueId,
        techniqueName,
        durationMinutes,
      );

      // Step 3: Update app preferences compatibility (Requirement 11.6)
      await _ecosystemService.applyCalmThemeCompatibility(userId);

      // Step 4: Create journal reflection entry if requested (Requirement 11.5)
      if (createJournalEntry && reflectionContent != null) {
        // Get mood improvement for context
        final moodSessionDoc = await _getMoodSessionData(moodSessionId);
        final moodImprovement = moodSessionDoc?['moodImprovement'] as int?;

        await _ecosystemService.createCalmReflectionEntry(
          userId,
          techniqueId,
          techniqueName,
          moodImprovement,
          reflectionContent,
        );
      }

      // Step 5: Update notification preferences based on usage patterns
      await _updateNotificationPreferences(
        userId,
        techniqueId,
        durationMinutes,
      );

      appLogger.i('Complete integration workflow executed successfully');
    } catch (e, stackTrace) {
      appLogger.e(
        'Error in complete integration workflow',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get reflection prompts for journaling integration
  Future<List<String>> getReflectionPrompts({
    required String userId,
    required String techniqueId,
    int? preMoodRating,
    int? postMoodRating,
  }) async {
    try {
      return await _ecosystemService.getCalmReflectionPrompts(
        userId,
        techniqueId,
        preMoodRating: preMoodRating,
        postMoodRating: postMoodRating,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting reflection prompts',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get comprehensive dashboard insights for unified progress display
  Future<Map<String, dynamic>> getDashboardInsights(String userId) async {
    try {
      return await _ecosystemService.getCalmInsightsForDashboard(userId);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting dashboard insights',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Get ecosystem integration status for monitoring
  Future<Map<String, dynamic>> getIntegrationStatus(String userId) async {
    try {
      return await _ecosystemService.getEcosystemIntegrationStatus(userId);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error getting integration status',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Update calm preferences while respecting app-wide settings
  Future<void> updateCalmPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _ecosystemService.updateCalmPreferences(userId, preferences);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error updating calm preferences',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Schedule intelligent calm reminders based on usage patterns
  Future<void> scheduleIntelligentReminders(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _ecosystemService.scheduleCalmReminders(userId, preferences);
    } catch (e, stackTrace) {
      appLogger.e(
        'Error scheduling intelligent reminders',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Private helper methods

  Future<Map<String, dynamic>?> _getMoodSessionData(
    String moodSessionId,
  ) async {
    try {
      final doc = await _db
          .collection('mood_sessions')
          .doc(moodSessionId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      appLogger.e('Error getting mood session data: $e');
      return null;
    }
  }

  Future<void> _updateNotificationPreferences(
    String userId,
    String techniqueId,
    int durationMinutes,
  ) async {
    try {
      // Get current usage patterns to optimize notification timing
      final stats = await _calmProgress.getUserStats(userId);
      final totalSessions = stats['totalSessions'] as int? ?? 0;
      final currentStreak = stats['currentStreak'] as int? ?? 0;

      // Adjust notification preferences based on usage patterns
      final preferences = <String, dynamic>{};

      // Increase frequency for engaged users
      if (totalSessions >= 10 && currentStreak >= 3) {
        preferences['frequency'] = 'daily';
        preferences['streakCelebration'] = true;
      } else if (totalSessions >= 5) {
        preferences['frequency'] = 'every_other_day';
      } else {
        preferences['frequency'] = 'weekly';
      }

      // Enable mood check-ins for users who complete longer sessions
      if (durationMinutes >= 5) {
        preferences['moodCheckIn'] = true;
      }

      // Update preferences if we have meaningful changes
      if (preferences.isNotEmpty) {
        await _ecosystemService.scheduleCalmReminders(userId, preferences);
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Error updating notification preferences',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}


