import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_endpoints.dart';
import 'package:easyget/core/network/auth_interceptor.dart';
import 'package:easyget/core/storage/token_store.dart';
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

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _Harness {
  _Harness(this.tokens);

  final InMemoryTokenStore tokens;
  late Future<ResponseBody> Function(RequestOptions options) onRequest;
  int refreshCalls = 0;
  int sessionLostFired = 0;

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://t/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) => onRequest(options));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokens: tokens,
        onSessionLost: () async {
          sessionLostFired++;
        },
      ),
    );
    return dio;
  }
}

String? _auth(RequestOptions o) => o.headers['Authorization'] as String?;

void main() {
  test('attaches bearer from TokenStore to normal requests', () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(access: 'A', refresh: 'R');
    String? seen;

    final harness = _Harness(tokens);
    harness.onRequest = (options) async {
      seen = _auth(options);
      return _json('{"ok":true}');
    };
    final dio = harness.build();

    await dio.get<dynamic>(ApiEndpoints.me);

    expect(seen, 'Bearer A');
  });

  test('auth endpoints never attach bearer and never refresh', () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(access: 'A', refresh: 'R');
    String? seen;

    final harness = _Harness(tokens);
    harness.onRequest = (options) async {
      seen = _auth(options);
      return _json('{"access":"x","refresh":"y"}');
    };
    final dio = harness.build();

    await dio.post<dynamic>(ApiEndpoints.login, data: {'email': 'a@b.c'});

    expect(seen, isNull);
    expect(harness.refreshCalls, 0);
  });

  test('two parallel 401s trigger exactly ONE refresh; both retried', () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(access: 'OLD', refresh: 'R');
    var meCalls = 0;

    final harness = _Harness(tokens);
    harness.onRequest = (options) async {
      if (options.path.endsWith(ApiEndpoints.refresh)) {
        harness.refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _json('{"access":"NEW"}');
      }
      meCalls++;
      if (_auth(options) == 'Bearer NEW') {
        return _json('{"id":1,"email":"a@b.c","role":"CUSTOMER"}');
      }
      return _json('{"detail":"expired"}', 401);
    };
    final dio = harness.build();

    final results = await Future.wait([
      dio.get<dynamic>(ApiEndpoints.me),
      dio.get<dynamic>(ApiEndpoints.me),
    ]);

    expect(results, hasLength(2));
    expect(harness.refreshCalls, 1);
    expect(meCalls, 4); // 2 initial 401s + 2 retries
    expect(await tokens.readAccess(), 'NEW');
  });

  test('refresh failure fires onSessionLost once and clears tokens', () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(access: 'OLD', refresh: 'R');

    final harness = _Harness(tokens);
    harness.onRequest = (options) async {
      if (options.path.endsWith(ApiEndpoints.refresh)) {
        harness.refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _json('{"detail":"invalid"}', 401);
      }
      return _json('{"detail":"expired"}', 401);
    };
    final dio = harness.build();

    Future<Response<dynamic>> swallow() => dio
        .get<dynamic>(ApiEndpoints.me)
        .catchError((Object _) => Response<dynamic>(
              requestOptions: RequestOptions(path: ApiEndpoints.me),
            ));

    await Future.wait([swallow(), swallow()]);

    expect(harness.refreshCalls, 1);
    expect(harness.sessionLostFired, 1);
    expect(await tokens.readAccess(), isNull);
    expect(await tokens.readRefresh(), isNull);
  });

  test('a retried request that 401s again loses the session, no loop',
      () async {
    final tokens = InMemoryTokenStore();
    await tokens.save(access: 'OLD', refresh: 'R');

    final harness = _Harness(tokens);
    harness.onRequest = (options) async {
      if (options.path.endsWith(ApiEndpoints.refresh)) {
        harness.refreshCalls++;
        return _json('{"access":"NEW"}');
      }
      return _json('{"detail":"expired"}', 401);
    };
    final dio = harness.build();

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.me),
      throwsA(isA<DioException>()),
    );

    expect(harness.refreshCalls, 1);
    expect(harness.sessionLostFired, 1);
  });
}
