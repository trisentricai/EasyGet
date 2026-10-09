import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(Future<ResponseBody> Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

ResponseBody _json(String body) => ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test('createDio uses Render cold-start friendly timeouts (DESIGN §14)', () {
    final dio = ApiClient.createDio();
    expect(dio.options.connectTimeout, const Duration(seconds: 90));
    expect(dio.options.receiveTimeout, const Duration(seconds: 60));
  });

  test('get<T> decodes the JSON body through decode()', () async {
    final client = ApiClient(
      _dioWith((_) async => _json('{"value":42}')),
    );

    final result = await client.get<Map<String, dynamic>>(
      '/ping/',
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );

    expect(result['value'], 42);
  });

  test('post<T> sends the body and decodes the response', () async {
    Object? seen;
    final client = ApiClient(
      _dioWith((options) async {
        seen = options.data;
        return _json('{"ok":true}');
      }),
    );

    final result = await client.post<Map<String, dynamic>>(
      '/auth/login/',
      body: {'email': 'a@b.c'},
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );

    expect(seen, {'email': 'a@b.c'});
    expect(result['ok'], true);
  });

  test('connection failure becomes ApiException with a human message',
      () async {
    final client = ApiClient(
      _dioWith(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        ),
      ),
    );

    await expectLater(
      client.get<void>('/x/'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          isNot(contains('DioException')),
        ),
      ),
    );
  });

  test('warmUp hits the public banners endpoint and never throws', () async {
    String? hitPath;
    Duration? connect;
    final client = ApiClient(
      _dioWith((options) async {
        hitPath = options.path;
        connect = options.connectTimeout;
        return _json('[]');
      }),
    );

    await client.warmUp();

    expect(hitPath, '/banners/');
    // Short, splash-only timeouts - never blocks the app for the full 90s.
    expect(connect, const Duration(seconds: 15));
  });

  test('warmUp swallows failures on an unreachable backend', () async {
    final client = ApiClient(
      _dioWith(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sleeping server',
        ),
      ),
    );

    // Completes without throwing despite the backend being down.
    await client.warmUp();
  });
}
