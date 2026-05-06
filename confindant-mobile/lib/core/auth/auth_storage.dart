import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();
  static String? _memoryToken;

  Future<void> saveToken(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  Future<String?> readToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token ?? _memoryToken;
    } catch (_) {
      return _memoryToken;
    }
  }

  Future<void> clearToken() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }
}
