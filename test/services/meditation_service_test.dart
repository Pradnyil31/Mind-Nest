import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/services/meditation_service.dart';

void main() {
  group('MeditationService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MeditationService meditationService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      meditationService = MeditationService(firestore: fakeFirestore);
    });

    test('getTotalSessionCount reads from summary doc when available', () async {
      const userId = 'summary-user';
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('meditation_stats')
          .doc('summary')
          .set({'totalSessions': 42, 'totalMinutes': 900});

      final count = await meditationService.getTotalSessionCount(userId);
      expect(count, 42);
    });

    test('getTotalMinutes reads from summary doc when available', () async {
      const userId = 'summary-user';
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('meditation_stats')
          .doc('summary')
          .set({'totalSessions': 10, 'totalMinutes': 321});

      final minutes = await meditationService.getTotalMinutes(userId);
      expect(minutes, 321);
    });

    test('getTotalSessionCount falls back to sessions query when summary is missing', () async {
      const userId = 'fallback-user';
      await fakeFirestore.collection('meditation_sessions').doc('a').set({
        'userId': userId,
        'completed': true,
        'durationMinutes': 10,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });
      await fakeFirestore.collection('meditation_sessions').doc('b').set({
        'userId': userId,
        'completed': true,
        'durationMinutes': 15,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });
      await fakeFirestore.collection('meditation_sessions').doc('c').set({
        'userId': userId,
        'completed': false,
        'durationMinutes': 99,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });

      final count = await meditationService.getTotalSessionCount(userId);
      expect(count, 2);
    });

    test('getTotalMinutes falls back to sessions query when summary is missing', () async {
      const userId = 'fallback-user';
      await fakeFirestore.collection('meditation_sessions').doc('a').set({
        'userId': userId,
        'completed': true,
        'durationMinutes': 10,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });
      await fakeFirestore.collection('meditation_sessions').doc('b').set({
        'userId': userId,
        'completed': true,
        'durationMinutes': 15,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });
      await fakeFirestore.collection('meditation_sessions').doc('c').set({
        'userId': userId,
        'completed': false,
        'durationMinutes': 999,
        'startTime': Timestamp.fromDate(DateTime.now()),
      });

      final minutes = await meditationService.getTotalMinutes(userId);
      expect(minutes, 25);
    });
  });
}
