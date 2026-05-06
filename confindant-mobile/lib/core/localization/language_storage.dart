import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageStorage {
  static const _languageCodeKey = 'language_code';
  static const _storage = FlutterSecureStorage();
  static String? _memoryLanguageCode;

  Future<void> saveLanguageCode(String code) async {
    _memoryLanguageCode = code;
    try {
      await _storage.write(key: _languageCodeKey, value: code);
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  Future<String?> readLanguageCode() async {
    try {
      final code = await _storage.read(key: _languageCodeKey);
      return code ?? _memoryLanguageCode;
    } catch (_) {
      return _memoryLanguageCode;
    }
  }
}
