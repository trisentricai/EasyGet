import 'package:dio/dio.dart';

/// Human-readable error surfaced from the EasyGet API (DRF).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.payload});

  final String message;
  final int? statusCode;
  final Object? payload;

  @override
  String toString() => message;

  /// DRF payloads: {detail}, {error: {message}}, or {field: [msgs]}.
  static ApiException fromDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException('Request timed out. Check your connection.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Cannot reach the server. Is the backend running?',
        statusCode: code,
      );
    }
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map && err['message'] is String) {
        return ApiException(err['message'] as String, statusCode: code);
      }
      final detail = data['detail'];
      if (detail is String) {
        return ApiException(detail, statusCode: code, payload: data);
      }
      // Field errors: {email: ["..."], quantity: ["..."]}
      final parts = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          parts.add('$key: ${value.join(', ')}');
        } else if (value is String) {
          parts.add('$key: $value');
        }
      });
      if (parts.isNotEmpty) {
        return ApiException(parts.join(' · '), statusCode: code, payload: data);
      }
    }
    if (data is String && data.isNotEmpty) {
      return ApiException(data, statusCode: code);
    }
    return ApiException(
      code == 401
          ? 'Session expired. Please sign in again.'
          : 'Request failed${code == null ? '' : ' ($code)'}.',
      statusCode: code,
    );
  }
}
