import 'package:confindant/core/auth/auth_controller.dart';
import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/auth/auth_storage.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthStorage extends AuthStorage {
  String? token;

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clearToken() async {
    token = null;
  }
}

class _FakeAuthApiService extends BackendApiService {
  _FakeAuthApiService() : super(AppApiClient(baseUrl: 'http://localhost'));

  bool meShouldFail = false;

  @override
  Future<Map<String, dynamic>> me() async {
    if (meShouldFail) {
      throw Exception('unauthorized');
    }
    return {'id': 'u1', 'username': 'tester'};
  }
}

void main() {
  test('bootstrap token valid -> authenticated', () async {
    final storage = _FakeAuthStorage()..token = 'token-valid';
    final api = _FakeAuthApiService();
    final controller = AuthController(
      api: api,
      storage: storage,
      client: AppApiClient(baseUrl: 'http://localhost'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(controller.state.status, AuthStatus.authenticated);
    expect(controller.state.token, 'token-valid');
    expect(controller.state.user?['id'], 'u1');
  });

  test('bootstrap token invalid -> clears and unauthenticated', () async {
    final storage = _FakeAuthStorage()..token = 'token-invalid';
    final api = _FakeAuthApiService()..meShouldFail = true;
    final controller = AuthController(
      api: api,
      storage: storage,
      client: AppApiClient(baseUrl: 'http://localhost'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
  });
}
