import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 輕量級日誌封裝，後續可接入檔案或遠端收集。
class AppLogger {
  const AppLogger();

  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log('ERROR', message, error: error, stackTrace: stackTrace);

  void _log(String level, String message,
      {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$level] $message');
    }
    developer.log(message,
        level: _toLevel(level), error: error, stackTrace: stackTrace);
  }

  int _toLevel(String level) {
    switch (level) {
      case 'ERROR':
        return 1000;
      case 'WARN':
        return 800;
      default:
        return 500;
    }
  }
}
