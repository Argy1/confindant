import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/auth/auth_storage.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends StateNotifier<AuthSessionState> {
  AuthController({
    required BackendApiService api,
    required AuthStorage storage,
    required AppApiClient client,
  }) : _api = api,
       _storage = storage,
       _client = client,
       super(AuthSessionState.initial()) {
    bootstrap();
  }

  final BackendApiService _api;
  final AuthStorage _storage;
  final AppApiClient _client;

  Future<void> bootstrap() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
      return;
    }

    _client.setBearerToken(token);
    try {
      final user = await _api.me().timeout(const Duration(seconds: 6));
      state = AuthSessionState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (_) {
      await _storage.clearToken();
      _client.setBearerToken(null);
      state = const AuthSessionState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final data = await _api.login(email: email, password: password);
      final token = data['access_token']?.toString() ?? '';
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? const {});
      if (token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Token tidak tersedia dari server',
        );
        return false;
      }
      await _storage.saveToken(token);
      _client.setBearerToken(token);
      state = AuthSessionState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.register(
        username: username,
        email: email,
        password: password,
      );
      final token = data['access_token']?.toString() ?? '';
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? const {});
      if (token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Token tidak tersedia dari server',
        );
        return false;
      }
      await _storage.saveToken(token);
      _client.setBearerToken(token);
      state = AuthSessionState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore logout API failure, always clear local session.
    }

    await _storage.clearToken();
    _client.setBearerToken(null);
    state = const AuthSessionState(status: AuthStatus.unauthenticated);
  }
}
