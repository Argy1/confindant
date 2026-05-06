import 'dart:async';

import 'package:confindant/core/network/api_exception.dart';
import 'package:confindant/core/utils/logger.dart';
import 'package:dio/dio.dart';

class AppApiClient {
  static const Duration _connectTimeout = Duration(seconds: 20);
  static const Duration _ioTimeout = Duration(seconds: 60);

  AppApiClient({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: _connectTimeout,
          receiveTimeout: _ioTimeout,
          sendTimeout: _ioTimeout,
          headers: const {'Accept': 'application/json'},
        ),
      );

  final Dio _dio;

  void setBearerToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _requestWithRetry(
      () => _dio.get(path, queryParameters: query),
      method: 'GET',
      path: path,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _requestWithRetry(
      () => _dio.post(path, data: body),
      method: 'POST',
      path: path,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _requestWithRetry(
      () => _dio.patch(path, data: body),
      method: 'PATCH',
      path: path,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _requestWithRetry(
      () => _dio.delete(path),
      method: 'DELETE',
      path: path,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    String? fileField,
    String? filePath,
  }) async {
    final formMap = <String, dynamic>{...fields};
    if (fileField != null && filePath != null && filePath.isNotEmpty) {
      formMap[fileField] = await MultipartFile.fromFile(filePath);
    }
    final response = await _requestWithRetry(
      () => _dio.post(path, data: FormData.fromMap(formMap)),
      method: 'POST',
      path: path,
    );
    return _asMap(response.data);
  }

  Future<Response<dynamic>> _requestWithRetry(
    Future<Response<dynamic>> Function() request,
    {required String method, required String path,}
  ) async {
    DioException? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        return await request();
      } on DioException catch (e) {
        lastError = e;
        final retriable = _isRetriable(e);
        final canRetry = retriable && attempt < 3;
        appLog(
          'API request failed: attempt=$attempt method=$method path=$path status=${e.response?.statusCode} type=${e.type} message=${e.message}',
        );
        if (!canRetry) {
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
    }
    throw _toApiException(lastError!);
  }

  bool _isRetriable(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  ApiException _toApiException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      final hint = _connectionHelpHint();
      return ApiException(
        hint == null
            ? 'Unable to connect to backend (${_dio.options.baseUrl})'
            : 'Unable to connect to backend (${_dio.options.baseUrl}). $hint',
      );
    }
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ?? 'Request failed';
      final detail = _firstErrorDetail(data['errors']);
      final combined = detail == null || detail.isEmpty
          ? message
          : '$message ($detail)';
      return ApiException(combined, statusCode: statusCode);
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'Server terlalu lama merespons. Coba lagi sebentar, atau cek koneksi backend (${_dio.options.baseUrl}).',
        statusCode: statusCode,
      );
    }
    return ApiException(
      e.message ?? 'Network request failed',
      statusCode: statusCode,
    );
  }

  String? _connectionHelpHint() {
    final uri = Uri.tryParse(_dio.options.baseUrl);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host == '10.0.2.2') {
      return 'If you run on physical phone, use your laptop LAN IP via --dart-define API_BASE_URL=http://<LAN_IP>:8000/api.';
    }

    final isLan = host.startsWith('192.168.') || host.startsWith('10.') || host.startsWith('172.');
    if (isLan) {
      return 'Ensure backend runs with php artisan serve --host=0.0.0.0 --port=8000, phone and laptop are on same Wi-Fi, and firewall allows port 8000.';
    }

    return null;
  }

  String? _firstErrorDetail(dynamic errors) {
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first?.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }
    if (errors is List && errors.isNotEmpty) {
      return errors.first?.toString();
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException('Invalid response format');
  }
}
