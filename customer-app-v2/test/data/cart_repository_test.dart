import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
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

const _cartJson = '''
{"id":9,"store":{"id":1,"slug":"easyget"},"items":[
  {"id":31,
   "variant":{"id":5,"name":"5 kg","label":"5 kg","sku":"ATTA-5","price":"289.00",
     "product":9,"product_name":"Aashirvaad Atta","product_slug":"aashirvaad-atta",
     "image":"https://example.com/atta.jpg"},
   "quantity":2,"line_total":"578.00","tenant_id":3,"seller_name":"EASYGET Store"},
  {"id":32,
   "variant":{"id":8,"name":"Tata Salt 1kg","price":"28.00"},
   "quantity":1,"line_total":"28.00","tenant_id":3,"seller_name":"EASYGET Store"}],
 "total_items":3,"subtotal":"606.00"}''';

void main() {
  late List<RequestOptions> seen;
  late HttpCartRepository repo;

  HttpCartRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpCartRepository(ApiClient(dio));
  }

  test('fetchCart decodes items, totals and unit price', () async {
    repo = build((_) async => _json(_cartJson));

    final cart = await repo.fetchCart();

    expect(seen.single.path, '/cart/');
    expect(cart.id, 9);
    expect(cart.totalItems, 3);
    expect(cart.subtotal, 606.0);
    expect(cart.items, hasLength(2));

    final first = cart.items.first;
    expect(first.id, 31);
    expect(first.variantId, 5);
    expect(first.variantLabel, '5 kg');
    expect(first.variantName, '5 kg');
    expect(first.price, 289.0);
    expect(first.quantity, 2);
    expect(first.lineTotal, 578.0);
    expect(first.tenantId, 3);
    expect(first.sellerName, 'EASYGET Store');
    // Live product details ride on the variant (see §18): name, slug, image.
    expect(first.productName, 'Aashirvaad Atta');
    expect(first.productSlug, 'aashirvaad-atta');
    expect(first.imageUrl, 'https://example.com/atta.jpg');

    // Label falls back to name when absent; product details stay null.
    expect(cart.items[1].variantLabel, 'Tata Salt 1kg');
    expect(cart.items[1].productName, isNull);
    expect(cart.items[1].productSlug, isNull);
    expect(cart.items[1].imageUrl, isNull);
  });

  test('addItem POSTs {variant_id, quantity}', () async {
    repo = build((_) async => _json(_cartJson));

    await repo.addItem(variantId: 5, quantity: 2);

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/cart/items/');
    expect(seen.single.data, {'variant_id': 5, 'quantity': 2});
  });

  test('updateQty rewrites via DELETE + re-POST (PATCH 405s live)', () async {
    repo = build((options) async {
      if (options.method == 'GET') return _json(_cartJson);
      return _json('', 204);
    });

    await repo.updateQty(31, 4);

    expect(seen.map((o) => o.method).toList(), ['GET', 'DELETE', 'POST']);
    expect(seen[1].path, '/cart/items/31/');
    expect(seen[2].path, '/cart/items/');
    expect(seen[2].data, {'variant_id': 5, 'quantity': 4});
  });

  test('updateQty to zero just DELETEs', () async {
    repo = build((_) async => _json('', 204));

    await repo.updateQty(31, 0);

    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/cart/items/31/');
  });

  test('remove DELETEs the line', () async {
    repo = build((_) async => _json('', 204));

    await repo.remove(31);

    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/cart/items/31/');
  });

  test('clear DELETEs /cart/clear/', () async {
    repo = build((_) async => _json('', 204));

    await repo.clear();

    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/cart/clear/');
  });
}