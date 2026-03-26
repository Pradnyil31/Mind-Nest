import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/logger.dart';
import '../core/exceptions.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthenticationException(
        _mapAuthExceptionMessage(e),
        code: e.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AuthenticationException(
        'An error occurred. Please try again.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthenticationException(
        _mapAuthExceptionMessage(e),
        code: e.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AuthenticationException(
        'An error occurred. Please try again.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        appLogger.i('User canceled Google sign-in');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      appLogger.i('Google sign-in successful for user: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e, stackTrace) {
      appLogger.e(
        'Firebase Auth Error during Google sign-in',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthenticationException(
        'Google sign-in failed: ${e.message}',
        code: e.code,
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
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e, stackTrace) {
      throw AuthenticationException(
        'Sign out failed. Please try again.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e, stackTrace) {
      throw AuthenticationException(
        'Account deletion failed. Please try again.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, stackTrace) {
      throw AuthenticationException(
        _mapAuthExceptionMessage(e),
        code: e.code,
        originalError: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw AuthenticationException(
        'Failed to send password reset email.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _mapAuthExceptionMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
