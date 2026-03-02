// Professional Logging Framework for FriendsRide App
// Mirrors utils/logger.dart for use inside lib/ via package imports

import 'package:flutter/foundation.dart';

/// Log levels for different severity
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Professional logger for FriendsRide app
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;

  static void setMinLevel(LogLevel level) => _minLevel = level;
  static LogLevel get minLevel => _minLevel;

  static void debug(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.info, message, tag: tag);

  static void warning(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.warning, message, tag: tag);

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, tag: tag, error: error);

  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.critical, message, tag: tag, error: error);

  static void _log(LogLevel level, String message, {String? tag, Object? error}) {
    if (level.index < _minLevel.index) return;
    final prefix = _prefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    debugPrint('$prefix $tagStr$message$errorStr');
  }

  static String _prefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 [DEBUG]';
      case LogLevel.info:
        return 'ℹ️  [INFO]';
      case LogLevel.warning:
        return '⚠️  [WARN]';
      case LogLevel.error:
        return '❌ [ERROR]';
      case LogLevel.critical:
        return '🔥 [CRIT]';
    }
  }
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
  });
}
