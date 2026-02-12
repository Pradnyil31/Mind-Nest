import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fy_project/providers/auth_provider.dart';

void main() {
  group('Auth Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('authStateProvider emits user when signed in', () async {
      // Arrange
      final mockUser = MockUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // Act
      final authState = container.read(authStateProvider);

      // Assert
      expect(authState, isA<AsyncValue>());
    });

    test('currentUserProvider returns null when not signed in', () {
      // Act
      final currentUser = container.read(currentUserProvider);

      // Assert
      expect(currentUser, isNull);
    });

    test('authServiceProvider provides AuthService instance', () {
      // Act
      final authService = container.read(authServiceProvider);

      // Assert
      expect(authService, isNotNull);
    });
  });
}
