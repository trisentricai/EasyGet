import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/orders/data/orders_repository.dart';
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

const _listJson = '''
[{"id":101,"order_number":"EG-1001","status":"CONFIRMED",
  "subtotal":"578.00","delivery_fee":"29.00","discount":"50.00",
  "total":"557.00","created_at":"2026-10-08T10:00:00Z","item_count":2}]''';

const _detailJson = '''
{"id":101,"order_number":"EG-1001","status":"OUT_FOR_DELIVERY",
 "subtotal":"578.00","delivery_fee":"29.00","discount":"50.00","total":"557.00",
 "created_at":"2026-10-08T10:00:00Z","item_count":2,
 "items":[{"id":1,"variant":{"name":"Aashirvaad Atta 5kg","label":"5 kg"},
   "quantity":2,"unit_price":"289.00","line_total":"578.00"}],
 "status_history":[{"from_status":"PENDING","to_status":"CONFIRMED",
   "note":"Confirmed","created_at":"2026-10-08T10:05:00Z"}],
 "estimated_delivery_at":"2026-10-08T11:00:00Z",
 "delivered_at":null,"cancelled_at":null,"cancellation_reason":null}''';

void main() {
  late List<RequestOptions> seen;
  late HttpOrdersRepository repo;

  HttpOrdersRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpOrdersRepository(ApiClient(dio));
  }

  test('list decodes Order rows with server-truth pricing', () async {
    repo = build((_) async => _json(_listJson));

    final orders = await repo.list();

    expect(seen.single.path, '/orders/');
    expect(orders.single.id, 101);
    expect(orders.single.orderNumber, 'EG-1001');
    expect(orders.single.status, 'CONFIRMED');
    expect(orders.single.subtotal, 578.0);
    expect(orders.single.deliveryFee, 29.0);
    expect(orders.single.discount, 50.0);
    expect(orders.single.total, 557.0);
    expect(orders.single.itemCount, 2);
  });

  test('detail decodes items + status timeline + delivery timestamps',
      () async {
    repo = build((_) async => _json(_detailJson));

    final order = await repo.detail(101);

    expect(seen.single.path, '/orders/101/');
    expect(order.items.single.variantLabel, '5 kg');
    expect(order.items.single.quantity, 2);
    expect(order.items.single.unitPrice, 289.0);
    expect(order.items.single.lineTotal, 578.0);
    expect(order.statusHistory.single.from, 'PENDING');
    expect(order.statusHistory.single.to, 'CONFIRMED');
    expect(order.statusHistory.single.note, 'Confirmed');
    expect(order.estimatedDeliveryAt, isNotNull);
    expect(order.deliveredAt, isNull);
    expect(order.cancellationReason, isNull);
  });

  test('create POSTs the cart payload and unwraps the orders envelope',
      () async {
    repo = build((_) async => _json('{"orders":$_listJson}'));

    final order = await repo.create(
      cartId: 9,
      deliveryAddress: '221B Baker St, Bengaluru 560001',
      instructions: 'Leave at door',
    );

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/orders/');
    expect(seen.single.data, {
      'cart_id': 9,
      'delivery_address': '221B Baker St, Bengaluru 560001',
      'delivery_instructions': 'Leave at door',
    });
    expect(order.id, 101);
    expect(order.orderNumber, 'EG-1001');
  });

  test('cancel POSTs {reason}', () async {
    repo = build((_) async => _json(_listJson));

    await repo.cancel(101, 'Ordered by mistake');

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/orders/101/cancel/');
    expect(seen.single.data, {'reason': 'Ordered by mistake'});
  });

  test('invoice GETs the invoice payload', () async {
    repo = build((_) async => _json('{"invoice_number":"INV-1","total":"557.00"}'));

    final invoice = await repo.invoice(101);

    expect(seen.single.path, '/orders/101/invoice/');
    expect(invoice['invoice_number'], 'INV-1');
  });
}