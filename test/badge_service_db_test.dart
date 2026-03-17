import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fy_project/services/badge_service.dart';
import 'package:fy_project/services/firestore_service.dart';
import 'package:fy_project/services/routine_tracking_service.dart';
import 'package:fy_project/services/meditation_analytics_service.dart';

void main() {
  group('BadgeService Database Validation', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BadgeService badgeService;
    late FirestoreService firestoreService;
    const String testUserId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
      
      badgeService = BadgeService(
        firestore: fakeFirestore,
        firestoreService: firestoreService,
        routineService: RoutineTrackingService(firestore: fakeFirestore),
        meditationAnalytics: MeditationAnalyticsService(firestore: fakeFirestore),
      );
    });

    test('Awards Journal Warrior badge when 15 entries are completed and writes to DB', () async {
      // 1. Setup initial data: simulate user having completed 15 journal entries
      await fakeFirestore
          .collection('users')
          .doc(testUserId)
          .collection('activity_stats')
          .doc('journaling')
          .set({
        'completionCount': 15,
        'lastCompleted': FieldValue.serverTimestamp(),
      });

      // 2. Execute badge check logic
      final newBadges = await badgeService.checkAndAwardBadges(testUserId);

      // 3. Verify returned value
      expect(newBadges.length, 1);
      final unlockedBadge = newBadges.first;
      expect(unlockedBadge.id, 'journal_warrior');
      expect(unlockedBadge.name, 'Journal Warrior');

      // 4. VERIFY DB WRITE: Check that the badge was actually written to the earned subcollection
      final earnedSnapshot = await fakeFirestore
          .collection('badges')
          .doc(testUserId)
          .collection('earned')
          .doc('journal_warrior')
          .get();

      // Assert data integrity in the database
      expect(earnedSnapshot.exists, true, reason: 'Badge document should exist in Firestore');
      
      final dbData = earnedSnapshot.data()!;
      expect(dbData['badgeId'], 'journal_warrior');
      expect(dbData['badgeName'], 'Journal Warrior');
      // Assert earnedDate is stored as a Timestamp instance properly
      expect(dbData['earnedDate'], isA<Timestamp>());
      
      // 5. Verify subsequent calls don't award it again
      final earnedAgain = await badgeService.checkAndAwardBadges(testUserId);
      expect(earnedAgain.isEmpty, true);

      // 6. Verify read works independently
      final allEarnedIds = await badgeService.getEarnedBadgeIds(testUserId);
      expect(allEarnedIds.contains('journal_warrior'), true);
    });
    
    test('Awards Goal Crusher badge when 3 goals are completed and writes to DB', () async {
      // 1. Setup initial data: simulate user having completed 3 goals
      for (int i = 0; i < 3; i++) {
        await fakeFirestore.collection('smart_goals').add({
          'userId': testUserId,
          'isCompleted': true,
        });
      }

      // 2. Execute badge check logic
      final newBadges = await badgeService.checkAndAwardBadges(testUserId);

      // 3. Verify returned value
      expect(newBadges.length, 1);
      final unlockedBadge = newBadges.first;
      expect(unlockedBadge.id, 'goal_crusher');
      expect(unlockedBadge.name, 'Goal Crusher');

      // 4. VERIFY DB WRITE: Check that the badge was actually written to the earned subcollection
      final earnedSnapshot = await fakeFirestore
          .collection('badges')
          .doc(testUserId)
          .collection('earned')
          .doc('goal_crusher')
          .get();

      // Assert data integrity in the database
      expect(earnedSnapshot.exists, true, reason: 'Badge document should exist in Firestore');
      
      final dbData = earnedSnapshot.data()!;
      expect(dbData['badgeId'], 'goal_crusher');
      expect(dbData['badgeName'], 'Goal Crusher');
      // Assert earnedDate is stored as a Timestamp instance properly
      expect(dbData['earnedDate'], isA<Timestamp>());
    });
  });
}
