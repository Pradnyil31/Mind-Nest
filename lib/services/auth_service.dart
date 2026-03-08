import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../core/exceptions.dart';
import '../core/logger.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AppUser({required this.uid, this.email, this.displayName});

  factory AppUser.fromSupabase(User user) {
    return AppUser(
      uid: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
    );
  }
}

class AppUserCredential {
  final AppUser? user;

  const AppUserCredential({this.user});
}

class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client, Object? auth, Object? googleSignIn})
    : _client = client ?? SupabaseConfig.client;

  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser.fromSupabase(user);
  }

  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((_) {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return AppUser.fromSupabase(user);
    });
  }

  Future<AppUserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return AppUserCredential(
        user: response.user == null
            ? null
            : AppUser.fromSupabase(response.user!),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'An error occurred. Please try again.';
    }
  }

  Future<AppUserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AppUserCredential(
        user: response.user == null
            ? null
            : AppUser.fromSupabase(response.user!),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'An error occurred. Please try again.';
    }
  }

  Future<AppUserCredential?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      return null;
    } on AuthException catch (e, stackTrace) {
      appLogger.e(
        'Supabase auth error during Google sign-in',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthenticationException(
        'Google sign-in failed: ${e.message}',
        code: e.statusCode,
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      appLogger.e(
        'Unexpected error during Google sign-in',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthenticationException(
        'Google sign-in failed',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw 'Sign out failed. Please try again.';
    }
  }

  Future<void> deleteAccount() async {
    throw 'Account deletion is not available from client side yet.';
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (_) {
      throw 'Failed to send password reset email.';
    }
  }

  String _handleAuthException(AuthException e) {
    final code = e.statusCode;
    final message = e.message.toLowerCase();

    if (message.contains('already registered')) {
      return 'An account already exists for this email.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('password should be at least')) {
      return 'The password is too weak.';
    }
    if (message.contains('invalid email')) {
      return 'The email address is invalid.';
    }
    if (code == '429') {
      return 'Too many attempts. Please try again later.';
    }
    return 'Authentication failed. Please try again.';
  }
}
