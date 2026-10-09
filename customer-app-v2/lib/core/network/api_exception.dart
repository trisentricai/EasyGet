import 'package:dio/dio.dart';

/// Human-readable error surfaced from the EasyGet API (DRF).
/// Every failure becomes one sentence a shopper can understand — never a
/// status code alone, never `DioException`, never a stack trace.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.payload});

  final String message;
  final int? statusCode;
  final Object? payload;

  @override
  String toString() => message;

  static const String coldStartMessage = 'Waking up the store, retry.';
  static const String offlineMessage =
      'Cannot reach EasyGet right now. Check your connection.';
  static const String serverMessage =
      'Something went wrong on our side. Please try again.';
  static const String sessionExpiredMessage =
      'Session expired. Please sign in again.';

  /// Maps any [DioException] to a single human sentence (DESIGN §14).
  static ApiException fromDio(DioException e) {
    final code = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException(coldStartMessage);
      case DioExceptionType.connectionError:
        return ApiException(offlineMessage, statusCode: code);
      case DioExceptionType.badCertificate:
        return ApiException(offlineMessage, statusCode: code);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled.', statusCode: code);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    // 5xx: never surface raw payload (can be HTML from a proxy).
    if (code != null && code >= 500) {
      return ApiException(serverMessage, statusCode: code);
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map && err['message'] is String) {
        return ApiException(err['message'] as String, statusCode: code);
      }
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(detail, statusCode: code, payload: data);
      }
      // DRF field errors: {email: ["..."], quantity: ["..."]}
      final parts = <String>[];
      data.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          parts.add('$key: ${value.join(', ')}');
        } else if (value is String && value.isNotEmpty) {
          parts.add('$key: $value');
        }
      });
      if (parts.isNotEmpty) {
        return ApiException(parts.join(' · '), statusCode: code, payload: data);
      }
    }
    if (data is String && data.isNotEmpty && !data.contains('<')) {
      return ApiException(data, statusCode: code);
    }
    if (code == 401) {
      return ApiException(sessionExpiredMessage, statusCode: code);
    }
    return ApiException(
      'Request failed${code == null ? '' : ' ($code)'}.',
      statusCode: code,
    );
  }
}
