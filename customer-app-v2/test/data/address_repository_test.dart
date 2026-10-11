import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/addresses/data/address_repository.dart';
import 'package:easyget/models/address_model.dart';
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

const _addressJson = '''
{"id":1,"label":"Home","line1":"221B Baker St","line2":"Indiranagar",
 "city":"Bengaluru","state":"Karnataka","postal_code":"560001","country":"IN",
 "phone":"9876543210","is_default":true}''';

void main() {
  late List<RequestOptions> seen;
  late HttpAddressRepository repo;

  HttpAddressRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpAddressRepository(ApiClient(dio));
  }

  test('list decodes addresses off /users/me/addresses/', () async {
    repo = build((_) async => _json('[$_addressJson]'));

    final list = await repo.list();

    expect(seen.single.path, '/users/me/addresses/');
    expect(list.single.label, 'Home');
    expect(list.single.line1, '221B Baker St');
    expect(list.single.postalCode, '560001');
    expect(list.single.isDefault, isTrue);
  });

  test('create POSTs the address fields', () async {
    repo = build((_) async => _json(_addressJson));

    final created = await repo.create(
      const AddressDraft(
        label: 'Home',
        line1: '221B Baker St',
        line2: 'Indiranagar',
        city: 'Bengaluru',
        state: 'Karnataka',
        postalCode: '560001',
        country: 'IN',
        phone: '9876543210',
      ),
    );

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/users/me/addresses/');
    expect(seen.single.data, {
      'label': 'Home',
      'line1': '221B Baker St',
      'line2': 'Indiranagar',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'postal_code': '560001',
      'country': 'IN',
      'phone': '9876543210',
    });
    expect(created.id, 1);
  });

  test('update PATCHes the address', () async {
    repo = build((_) async => _json(_addressJson));

    await repo.update(1, const AddressDraft(
      label: 'Work', line1: '1 MG Road', city: 'Bengaluru',
      state: 'Karnataka', postalCode: '560001', country: 'IN',
      phone: '9876543210',
    ));

    expect(seen.single.method, 'PATCH');
    expect(seen.single.path, '/users/me/addresses/1/');
    expect((seen.single.data as Map)['label'], 'Work');
  });

  test('delete DELETEs the address', () async {
    repo = build((_) async => _json('', 204));

    await repo.delete(1);

    expect(seen.single.method, 'DELETE');
    expect(seen.single.path, '/users/me/addresses/1/');
  });

  test('setDefault POSTs to the set-default path', () async {
    repo = build((_) async => _json(_addressJson));

    await repo.setDefault(1);

    expect(seen.single.method, 'POST');
    expect(seen.single.path, '/users/me/addresses/1/set-default/');
  });
}