import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/features/reviews/data/review_repository.dart';
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

const _reviewJson = '''
{"id":5,"rating":4,"title":"Good atta","body":"Fresh and well packed",
 "user_name":"Rahul","verified":true,"status":"APPROVED",
 "created_at":"2026-10-07T09:00:00Z"}''';

void main() {
  late List<RequestOptions> seen;
  late HttpReviewRepository repo;

  HttpReviewRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpReviewRepository(ApiClient(dio));
  }

  test('list decodes paged reviews', () async {
    repo = build((_) async =>
        _json('{"count":1,"results":[$_reviewJson]}'));

    final reviews = await repo.list('aashirvaad-atta-5kg');

    expect(seen.single.path, '/products/aashirvaad-atta-5kg/reviews/');
    expect(reviews.single.id, 5);
    expect(reviews.single.rating, 4);
    expect(reviews.single.title, 'Good atta');
    expect(reviews.single.userName, 'Rahul');
    expect(reviews.single.verified, isTrue);
    expect(reviews.single.status, 'APPROVED');
  });

  test('create POSTs {rating,title,body} and decodes the review', () async {
    repo = build((_) async => _json(_reviewJson));

    final review = await repo.create(
      'aashirvaad-atta-5kg',
      rating: 4,
      title: 'Good atta',
      body: 'Fresh and well packed',
    );

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/products/aashirvaad-atta-5kg/reviews/');
    expect(seen.single.data,
        {'rating': 4, 'title': 'Good atta', 'body': 'Fresh and well packed'});
    expect(review.id, 5);
  });

  test('duplicate review (409) surfaces a human ApiException', () async {
    repo = build((_) async => _json(
          '{"detail":"You have already reviewed this product."}',
          409,
        ));

    await expectLater(
      repo.create('aashirvaad-atta-5kg', rating: 5, title: 'x', body: 'y'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'You have already reviewed this product.',
        ),
      ),
    );
  });
}