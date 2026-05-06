import 'package:flutter/foundation.dart';

void appLog(String message) {
  if (kDebugMode) {
    // Simple centralized logger for skeleton stage.
    debugPrint('[Confindant] $message');
  }
}
