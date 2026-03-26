/// Base exception class for all app-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => message;
}

/// Network-related exceptions (connectivity, timeouts, etc.)
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Firestore database exceptions
class FirestoreException extends AppException {
  FirestoreException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Goal-related exceptions
class GoalException extends AppException {
  GoalException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Journal-related exceptions
class JournalException extends AppException {
  JournalException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Chat service exceptions
class ChatException extends AppException {
  ChatException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
