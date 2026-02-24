import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fy_project/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: false);
      authService = AuthService(auth: mockAuth);
    });

    group('Email Authentication', () {
      test('signUpWithEmail creates new user successfully', () async {
        const email = 'newuser@example.com';
        const password = 'Test123!@#';

        final result = await authService.signUpWithEmail(
          email: email,
          password: password,
        );

        expect(result, isNotNull);
        expect(result?.user?.email, equals(email));
      });

      test('signUpWithEmail sets current user after sign up', () async {
        final auth = MockFirebaseAuth(signedIn: false);
        final service = AuthService(auth: auth);

        await service.signUpWithEmail(
          email: 'signed@example.com',
          password: 'Test123!@#',
        );

        expect(service.currentUser, isNotNull);
      });

      test('signInWithEmail signs in existing user', () async {
        // First sign up to register the user in mock
        await mockAuth.createUserWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'Test123!@#',
        );

        final result = await authService.signInWithEmail(
          email: 'existing@example.com',
          password: 'Test123!@#',
        );

        expect(result, isNotNull);
      });
    });

    group('Auth State', () {
      test('authStateChanges stream is a Stream', () {
        final stream = authService.authStateChanges;
        expect(stream, isA<Stream>());
      });

      test('currentUser returns null when not signed in', () {
        expect(authService.currentUser, isNull);
      });

      test('currentUser returns user when signed in', () async {
        final signedInAuth = MockFirebaseAuth(signedIn: true);
        final signedInService = AuthService(auth: signedInAuth);

        expect(signedInService.currentUser, isNotNull);
      });

      test('authStateChanges emits a value', () async {
        final stream = authService.authStateChanges;
        final value = await stream.first;
        // When not signed in, emits null
        expect(value, isNull);
      });
    });

    group('Password Reset', () {
      test('sendPasswordResetEmail completes for valid email format', () async {
        const email = 'test@example.com';

        await expectLater(
          authService.sendPasswordResetEmail(email),
          completes,
        );
      });
    });
  });
}
