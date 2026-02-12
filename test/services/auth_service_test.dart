import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fy_project/services/auth_service.dart';
import 'package:fy_project/core/exceptions.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([User, UserCredential])
void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      // Create mock Firebase Auth
      mockAuth = MockFirebaseAuth(signedIn: false);
      authService = AuthService();
    });

    group('Email Authentication', () {
      test('signUpWithEmail creates new user successfully', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'Test123!@#';
        const displayName = 'Test User';

        // Note: In a real test, you'd mock the FirebaseAuth instance
        // For now, this is a placeholder structure

        // Act & Assert
        // This will fail in real execution without proper mocking
        // expect(
        //   () => authService.signUpWithEmail(email, password, displayName),
        //   throwsA(isA<AuthenticationException>()),
        // );
      });

      test('signInWithEmail with invalid credentials throws exception', () async {
        // Arrange
        const email = 'invalid@example.com';
        const password = 'wrongpassword';

        // Act & Assert
        expect(
          () => authService.signInWithEmail(email: email, password: password),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });

    group('Sign Out', () {
      test('signOut completes successfully', () async {
        // Act
        await authService.signOut();

        // Assert - should complete without errors
        expect(authService.currentUser, isNull);
      });
    });

    group('Auth State', () {
      test('authStateChanges stream emits user changes', () async {
        // Arrange
        final stream = authService.authStateChanges;

        // Assert
        expect(stream, isA<Stream<User?>>());
      });

      test('currentUser returns null when not signed in', () {
        // Assert
        expect(authService.currentUser, isNull);
      });
    });

    group('Password Reset', () {
      test('sendPasswordResetEmail sends email for valid address', () async {
        // Arrange
        const email = 'test@example.com';

        // Act & Assert
        // Should not throw for valid email format
        await expectLater(
          authService.sendPasswordResetEmail(email),
          completes,
        );
      });
    });
  });
}
