import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fy_project/services/firestore_service.dart';
import 'package:fy_project/models/user_model.dart';

void main() {
  group('FirestoreService Tests', () {
    late FirestoreService firestoreService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(firestore: fakeFirestore);
    });

    group('User CRUD Operations', () {
      test('createUser adds user to Firestore', () async {
        final user = UserModel(
          uid: 'test-uid-123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await firestoreService.createUser(user);

        final retrieved = await firestoreService.getUser(user.uid);
        expect(retrieved, isNotNull);
        expect(retrieved?.email, equals(user.email));
        expect(retrieved?.displayName, equals(user.displayName));
      });

      test('getUser returns null for non-existent user', () async {
        final user = await firestoreService.getUser('non-existent-id');
        expect(user, isNull);
      });

      test('updateUser modifies existing user data', () async {
        final user = UserModel(
          uid: 'test-uid-456',
          email: 'test@example.com',
          displayName: 'Original Name',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        await firestoreService.updateUser(user.uid, {
          'displayName': 'Updated Name',
        });

        final updated = await firestoreService.getUser(user.uid);
        expect(updated?.displayName, equals('Updated Name'));
      });

      test('deleteUser removes user from Firestore', () async {
        final user = UserModel(
          uid: 'test-uid-789',
          email: 'delete@example.com',
          displayName: 'Delete Me',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        await firestoreService.deleteUser(user.uid);

        final deleted = await firestoreService.getUser(user.uid);
        expect(deleted, isNull);
      });

      test('userExists returns true for existing user', () async {
        final user = UserModel(
          uid: 'exists-uid',
          email: 'exists@example.com',
          displayName: 'Exists',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        final exists = await firestoreService.userExists(user.uid);
        expect(exists, isTrue);
      });

      test('userExists returns false for non-existent user', () async {
        final exists = await firestoreService.userExists('ghost-uid');
        expect(exists, isFalse);
      });
    });

    group('User Stream', () {
      test('streamUser emits user data changes', () async {
        final user = UserModel(
          uid: 'stream-test-uid',
          email: 'stream@example.com',
          displayName: 'Stream Test',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        final stream = firestoreService.streamUser(user.uid);

        expect(stream, isA<Stream<UserModel?>>());

        final firstEmission = await stream.first;
        expect(firstEmission, isNotNull);
        expect(firstEmission?.uid, equals(user.uid));
      });
    });

    group('Daily Motive', () {
      test('saveDailyMotive stores motive for user', () async {
        const userId = 'motive-test-uid';
        const motive = 'Test your limits!';

        await firestoreService.saveDailyMotive(userId, motive);

        final retrieved = await firestoreService.getDailyMotive(userId);
        expect(retrieved, equals(motive));
      });

      test('getDailyMotive returns null for non-existent motive', () async {
        final motive = await firestoreService.getDailyMotive('no-motive-uid');
        expect(motive, isNull);
      });
    });

    group('Sleep Data', () {
      test('logSleepData stores sleep data for user', () async {
        const userId = 'sleep-uid';
        final date = DateTime(2026, 2, 24);
        final data = {'duration': 7.5, 'quality': 'good'};

        await firestoreService.logSleepData(userId, date, data);

        final retrieved = await firestoreService.getSleepData(userId, date);
        expect(retrieved, isNotNull);
        expect(retrieved!['duration'], equals(7.5));
      });

      test('getSleepData returns null when no data for date', () async {
        final result = await firestoreService.getSleepData(
          'no-sleep-uid',
          DateTime(2026, 1, 1),
        );
        expect(result, isNull);
      });
    });
  });
}
