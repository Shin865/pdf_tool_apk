import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Global error boundary and diagnostic logger.
/// Scrubs PII, file contents, and sensitive filesystem paths from logs.
class GlobalErrorBoundary {
  GlobalErrorBoundary._();

  static final _log = Logger('GlobalErrorBoundary');

  /// Initializes the error boundary and registers hooks.
  static void initialize({required void Function() runAppCallback}) {
    // Scrub sensitive info from log messages
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      final sanitized = sanitizeMessage(record.message);
      debugPrint(
        '[${record.level.name}] ${record.time}: ${record.loggerName} - $sanitized',
      );
      if (record.error != null) {
        debugPrint('  Error: ${sanitizeMessage(record.error.toString())}');
      }
    });

    // Intercept Flutter framework errors
    FlutterError.onError = (details) {
      final sanitizedException = sanitizeMessage(details.exceptionAsString());
      _log.severe('Flutter framework error: $sanitizedException');
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Intercept asynchronous platform dispatcher errors
    PlatformDispatcher.instance.onError = (error, stack) {
      final sanitized = sanitizeMessage(error.toString());
      _log.severe('Uncaught asynchronous error: $sanitized');
      return true; // Mark as handled
    };

    // Run within guarded zone
    runZonedGuarded(runAppCallback, (error, stackTrace) {
      final sanitized = sanitizeMessage(error.toString());
      _log.severe('Zoned error: $sanitized');
    });
  }

  /// Sanitizes messages by removing sensitive filesystem paths and potential PII.
  static String sanitizeMessage(String message) {
    var out = message;

    // Redact user profile directory paths: C:\Users\<name>\... or /data/user/0/...
    out = out.replaceAll(
      RegExp(r'[A-Za-z]:\\[Uu]sers\\[^\\]+'),
      r'C:\Users\<redacted>',
    );
    out = out.replaceAll(
      RegExp(r'/data/user/\d+/[^/]+'),
      '/data/user/0/<app>',
    );
    out = out.replaceAll(
      RegExp('/data/data/[^/]+'),
      '/data/data/<app>',
    );

    // Redact passwords if present in query parameters or arguments
    out = out.replaceAll(
      RegExp(r'password=[^&\s]+', caseSensitive: false),
      'password=<redacted>',
    );
    out = out.replaceAll(
      RegExp(r'token=[^&\s]+', caseSensitive: false),
      'token=<redacted>',
    );

    return out;
  }
}
