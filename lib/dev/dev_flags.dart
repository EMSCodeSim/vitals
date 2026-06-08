import 'package:flutter/foundation.dart';

/// Internal developer switches.
///
/// These must default to `false` for release readiness.
class DevFlags {
  static const bool revealHiddenAnswersInLogs = false;
}

void devLog(String message) {
  if (!kDebugMode) return;
  if (!DevFlags.revealHiddenAnswersInLogs) return;
  debugPrint(message);
}
