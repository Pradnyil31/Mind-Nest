import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fy_project/providers/auth_provider.dart';
import 'package:fy_project/services/auth_service.dart';

void main() {
  group('Auth Provider Tests', () {
    late MockFirebaseAuth mockAuth;
    late ProviderContainer container;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: false);

      // Override the authServiceProvider with a mock-based AuthService
      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService(auth: mockAuth)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('authStateProvider emits AsyncValue', () {
      final authState = container.read(authStateProvider);
      expect(authState, isA<AsyncValue>());
    });

    test('currentUserProvider returns null when not signed in', () {
      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isNull);
    });

    test('authServiceProvider provides AuthService instance', () {
      final authService = container.read(authServiceProvider);
      expect(authService, isNotNull);
      expect(authService, isA<AuthService>());
    });

    test('authStateProvider returns loading or data, not error', () {
      final authState = container.read(authStateProvider);
      // Should be loading (AsyncLoading) or data, never an error
      authState.when(
        data: (user) => expect(user, isNull),
        loading: () => expect(true, isTrue),
        error: (e, _) => fail('authStateProvider should not emit error: $e'),
      );
    });
  });
}
