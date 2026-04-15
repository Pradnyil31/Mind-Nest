import 'dart:async';
import 'package:logger/logger.dart';
import '../../../services/notification_service.dart';
import '../../../config/motive_config.dart';

/// Service for managing calm-specific notifications including reminders,
/// achievements, and emergency technique suggestions
class CalmNotificationService {
  final Logger _logger = Logger();
  final NotificationService _notificationService;

  CalmNotificationService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  // Notification IDs for different types
  static const int _baseReminderId = 1000;
  static const int _achievementId = 2000;
  static const int _streakId = 3000;
  static const int _emergencyId = 4000;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      await _notificationService.init();
      await _notificationService.requestPermissions();
      _logger.i('CalmNotificationService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize CalmNotificationService: $e');
      rethrow;
    }
  }

  /// Schedule motive-specific calm reminders
  Future<void> scheduleMotiveReminders(String userId, String motive) async {
    try {
      // Cancel existing reminders first
      await cancelAllReminders(userId);

      final profile = MotiveConfig.getProfile(motive);
      if (profile == null) {
        _logger.w('No profile found for motive: $motive');
        return;
      }

      // Schedule morning reminder
      await _scheduleMorningReminder(motive, profile);

      // Schedule evening reminder
      await _scheduleEveningReminder(motive, profile);

      // Schedule midday reminder for stress/anxiety motives
      if (motive.toLowerCase() == 'stress' ||
          motive.toLowerCase() == 'anxiety') {
        await _scheduleMiddayReminder(motive, profile);
      }

      _logger.i('Scheduled motive reminders for $motive');
    } catch (e) {
      _logger.e('Failed to schedule motive reminders: $e');
      rethrow;
    }
  }

  /// Send achievement notification
  Future<void> sendAchievementNotification(
    String userId,
    String achievement,
  ) async {
    try {
      await _notificationService.scheduleDailyNotification(
        id: _achievementId,
        title: '🎉 Achievement Unlocked!',
        body: achievement,
        hour: DateTime.now().hour,
        minute: DateTime.now().minute + 1, // Send in 1 minute
      );

      _logger.i('Sent achievement notification: $achievement');
    } catch (e) {
      _logger.e('Failed to send achievement notification: $e');
    }
  }

  /// Send streak celebration notification
  Future<void> sendStreakCelebration(
    String userId,
    int streakDays,
    String? motive,
  ) async {
    try {
      final streakMessage = MotiveConfig.getInsightMessage(
        motive,
        'streak',
        count: streakDays,
      );

      await _notificationService.scheduleDailyNotification(
        id: _streakId,
        title: 'Streak Celebration! 🔥',
        body: streakMessage,
        hour: DateTime.now().hour,
        minute: DateTime.now().minute + 1, // Send in 1 minute
      );

      _logger.i('Sent streak celebration for $streakDays days');
    } catch (e) {
      _logger.e('Failed to send streak celebration: $e');
    }
  }

  /// Send emergency technique suggestion
  Future<void> sendEmergencyTechniqueSuggestion(
    String userId,
    String techniqueName,
    String? motive,
  ) async {
    try {
      final profile = MotiveConfig.getProfile(motive);
      final emoji = profile?.emoji ?? '💜';

      await _notificationService.scheduleDailyNotification(
        id: _emergencyId,
        title: '$emoji Quick Relief Available',
        body: 'Try "$techniqueName" for immediate calm support',
        hour: DateTime.now().hour,
        minute: DateTime.now().minute + 1, // Send in 1 minute
      );

      _logger.i('Sent emergency technique suggestion: $techniqueName');
    } catch (e) {
      _logger.e('Failed to send emergency technique suggestion: $e');
    }
  }

  /// Cancel all calm-related reminders for a user
  Future<void> cancelAllReminders(String userId) async {
    try {
      // Cancel all notification types
      await _notificationService.cancel(_baseReminderId + 1);
      await _notificationService.cancel(_baseReminderId + 2);
      await _notificationService.cancel(_baseReminderId + 3);
      _logger.i('Cancelled all calm reminders for user: $userId');
    } catch (e) {
      _logger.e('Failed to cancel reminders: $e');
    }
  }

  /// Schedule morning reminder based on motive
  Future<void> _scheduleMorningReminder(
    String motive,
    MotiveProfile profile,
  ) async {
    final messages = _getMorningMessages(motive, profile);
    final message = messages[DateTime.now().day % messages.length];

    await _notificationService.scheduleDailyNotification(
      id: _baseReminderId + 1,
      title: '${profile.emoji} Good Morning!',
      body: message,
      hour: 8, // 8 AM
      minute: 0,
    );
  }

  /// Schedule evening reminder based on motive
  Future<void> _scheduleEveningReminder(
    String motive,
    MotiveProfile profile,
  ) async {
    final messages = _getEveningMessages(motive, profile);
    final message = messages[DateTime.now().day % messages.length];

    await _notificationService.scheduleDailyNotification(
      id: _baseReminderId + 2,
      title: '${profile.emoji} Evening Check-in',
      body: message,
      hour: 19, // 7 PM
      minute: 0,
    );
  }

  /// Schedule midday reminder for stress/anxiety motives
  Future<void> _scheduleMiddayReminder(
    String motive,
    MotiveProfile profile,
  ) async {
    final messages = _getMiddayMessages(motive, profile);
    final message = messages[DateTime.now().day % messages.length];

    await _notificationService.scheduleDailyNotification(
      id: _baseReminderId + 3,
      title: '${profile.emoji} Midday Reset',
      body: message,
      hour: 13, // 1 PM
      minute: 0,
    );
  }

  /// Get motive-specific morning messages
  List<String> _getMorningMessages(String motive, MotiveProfile profile) {
    switch (motive.toLowerCase()) {
      case 'sleep':
        return [
          'How did you sleep? Start your day with morning sunlight exposure.',
          'Time to make your bed and set a positive tone for the day.',
          'Begin with gentle movement to wake up your body naturally.',
        ];
      case 'stress':
        return [
          'Take a moment for morning mindfulness before the day begins.',
          'Start slowly today - your nervous system will thank you.',
          'Set a positive intention for managing stress today.',
        ];
      case 'anxiety':
        return [
          'Ground yourself with a few deep breaths this morning.',
          'You\'re safe and capable. Set a gentle intention for today.',
          'Begin with your daily anchor habit for stability.',
        ];
      case 'focus':
        return [
          'Clear your workspace and prioritize your most important task.',
          'Set your focus intention - what matters most today?',
          'Review your goals and prepare for a productive day.',
        ];
      case 'habit building':
        return [
          'Consistency is key - start with your morning routine.',
          'Small actions today build tomorrow\'s habits.',
          'Check in with your habit stack - what\'s first?',
        ];
      default:
        return [
          'Good morning! Take a moment for mindful breathing.',
          'Start your day with intention and self-compassion.',
          'You\'ve got this - begin with one small positive action.',
        ];
    }
  }

  /// Get motive-specific evening messages
  List<String> _getEveningMessages(String motive, MotiveProfile profile) {
    switch (motive.toLowerCase()) {
      case 'sleep':
        return [
          'Time to wind down - try limiting screens for better sleep.',
          'Create your evening ritual for quality rest tonight.',
          'How was your sleep preparation today?',
        ];
      case 'stress':
        return [
          'Reflect on today - what went well despite the challenges?',
          'Try progressive muscle relaxation to release today\'s tension.',
          'Practice gratitude for three things that brought you peace.',
        ];
      case 'anxiety':
        return [
          'You made it through today - that\'s worth celebrating.',
          'Try some worry journaling to clear your mind for rest.',
          'Create a safe space meditation before sleep.',
        ];
      case 'focus':
        return [
          'Review today\'s accomplishments and plan tomorrow.',
          'Celebrate the small wins from your focused work today.',
          'Prepare your environment for tomorrow\'s success.',
        ];
      case 'habit building':
        return [
          'Track your habits - consistency is building momentum.',
          'Reflect on today\'s progress in your habit journey.',
          'Prepare for tomorrow - what habits will you practice?',
        ];
      default:
        return [
          'Take a moment to reflect on today\'s positive moments.',
          'Practice evening gratitude for a peaceful night.',
          'You\'ve done well today - rest and recharge.',
        ];
    }
  }

  /// Get motive-specific midday messages for stress/anxiety
  List<String> _getMiddayMessages(String motive, MotiveProfile profile) {
    switch (motive.toLowerCase()) {
      case 'stress':
        return [
          'Midday reset - take three deep breaths and check in.',
          'How\'s your stress level? Try a quick grounding exercise.',
          'Time for a mindful break - step away from the pressure.',
        ];
      case 'anxiety':
        return [
          'Pause and ground yourself - you\'re doing great.',
          'Check in with your body - what do you need right now?',
          'Remember: this feeling will pass. You\'re safe.',
        ];
      default:
        return [
          'Midday check-in - how are you feeling right now?',
          'Take a mindful moment to reset and refocus.',
          'You\'re halfway through the day - keep going!',
        ];
    }
  }
}
