import 'package:logger/logger.dart';

/// Global logger instance for the application
/// 
/// Usage:
/// ```dart
/// appLogger.i('Info message');
/// appLogger.w('Warning message');
/// appLogger.e('Error message', error: error, stackTrace: stackTrace);
/// appLogger.d('Debug message');
/// ```
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Should each log print contain a timestamp
  ),
);

/// Production logger with minimal output
final productionLogger = Logger(
  printer: SimplePrinter(),
  level: Level.warning, // Only show warnings and errors in production
);
