import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/wishlist/data/wishlist_repository.dart';
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

void main() {
  late List<RequestOptions> seen;
  late HttpWishlistRepository repo;

  HttpWishlistRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpWishlistRepository(ApiClient(dio));
  }

  test('fetch returns product slugs from a paged envelope', () async {
    repo = build((_) async => _json(
          '{"count":2,"results":[{"id":1,"slug":"tata-salt-1kg"},'
          '{"id":2,"slug":"aashirvaad-atta-5kg"}]}',
        ));

    final slugs = await repo.fetch();

    expect(seen.single.path, '/products/wishlist/');
    expect(slugs, ['tata-salt-1kg', 'aashirvaad-atta-5kg']);
  });

  test('fetch tolerates a plain list of slug strings', () async {
    repo = build((_) async => _json('["tata-salt-1kg"]'));

    expect(await repo.fetch(), ['tata-salt-1kg']);
  });

  test('toggle POSTs to add and decodes {added,slug,count}', () async {
    repo = build((_) async =>
        _json('{"added":true,"slug":"tata-salt-1kg","count":3}'));

    final result = await repo.toggle('tata-salt-1kg');

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/products/wishlist/tata-salt-1kg/');
    expect(result.added, isTrue);
    expect(result.slug, 'tata-salt-1kg');
    expect(result.count, 3);
  });

  test('toggle DELETEs to remove', () async {
    repo = build((_) async =>
        _json('{"added":false,"slug":"tata-salt-1kg","count":2}'));

    final result = await repo.toggle('tata-salt-1kg', hearted: true);

    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/products/wishlist/tata-salt-1kg/');
    expect(result.added, isFalse);
    expect(result.count, 2);
  });
}