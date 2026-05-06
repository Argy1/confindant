import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiSettingsStorage {
  static const _autoCategorizationKey = 'ai_auto_categorization_enabled';
  static const _storage = FlutterSecureStorage();
  static bool? _memoryEnabled;

  Future<void> saveAutoCategorizationEnabled(bool enabled) async {
    _memoryEnabled = enabled;
    try {
      await _storage.write(
        key: _autoCategorizationKey,
        value: enabled ? '1' : '0',
      );
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  Future<bool> readAutoCategorizationEnabled() async {
    try {
      final raw = await _storage.read(key: _autoCategorizationKey);
      if (raw == null) return _memoryEnabled ?? true;
      return raw == '1';
    } catch (_) {
      return _memoryEnabled ?? true;
    }
  }
}
