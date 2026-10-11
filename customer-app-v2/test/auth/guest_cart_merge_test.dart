import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
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

ResponseBody _json(String body) => ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _loginJson =
    '{"access":"a1","refresh":"r1","user":{"id":1,"email":"a@b.c","name":"A","role":"CUSTOMER"}}';

void main() {
  late List<RequestOptions> seen;

  HttpAuthRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
    TokenStore tokens,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpAuthRepository(ApiClient(dio), tokens);
  }

  test('login merges the guest cart with {session_key} then clears it',
      () async {
    final tokens = InMemoryTokenStore();
    await tokens.saveGuestSessionKey('guest-abc');

    final repo = build((options) async {
      if (options.path == '/cart/merge/') return _json('{}');
      return _json(_loginJson);
    }, tokens);

    await repo.login(email: 'a@b.c', password: 'secret');

    final merge = seen.firstWhere((o) => o.path == '/cart/merge/');
    expect(merge.method, 'POST');
    expect(merge.data, {'session_key': 'guest-abc'});
    expect(await tokens.readGuestSessionKey(), isNull);
  });

  test('login without a guest session key never calls merge', () async {
    final tokens = InMemoryTokenStore();

    final repo = build((options) async => _json(_loginJson), tokens);

    await repo.login(email: 'a@b.c', password: 'secret');

    expect(seen.where((o) => o.path == '/cart/merge/'), isEmpty);
    expect(seen.single.path, '/auth/login/');
  });
}