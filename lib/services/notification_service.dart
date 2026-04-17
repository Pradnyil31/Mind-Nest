import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../core/logger.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // Initialize Timezone
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      // Fallback if timezone not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
    
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    // Safety guard: ensure plugin is initialised before scheduling
    if (!_isInitialized) await init();
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_routine_channel',
            'Daily Routine Reminders',
            channelDescription: 'Reminders for your daily routine activities',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeating daily
      );
    } catch (e) {
      appLogger.w('Error scheduling notification $id: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Ensures core routine notifications are scheduled
  /// IDs 1-4: Wake, Midday, Evening, Bedtime
  Future<void> syncRoutineNotifications({
    required String name,
    required String motive,
    required int wakeHour,
    required int wakeMinute,
    required int bedHour,
    required int bedMinute,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      // 1. Wake Up (ID: 1)
      await scheduleDailyNotification(
        id: 1,
        title: 'Good Morning!',
        body: 'Time for your morning routine, $name.',
        hour: wakeHour,
        minute: wakeMinute,
      );

      // 2. Midday (ID: 2)
      final middayHour = (wakeHour + 6) % 24;
      await scheduleDailyNotification(
        id: 2,
        title: 'Check In',
        body: 'How is your day going, $name? Take a mindful pause.',
        hour: middayHour,
        minute: wakeMinute,
      );

      // 3. Evening (ID: 3)
      final eveningHour = (bedHour - 2 + 24) % 24;
      await scheduleDailyNotification(
        id: 3,
        title: 'Wind Down',
        body: 'Preparing for rest, $name? Let\'s wrap up the day.',
        hour: eveningHour,
        minute: bedMinute,
      );

      // 4. Bedtime (ID: 4)
      await scheduleDailyNotification(
        id: 4,
        title: 'Sweet Dreams',
        body: 'Time for restorative sleep. Goodnight, $name.',
        hour: bedHour,
        minute: bedMinute,
      );

      appLogger.i('Routine notifications synced successfully');
    } catch (e) {
      appLogger.e('Failed to sync routine notifications: $e');
    }
  }
}
