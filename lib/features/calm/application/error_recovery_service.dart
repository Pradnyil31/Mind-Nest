import 'dart:async';
import 'dart:developer' as developer;

/// Service for handling errors and implementing recovery strategies
/// across the calm tab enhancement system
class ErrorRecoveryService {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultDelay = Duration(seconds: 1);

  /// Executes an operation with automatic retry logic
  /// Uses exponential backoff for retry delays
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = _defaultMaxRetries,
    Duration delay = _defaultDelay,
    String? operationName,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final result = await operation();

        // Log successful retry if this wasn't the first attempt
        if (attempt > 0 && operationName != null) {
          developer.log(
            'Operation "$operationName" succeeded on attempt ${attempt + 1}',
            name: 'ErrorRecoveryService',
          );
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Don't retry on the last attempt
        if (attempt == maxRetries - 1) {
          developer.log(
            'Operation "${operationName ?? 'unknown'}" failed after $maxRetries attempts: $e',
            name: 'ErrorRecoveryService',
            error: e,
          );
          break;
        }

        // Calculate exponential backoff delay
        final retryDelay = delay * (attempt + 1);

        developer.log(
          'Operation "${operationName ?? 'unknown'}" failed on attempt ${attempt + 1}, retrying in ${retryDelay.inMilliseconds}ms: $e',
          name: 'ErrorRecoveryService',
        );

        await Future.delayed(retryDelay);
      }
    }

    throw lastException ??
        Exception('Operation failed after $maxRetries attempts');
  }

  /// Executes an operation with a timeout and fallback
  Future<T> withTimeout<T>(
    Future<T> Function() operation,
    T fallback, {
    Duration timeout = const Duration(seconds: 10),
    String? operationName,
  }) async {
    try {
      return await operation().timeout(timeout);
    } catch (e) {
      developer.log(
        'Operation "${operationName ?? 'unknown'}" timed out or failed, using fallback: $e',
        name: 'ErrorRecoveryService',
        error: e,
      );
      return fallback;
    }
  }

  /// Executes an operation with circuit breaker pattern
  /// Prevents cascading failures by temporarily disabling failing operations
  Future<T?> withCircuitBreaker<T>(
    Future<T> Function() operation, {
    required String circuitName,
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(minutes: 1),
  }) async {
    final circuit = _CircuitBreaker.getInstance(
      circuitName,
      failureThreshold: failureThreshold,
      resetTimeout: resetTimeout,
    );

    return await circuit.execute(operation);
  }

  /// Handles network connectivity errors with graceful degradation
  Future<T> handleNetworkError<T>(
    Future<T> Function() networkOperation,
    T Function() offlineFallback, {
    String? operationName,
  }) async {
    try {
      return await networkOperation();
    } on NetworkException catch (e) {
      developer.log(
        'Network error for "${operationName ?? 'unknown'}", using offline fallback: $e',
        name: 'ErrorRecoveryService',
      );
      return offlineFallback();
    } catch (e) {
      developer.log(
        'Unexpected error for "${operationName ?? 'unknown'}", using offline fallback: $e',
        name: 'ErrorRecoveryService',
        error: e,
      );
      return offlineFallback();
    }
  }

  /// Validates data integrity before operations
  bool validateDataIntegrity<T>(T data, bool Function(T) validator) {
    try {
      return validator(data);
    } catch (e) {
      developer.log(
        'Data validation failed: $e',
        name: 'ErrorRecoveryService',
        error: e,
      );
      return false;
    }
  }

  /// Provides safe defaults when configuration is invalid
  T getSafeDefault<T>(
    T Function() getter,
    T defaultValue, {
    String? configName,
  }) {
    try {
      return getter();
    } catch (e) {
      developer.log(
        'Configuration "${configName ?? 'unknown'}" failed, using default: $e',
        name: 'ErrorRecoveryService',
      );
      return defaultValue;
    }
  }
}

/// Circuit breaker implementation for preventing cascading failures
class _CircuitBreaker {
  static final Map<String, _CircuitBreaker> _instances = {};

  final String name;
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  _CircuitState _state = _CircuitState.closed;

  _CircuitBreaker._(
    this.name, {
    required this.failureThreshold,
    required this.resetTimeout,
  });

  static _CircuitBreaker getInstance(
    String name, {
    required int failureThreshold,
    required Duration resetTimeout,
  }) {
    return _instances.putIfAbsent(
      name,
      () => _CircuitBreaker._(
        name,
        failureThreshold: failureThreshold,
        resetTimeout: resetTimeout,
      ),
    );
  }

  Future<T?> execute<T>(Future<T> Function() operation) async {
    if (_state == _CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = _CircuitState.halfOpen;
      } else {
        developer.log(
          'Circuit breaker "$name" is open, operation blocked',
          name: 'CircuitBreaker',
        );
        return null;
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = _CircuitState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = _CircuitState.open;
      developer.log(
        'Circuit breaker "$name" opened after $_failureCount failures',
        name: 'CircuitBreaker',
      );
    }
  }
}

enum _CircuitState { closed, open, halfOpen }

/// Custom exception types for better error handling
class NetworkException implements Exception {
  final String message;
  final Exception? originalException;

  const NetworkException(this.message, [this.originalException]);

  @override
  String toString() => 'NetworkException: $message';
}

class AudioPlaybackException implements Exception {
  final String message;
  final String? audioFile;
  final Exception? originalException;

  const AudioPlaybackException(
    this.message, [
    this.audioFile,
    this.originalException,
  ]);

  @override
  String toString() =>
      'AudioPlaybackException: $message${audioFile != null ? ' (file: $audioFile)' : ''}';
}

class DataIntegrityException implements Exception {
  final String message;
  final String? dataType;

  const DataIntegrityException(this.message, [this.dataType]);

  @override
  String toString() =>
      'DataIntegrityException: $message${dataType != null ? ' (type: $dataType)' : ''}';
}

class MotiveConfigurationException implements Exception {
  final String message;
  final String? motive;

  const MotiveConfigurationException(this.message, [this.motive]);

  @override
  String toString() =>
      'MotiveConfigurationException: $message${motive != null ? ' (motive: $motive)' : ''}';
}
