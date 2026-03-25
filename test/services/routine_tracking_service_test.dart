import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/services/routine_tracking_service.dart';

void main() {
  group('RoutineTrackingService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RoutineTrackingService service;
    const userId = 'u1';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = RoutineTrackingService(firestore: fakeFirestore);
    });

    Future<void> seedCompletion({
      required DateTime date,
      required List<String> completed,
      int total = 5,
    }) async {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await fakeFirestore.collection('routine_completions').doc('${userId}_$key').set({
        'id': '${userId}_$key',
        'userId': userId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'completedActivities': completed,
        'totalActivities': total,
      });
    }

    test('hasAnyCompletedActivityToday returns true when today has completed items', () async {
      final now = DateTime.now();
      await seedCompletion(date: now, completed: ['Meditation']);

      final hasAny = await service.hasAnyCompletedActivityToday(userId);

      expect(hasAny, isTrue);
    });

    test('getTodayCompletionSummary returns zero values when no doc exists', () async {
      final summary = await service.getTodayCompletionSummary(userId);

      expect(summary['completed'], 0);
      expect(summary['total'], 0);
    });

    test('getActiveDaysThisWeek returns weekdays that have any completion', () async {
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - DateTime.monday));
      final wednesday = monday.add(const Duration(days: 2));

      await seedCompletion(date: monday, completed: ['Breathing']);
      await seedCompletion(date: wednesday, completed: ['Journal']);

      final activeDays = await service.getActiveDaysThisWeek(userId);

      expect(activeDays.contains(DateTime.monday), isTrue);
      expect(activeDays.contains(DateTime.wednesday), isTrue);
    });

    test('getCompletionStreak returns consecutive streak from today backwards', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await seedCompletion(date: today, completed: ['A']);
      await seedCompletion(
        date: today.subtract(const Duration(days: 1)),
        completed: ['B'],
      );
      await seedCompletion(
        date: today.subtract(const Duration(days: 2)),
        completed: ['C'],
      );
      await seedCompletion(
        date: today.subtract(const Duration(days: 4)),
        completed: ['Gap'],
      );

      final streak = await service.getCompletionStreak(userId);

      expect(streak, 3);
    });
  });
}
