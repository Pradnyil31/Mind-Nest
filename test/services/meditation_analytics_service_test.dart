import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/services/meditation_analytics_service.dart';

void main() {
  group('MeditationAnalyticsService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MeditationAnalyticsService analyticsService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      analyticsService = MeditationAnalyticsService(firestore: fakeFirestore);
    });

    test('getCurrentStreak returns consecutive-day streak', () async {
      final userId = 'user-streak';
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 9);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      await fakeFirestore.collection('meditation_sessions').doc('s1').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(today),
      });
      await fakeFirestore.collection('meditation_sessions').doc('s2').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(yesterday),
      });
      await fakeFirestore.collection('meditation_sessions').doc('s3').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(twoDaysAgo),
      });

      final streak = await analyticsService.getCurrentStreak(userId);
      expect(streak, 3);
    });

    test('getCurrentStreak returns 0 when latest session is stale', () async {
      final userId = 'user-stale';
      final staleDay = DateTime.now().subtract(const Duration(days: 3));

      await fakeFirestore.collection('meditation_sessions').doc('s1').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(staleDay),
      });

      final streak = await analyticsService.getCurrentStreak(userId);
      expect(streak, 0);
    });

    test('hasMeditatedToday returns true when a completed session exists today', () async {
      final userId = 'user-today';
      final today = DateTime.now();

      await fakeFirestore.collection('meditation_sessions').doc('s1').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(today),
      });

      final result = await analyticsService.hasMeditatedToday(userId);
      expect(result, isTrue);
    });

    test('hasMeditatedToday uses summary metadata when available', () async {
      final userId = 'user-summary';
      final now = DateTime.now();
      final dayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('meditation_stats')
          .doc('summary')
          .set({
        'lastMeditationDay': dayKey,
        'currentStreak': 4,
      });

      final result = await analyticsService.hasMeditatedToday(userId);
      expect(result, isTrue);
    });

    test('getMeditationCalendar returns day-wise counts for last 30 days', () async {
      final userId = 'user-calendar';
      final now = DateTime.now();
      final inWindow = now.subtract(const Duration(days: 2));
      final old = now.subtract(const Duration(days: 40));
      final dayKey = DateTime(inWindow.year, inWindow.month, inWindow.day);

      await fakeFirestore.collection('meditation_sessions').doc('s1').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(inWindow),
      });
      await fakeFirestore.collection('meditation_sessions').doc('s2').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(inWindow.add(const Duration(hours: 3))),
      });
      await fakeFirestore.collection('meditation_sessions').doc('s3').set({
        'userId': userId,
        'completed': true,
        'startTime': Timestamp.fromDate(old),
      });

      final calendar = await analyticsService.getMeditationCalendar(userId);

      expect(calendar[dayKey], 2);
      expect(
        calendar.keys.any((d) => d.year == old.year && d.month == old.month && d.day == old.day),
        isFalse,
      );
    });

    test('updateStats increments sessions and keeps same-day streak stable', () async {
      final userId = 'user-update';

      await analyticsService.updateStats(userId, 10);
      await analyticsService.updateStats(userId, 15);

      final stats = await analyticsService.getStats(userId);
      expect(stats['totalSessions'], 2);
      expect(stats['totalMinutes'], 25);
      expect(stats['currentStreak'], 1);
      expect(stats['longestStreak'], 1);
    });
  });
}
