// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fy_project/features/calm/application/mood_tracking_service.dart';
import 'package:fy_project/features/calm/models/mood_session.dart';

/// Test-specific MoodTrackingService that allows firestore injection
class TestMoodTrackingService extends MoodTrackingService {
  final FirebaseFirestore testFirestore;

  TestMoodTrackingService(this.testFirestore);

  // ignore: unused_element
  CollectionReference get _moodSessionsCollection =>
      testFirestore.collection('mood_sessions');

  // ignore: unused_element
  FirebaseFirestore get _firestore => testFirestore;
}

void main() {
  group('MoodTrackingService', () {
    late TestMoodTrackingService moodTrackingService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      moodTrackingService = TestMoodTrackingService(fakeFirestore);
    });

    group('recordPreMood', () {
      test('should create mood session with pre-mood rating', () async {
        const userId = 'test-user';
        const techniqueId = '5-4-3-2-1';
        const rating = 6;

        final sessionId = await moodTrackingService.recordPreMood(
          userId,
          techniqueId,
          rating,
        );

        expect(sessionId, isNotEmpty);

        // Verify session was created in Firestore
        final doc = await fakeFirestore
            .collection('mood_sessions')
            .doc(sessionId)
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['userId'], equals(userId));
        expect(data['techniqueId'], equals(techniqueId));
        expect(data['preMoodRating'], equals(rating));
        expect(data['postMoodRating'], isNull);
        expect(data['moodImprovement'], isNull);
        expect(data['startTime'], isNotNull);
      });

      test('should throw error for invalid rating', () async {
        expect(
          () => moodTrackingService.recordPreMood('user', 'technique', 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => moodTrackingService.recordPreMood('user', 'technique', 11),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('recordPostMood', () {
      test(
        'should update session with post-mood rating and calculate improvement',
        () async {
          const userId = 'test-user';
          const techniqueId = '5-4-3-2-1';
          const preMoodRating = 4;
          const postMoodRating = 7;

          // First create a pre-mood session
          final sessionId = await moodTrackingService.recordPreMood(
            userId,
            techniqueId,
            preMoodRating,
          );

          // Then record post-mood
          await moodTrackingService.recordPostMood(sessionId, postMoodRating);

          // Verify session was updated
          final doc = await fakeFirestore
              .collection('mood_sessions')
              .doc(sessionId)
              .get();

          final data = doc.data()!;
          expect(data['postMoodRating'], equals(postMoodRating));
          expect(data['moodImprovement'], equals(3)); // 7 - 4 = 3
          expect(data['endTime'], isNotNull);
        },
      );

      test('should throw error for non-existent session', () async {
        expect(
          () => moodTrackingService.recordPostMood('non-existent', 5),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error for invalid rating', () async {
        const sessionId = 'test-session';

        expect(
          () => moodTrackingService.recordPostMood(sessionId, 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => moodTrackingService.recordPostMood(sessionId, 11),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getMoodTrends', () {
      test('should return empty trends for user with no data', () async {
        const userId = 'new-user';

        final trends = await moodTrackingService.getMoodTrends(userId);

        expect(trends['totalSessions'], equals(0));
        expect(trends['averageImprovement'], equals(0.0));
        expect(trends['improvementTrend'], isEmpty);
        expect(trends['bestTechniques'], isEmpty);
        expect(trends['recentSessions'], isEmpty);
      });

      test('should calculate trends correctly for user with data', () async {
        const userId = 'test-user';

        // Create multiple completed sessions
        final sessions = [
          {'techniqueId': '5-4-3-2-1', 'preMood': 3, 'postMood': 7}, // +4
          {'techniqueId': 'worry-banking', 'preMood': 5, 'postMood': 6}, // +1
          {'techniqueId': '5-4-3-2-1', 'preMood': 4, 'postMood': 8}, // +4
        ];

        for (final session in sessions) {
          final sessionId = await moodTrackingService.recordPreMood(
            userId,
            session['techniqueId'] as String,
            session['preMood'] as int,
          );
          await moodTrackingService.recordPostMood(
            sessionId,
            session['postMood'] as int,
          );
        }

        final trends = await moodTrackingService.getMoodTrends(userId);

        expect(trends['totalSessions'], equals(3));
        expect(trends['averageImprovement'], equals(3.0)); // (4+1+4)/3 = 3
        expect(trends['improvementTrend'], hasLength(3));
        expect(trends['bestTechniques'], isNotEmpty);

        // Check that 5-4-3-2-1 is the most effective (average 4.0)
        final bestTechniques =
            trends['bestTechniques'] as List<Map<String, dynamic>>;
        expect(bestTechniques.first['techniqueId'], equals('5-4-3-2-1'));
        expect(bestTechniques.first['averageImprovement'], equals(4.0));
      });
    });

    group('getAverageMoodImprovement', () {
      test('should return 0.0 for user with no data', () async {
        const userId = 'new-user';

        final average = await moodTrackingService.getAverageMoodImprovement(
          userId,
        );

        expect(average, equals(0.0));
      });

      test('should calculate average improvement correctly', () async {
        const userId = 'test-user';

        // Create sessions with improvements: +3, +1, -2
        final sessions = [
          {'techniqueId': 'technique1', 'preMood': 4, 'postMood': 7}, // +3
          {'techniqueId': 'technique2', 'preMood': 5, 'postMood': 6}, // +1
          {'techniqueId': 'technique3', 'preMood': 6, 'postMood': 4}, // -2
        ];

        for (final session in sessions) {
          final sessionId = await moodTrackingService.recordPreMood(
            userId,
            session['techniqueId'] as String,
            session['preMood'] as int,
          );
          await moodTrackingService.recordPostMood(
            sessionId,
            session['postMood'] as int,
          );
        }

        final average = await moodTrackingService.getAverageMoodImprovement(
          userId,
        );

        expect(average, closeTo(0.67, 0.01)); // (3+1-2)/3 ≈ 0.67
      });
    });

    group('getTechniqueEffectiveness', () {
      test('should return empty map for user with no data', () async {
        const userId = 'new-user';

        final effectiveness = await moodTrackingService
            .getTechniqueEffectiveness(userId);

        expect(effectiveness, isEmpty);
      });

      test('should calculate technique effectiveness correctly', () async {
        const userId = 'test-user';

        // Create sessions for different techniques
        final sessions = [
          {'techniqueId': '5-4-3-2-1', 'preMood': 3, 'postMood': 8}, // +5
          {'techniqueId': '5-4-3-2-1', 'preMood': 4, 'postMood': 7}, // +3
          {'techniqueId': 'worry-banking', 'preMood': 5, 'postMood': 6}, // +1
        ];

        for (final session in sessions) {
          final sessionId = await moodTrackingService.recordPreMood(
            userId,
            session['techniqueId'] as String,
            session['preMood'] as int,
          );
          await moodTrackingService.recordPostMood(
            sessionId,
            session['postMood'] as int,
          );
        }

        final effectiveness = await moodTrackingService
            .getTechniqueEffectiveness(userId);

        expect(effectiveness['5-4-3-2-1'], equals(4.0)); // (5+3)/2 = 4.0
        expect(effectiveness['worry-banking'], equals(1.0));
      });
    });

    group('hasAnyMoodData', () {
      test('should return false for user with no data', () async {
        const userId = 'new-user';

        final hasData = await moodTrackingService.hasAnyMoodData(userId);

        expect(hasData, isFalse);
      });

      test('should return true for user with data', () async {
        const userId = 'test-user';

        await moodTrackingService.recordPreMood(userId, 'technique', 5);

        final hasData = await moodTrackingService.hasAnyMoodData(userId);

        expect(hasData, isTrue);
      });
    });

    group('deleteUserMoodData', () {
      test('should delete all mood data for user', () async {
        const userId = 'test-user';

        // Create multiple sessions
        await moodTrackingService.recordPreMood(userId, 'technique1', 5);
        await moodTrackingService.recordPreMood(userId, 'technique2', 6);

        // Verify data exists
        expect(await moodTrackingService.hasAnyMoodData(userId), isTrue);

        // Delete data
        await moodTrackingService.deleteUserMoodData(userId);

        // Verify data is gone
        expect(await moodTrackingService.hasAnyMoodData(userId), isFalse);
      });
    });

    group('getMoodStatsForPeriod', () {
      test('should return empty stats for user with no data', () async {
        const userId = 'new-user';

        final stats = await moodTrackingService.getMoodStatsForPeriod(
          userId,
          7,
        );

        expect(stats['sessionsCount'], equals(0));
        expect(stats['averageImprovement'], equals(0.0));
        expect(stats['bestDay'], isNull);
        expect(stats['totalImprovement'], equals(0));
      });

      test('should calculate period stats correctly', () async {
        const userId = 'test-user';

        // Create sessions with improvements: +3, +2
        final sessions = [
          {'techniqueId': 'technique1', 'preMood': 4, 'postMood': 7}, // +3
          {'techniqueId': 'technique2', 'preMood': 5, 'postMood': 7}, // +2
        ];

        for (final session in sessions) {
          final sessionId = await moodTrackingService.recordPreMood(
            userId,
            session['techniqueId'] as String,
            session['preMood'] as int,
          );
          await moodTrackingService.recordPostMood(
            sessionId,
            session['postMood'] as int,
          );
        }

        final stats = await moodTrackingService.getMoodStatsForPeriod(
          userId,
          7,
        );

        expect(stats['sessionsCount'], equals(2));
        expect(stats['averageImprovement'], equals(2.5)); // (3+2)/2 = 2.5
        expect(stats['totalImprovement'], equals(5)); // 3+2 = 5
        expect(stats['bestDay'], isNotNull);
      });
    });

    group('getRecentSessions stream', () {
      test('should return stream of recent sessions', () async {
        const userId = 'test-user';

        // Create a session
        final sessionId = await moodTrackingService.recordPreMood(
          userId,
          '5-4-3-2-1',
          5,
        );
        await moodTrackingService.recordPostMood(sessionId, 8);

        final stream = moodTrackingService.getRecentSessions(userId, limit: 5);

        await expectLater(
          stream,
          emits(
            predicate<List<MoodSession>>((sessions) {
              return sessions.length == 1 &&
                  sessions.first.userId == userId &&
                  sessions.first.techniqueId == '5-4-3-2-1' &&
                  sessions.first.isComplete;
            }),
          ),
        );
      });
    });
  });

  group('MoodSession model', () {
    test('should create from Firestore document correctly', () {
      final doc = FakeDocumentSnapshot('session-id', {
        'userId': 'test-user',
        'techniqueId': '5-4-3-2-1',
        'preMoodRating': 4,
        'postMoodRating': 7,
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'moodImprovement': 3,
      });

      final session = MoodSession.fromFirestore(doc);

      expect(session.id, equals('session-id'));
      expect(session.userId, equals('test-user'));
      expect(session.techniqueId, equals('5-4-3-2-1'));
      expect(session.preMoodRating, equals(4));
      expect(session.postMoodRating, equals(7));
      expect(session.moodImprovement, equals(3));
      expect(session.isComplete, isTrue);
    });

    test('should calculate improvement percentage correctly', () {
      final session = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        preMoodRating: 3,
        postMoodRating: 7,
        startTime: DateTime.now(),
        moodImprovement: 4,
      );

      // Improvement from 3 to 7 is 4 out of possible 7 (10-3)
      // So percentage should be (4/7) * 100 ≈ 57.14%
      expect(session.improvementPercentage, closeTo(57.14, 0.01));
    });

    test('should provide correct improvement descriptions', () {
      final significantImprovement = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: 5,
      );
      expect(
        significantImprovement.improvementDescription,
        equals('Significant improvement'),
      );

      final mildImprovement = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: 2,
      );
      expect(
        mildImprovement.improvementDescription,
        equals('Mild improvement'),
      );

      final noChange = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: 0,
      );
      expect(noChange.improvementDescription, equals('No change'));

      final decline = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: -2,
      );
      expect(decline.improvementDescription, equals('Slight decline'));
    });
  });
}

/// Helper class to create fake Firestore document snapshots for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  dynamic get(Object field) => _data?[field];

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}
