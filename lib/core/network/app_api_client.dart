import 'dart:async';

import 'package:confindant/core/network/api_exception.dart';
import 'package:confindant/core/utils/logger.dart';
import 'package:dio/dio.dart';

class AppApiClient {
  AppApiClient({required String baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
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
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _requestWithRetry(() => _dio.post(path, data: body));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _requestWithRetry(
      () => _dio.patch(path, data: body),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await _requestWithRetry(() => _dio.delete(path));
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
    );
    return _asMap(response.data);
  }

  Future<Response<dynamic>> _requestWithRetry(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (_isRetriable(e)) {
        try {
          return await request();
        } on DioException catch (second) {
          appLog(
            'API retry failed: status=${second.response?.statusCode} message=${second.message}',
          );
          throw _toApiException(second);
        }
      }
      appLog(
        'API request failed: status=${e.response?.statusCode} message=${e.message}',
      );
      throw _toApiException(e);
    }
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
      return ApiException(
        'Unable to connect to backend (${_dio.options.baseUrl})',
      );
    }
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ?? 'Request failed';
      return ApiException(message, statusCode: statusCode);
    }
    return ApiException(
      e.message ?? 'Network request failed',
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException('Invalid response format');
  }
}
