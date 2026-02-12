import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fy_project/services/firestore_service.dart';
import 'package:fy_project/models/user_model.dart';

void main() {
  group('FirestoreService Tests', () {
    late FirestoreService firestoreService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // Note: You'd need to pass fakeFirestore to FirestoreService
      // For now, using default instance
      firestoreService = FirestoreService();
    });

    group('User CRUD Operations', () {
      test('createUser adds user to Firestore', () async {
        // Arrange
        final user = UserModel(
          uid: 'test-uid-123',
          email: 'test@example.com',
          displayName: 'Test User',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        // Act
        await firestoreService.createUser(user);

        // Assert
        final retrieved = await firestoreService.getUser(user.uid);
        expect(retrieved, isNotNull);
        expect(retrieved?.email, equals(user.email));
        expect(retrieved?.displayName, equals(user.displayName));
      });

      test('getUser returns null for non-existent user', () async {
        // Act
        final user = await firestoreService.getUser('non-existent-id');

        // Assert
        expect(user, isNull);
      });

      test('updateUser modifies existing user data', () async {
        // Arrange
        final user = UserModel(
          uid: 'test-uid-456',
          email: 'test@example.com',
          displayName: 'Original Name',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        // Act
        await firestoreService.updateUser(user.uid, {
          'displayName': 'Updated Name',
        });

        // Assert
        final updated = await firestoreService.getUser(user.uid);
        expect(updated?.displayName, equals('Updated Name'));
      });

      test('deleteUser removes user from Firestore', () async {
        // Arrange
        final user = UserModel(
          uid: 'test-uid-789',
          email: 'delete@example.com',
          displayName: 'Delete Me',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        // Act
        await firestoreService.deleteUser(user.uid);

        // Assert
        final deleted = await firestoreService.getUser(user.uid);
        expect(deleted, isNull);
      });
    });

    group('User Stream', () {
      test('streamUser emits user data changes', () async {
        // Arrange
        final user = UserModel(
          uid: 'stream-test-uid',
          email: 'stream@example.com',
          displayName: 'Stream Test',
          photoURL: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await firestoreService.createUser(user);

        // Act
        final stream = firestoreService.streamUser(user.uid);

        // Assert
        expect(stream, isA<Stream<UserModel?>>());
        
        // Listen to first emission
        final firstEmission = await stream.first;
        expect(firstEmission, isNotNull);
        expect(firstEmission?.uid, equals(user.uid));
      });
    });

    group('Daily Motive', () {
      test('saveDailyMotive stores motive for user', () async {
        // Arrange
        const userId = 'motive-test-uid';
        const motive = 'Test your limits!';

        // Act
        await firestoreService.saveDailyMotive(userId, motive);

        // Assert
        final retrieved = await firestoreService.getDailyMotive(userId);
        expect(retrieved, equals(motive));
      });

      test('getDailyMotive returns null for non-existent motive', () async {
        // Act
        final motive = await firestoreService.getDailyMotive('no-motive-uid');

        // Assert
        expect(motive, isNull);
      });
    });
  });
}
