import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loggerProvider = Provider<AppLogger>((ref) {
  throw UnimplementedError('Logger provider must be overridden');
});

class AppLogger {
  const AppLogger();

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARN', message, error, stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  void _log(String level, String message, Object? error, StackTrace? stackTrace) {
    final buffer = StringBuffer('[$level] $message');
    if (error != null) {
      buffer.write(' | error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    debugPrint(buffer.toString());
  }
}
