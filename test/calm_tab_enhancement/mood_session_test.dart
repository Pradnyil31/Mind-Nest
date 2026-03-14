import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fy_project/features/calm/models/mood_session.dart';

void main() {
  group('MoodSession', () {
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

    test('should handle incomplete session correctly', () {
      final doc = FakeDocumentSnapshot('session-id', {
        'userId': 'test-user',
        'techniqueId': '5-4-3-2-1',
        'preMoodRating': 4,
        'postMoodRating': null,
        'startTime': Timestamp.now(),
        'endTime': null,
        'moodImprovement': null,
      });

      final session = MoodSession.fromFirestore(doc);

      expect(session.isComplete, isFalse);
      expect(session.postMoodRating, isNull);
      expect(session.moodImprovement, isNull);
      expect(session.duration, isNull);
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

    test('should calculate negative improvement percentage correctly', () {
      final session = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        preMoodRating: 7,
        postMoodRating: 4,
        startTime: DateTime.now(),
        moodImprovement: -3,
      );

      // Decline from 7 to 4 is -3 out of possible -6 (7-1)
      // So percentage should be (-3/-6) * 100 = 50%
      expect(session.improvementPercentage, closeTo(50.0, 0.01));
    });

    test('should handle zero improvement correctly', () {
      final session = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        preMoodRating: 5,
        postMoodRating: 5,
        startTime: DateTime.now(),
        moodImprovement: 0,
      );

      expect(session.improvementPercentage, equals(0.0));
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

      final slightDecline = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: -2,
      );
      expect(slightDecline.improvementDescription, equals('Slight decline'));

      final significantDecline = MoodSession(
        id: 'test',
        userId: 'user',
        techniqueId: 'technique',
        startTime: DateTime.now(),
        moodImprovement: -5,
      );
      expect(
        significantDecline.improvementDescription,
        equals('Significant decline'),
      );
    });

    test('should convert to Firestore format correctly', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 5));

      final session = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        postMoodRating: 7,
        startTime: startTime,
        endTime: endTime,
        moodImprovement: 3,
      );

      final firestoreData = session.toFirestore();

      expect(firestoreData['userId'], equals('test-user'));
      expect(firestoreData['techniqueId'], equals('5-4-3-2-1'));
      expect(firestoreData['preMoodRating'], equals(4));
      expect(firestoreData['postMoodRating'], equals(7));
      expect(firestoreData['moodImprovement'], equals(3));
      expect(firestoreData['startTime'], isA<Timestamp>());
      expect(firestoreData['endTime'], isA<Timestamp>());
    });

    test('should calculate duration correctly', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 5));

      final session = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        startTime: startTime,
        endTime: endTime,
      );

      expect(session.duration, equals(const Duration(minutes: 5)));
    });

    test('should handle copyWith correctly', () {
      final original = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        startTime: DateTime.now(),
      );

      final updated = original.copyWith(postMoodRating: 7, moodImprovement: 3);

      expect(updated.id, equals(original.id));
      expect(updated.userId, equals(original.userId));
      expect(updated.techniqueId, equals(original.techniqueId));
      expect(updated.preMoodRating, equals(original.preMoodRating));
      expect(updated.postMoodRating, equals(7));
      expect(updated.moodImprovement, equals(3));
    });

    test('should handle equality correctly', () {
      final startTime = DateTime.now();

      final session1 = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        startTime: startTime,
      );

      final session2 = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        startTime: startTime,
      );

      final session3 = MoodSession(
        id: 'different-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        startTime: startTime,
      );

      expect(session1, equals(session2));
      expect(session1, isNot(equals(session3)));
      expect(session1.hashCode, equals(session2.hashCode));
      expect(session1.hashCode, isNot(equals(session3.hashCode)));
    });

    test('should handle toString correctly', () {
      final session = MoodSession(
        id: 'test-id',
        userId: 'test-user',
        techniqueId: '5-4-3-2-1',
        preMoodRating: 4,
        postMoodRating: 7,
        startTime: DateTime.now(),
        moodImprovement: 3,
      );

      final string = session.toString();

      expect(string, contains('test-id'));
      expect(string, contains('test-user'));
      expect(string, contains('5-4-3-2-1'));
      expect(string, contains('4'));
      expect(string, contains('7'));
      expect(string, contains('3'));
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
