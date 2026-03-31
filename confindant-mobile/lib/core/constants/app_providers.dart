import 'package:confindant/core/auth/auth_controller.dart';
import 'package:confindant/core/auth/auth_state.dart';
import 'package:confindant/core/auth/auth_storage.dart';
import 'package:confindant/core/network/app_api_client.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _apiEnvironment = String.fromEnvironment('API_ENV', defaultValue: 'dev');
const _apiBaseUrlOverride = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String _normalizeApiBaseUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return value;

  value = value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  if (value.endsWith('/api/v1')) {
    value = value.substring(0, value.length - 3);
  }

  final uri = Uri.tryParse(value);
  if (uri == null) return value;

  // Common stale local config: old :4000 endpoint.
  if (uri.host == '10.0.2.2' && uri.port == 4000 && _apiEnvironment == 'dev') {
    return uri.replace(port: 8000, path: '/api').toString();
  }

  return uri.toString();
}

String _defaultApiBaseUrlForEnv() {
  switch (_apiEnvironment) {
    case 'prod':
      return 'https://api.confindant.app/api';
    case 'staging':
      return 'https://staging-api.confindant.app/api';
    default:
      return 'http://10.0.2.2:8000/api';
  }
}

final apiBaseUrlProvider = Provider<String>((ref) {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _normalizeApiBaseUrl(_apiBaseUrlOverride);
  }
  return _normalizeApiBaseUrl(_defaultApiBaseUrlForEnv());
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final appApiClientProvider = Provider<AppApiClient>((ref) {
  return AppApiClient(baseUrl: ref.watch(apiBaseUrlProvider));
});

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  return BackendApiService(ref.watch(appApiClientProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthSessionState>((ref) {
      return AuthController(
        api: ref.watch(backendApiServiceProvider),
        storage: ref.watch(authStorageProvider),
        client: ref.watch(appApiClientProvider),
      );
    });

final isAuthenticatedProvider = StateProvider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.status == AuthStatus.authenticated;
});
