import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/payments/data/payment_repository.dart';
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
  late HttpPaymentRepository repo;

  HttpPaymentRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpPaymentRepository(ApiClient(dio));
  }

  test('methods decodes saved payment methods', () async {
    repo = build((_) async => _json(
          '[{"id":1,"type":"COD","label":"Cash on Delivery"},'
          '{"id":2,"type":"UPI","label":"UPI","upi_id":"rahul@upi"}]',
        ));

    final methods = await repo.methods();

    expect(seen.single.path, '/payments/methods/');
    expect(methods, hasLength(2));
    expect(methods.first.type, 'COD');
    expect(methods.first.label, 'Cash on Delivery');
    expect(methods[1].upiId, 'rahul@upi');
  });

  test('createForOrder POSTs /payments/ with the order + gateway', () async {
    repo = build((_) async => _json(
          '{"id":9,"order":101,"gateway":"COD","status":"PENDING",'
          '"amount":"557.00","reference":"PAY-1"}',
        ));

    final payment = await repo.createForOrder(order: 101, gateway: 'COD', amount: 557);

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/payments/');
    expect(seen.single.data, {'order': 101, 'gateway': 'COD', 'amount': 557});
    expect(payment.id, 9);
    expect(payment.status, 'PENDING');
    expect(payment.amount, 557.0);
    expect(payment.reference, 'PAY-1');
  });

  test('createForOrder includes payment_method_id when given', () async {
    repo = build((_) async => _json('{"id":9,"order":101,"gateway":"UPI","status":"PENDING","amount":"557.00"}'));

    await repo.createForOrder(
      order: 101,
      gateway: 'UPI',
      amount: 557,
      paymentMethodId: 2,
    );

    expect(seen.single.data,
        {'order': 101, 'gateway': 'UPI', 'amount': 557, 'payment_method_id': 2});
  });
}