import 'package:flutter/services.dart';

String imagePickerErrorMessage(Object error, {required bool forCamera}) {
  if (error is PlatformException) {
    final code = error.code.toLowerCase();

    if (code.contains('camera_access_denied') ||
        code.contains('access_denied') ||
        code.contains('permission')) {
      return forCamera
          ? 'Camera permission denied. Please enable camera permission in app settings.'
          : 'Photo access denied. Please enable photo permission in app settings.';
    }

    if (code.contains('camera_unavailable') || code.contains('no_available_camera')) {
      return 'Camera is unavailable on this device/emulator.';
    }
  }

  return forCamera
      ? 'Failed to open camera. Please try again or use Gallery.'
      : 'Failed to open gallery. Please try again.';
}
