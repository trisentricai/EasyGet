import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

RequestOptions _options() => RequestOptions(path: '/x/');

DioException _dio(
  DioExceptionType type, {
  int? status,
  Object? data,
}) =>
    DioException(
      requestOptions: _options(),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: _options(),
              statusCode: status,
              data: data,
            ),
    );

void main() {
  group('timeouts', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      test('$type -> cold-start hint', () {
        expect(
          ApiException.fromDio(_dio(type)).message,
          'Waking up the store, retry.',
        );
      });
    }
  });

  test('connectionError -> human sentence', () {
    expect(
      ApiException.fromDio(_dio(DioExceptionType.connectionError)).message,
      'Cannot reach EasyGet right now. Check your connection.',
    );
  });

  test('400 with DRF detail -> surfaced verbatim', () {
    final e = ApiException.fromDio(
      _dio(DioExceptionType.badResponse, status: 400, data: {
        'detail': 'Invalid token.',
      }),
    );
    expect(e.message, 'Invalid token.');
    expect(e.statusCode, 400);
  });

  test('400 with DRF field errors -> surfaced readably', () {
    final e = ApiException.fromDio(
      _dio(DioExceptionType.badResponse, status: 400, data: {
        'email': ['user with this email already exists.'],
      }),
    );
    expect(e.message, contains('user with this email already exists.'));
  });

  test('500 -> generic human sentence, never raw HTML/jargon', () {
    final e = ApiException.fromDio(
      _dio(DioExceptionType.badResponse,
          status: 500, data: '<html>Server Error</html>'),
    );
    expect(e.message, 'Something went wrong on our side. Please try again.');
  });

  test('401 -> session expired sentence', () {
    expect(
      ApiException.fromDio(
        _dio(DioExceptionType.badResponse, status: 401),
      ).message,
      'Session expired. Please sign in again.',
    );
  });

  test('no mapping ever leaks Dio/stack jargon', () {
    for (final type in DioExceptionType.values) {
      final message =
          ApiException.fromDio(_dio(type, status: 503)).message;
      expect(message, isNot(contains('DioException')), reason: '$type');
      expect(message, isNot(contains('stack')), reason: '$type');
      expect(message.trim(), isNotEmpty, reason: '$type');
    }
  });
}
