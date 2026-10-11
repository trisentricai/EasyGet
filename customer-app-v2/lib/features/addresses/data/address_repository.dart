import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/address_model.dart';

/// Saved addresses (`/users/me/addresses/`). Abstract for fake tests.
abstract class AddressRepository {
  Future<List<Address>> list();

  Future<Address> create(AddressDraft draft);

  Future<Address> update(int id, AddressDraft draft);

  Future<void> delete(int id);

  Future<Address> setDefault(int id);
}

class HttpAddressRepository implements AddressRepository {
  HttpAddressRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Address>> list() async {
    final json = await _api.get<dynamic>(ApiEndpoints.addressesBase);
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Address.fromJson)
        .toList();
  }

  @override
  Future<Address> create(AddressDraft draft) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addressesBase,
      body: draft.toJson(),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Address.fromJson(json);
  }

  @override
  Future<Address> update(int id, AddressDraft draft) async {
    final json = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.addressDetail('$id'),
      body: draft.toJson(),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Address.fromJson(json);
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete<dynamic>(ApiEndpoints.addressDetail('$id'));
  }

  @override
  Future<Address> setDefault(int id) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addressSetDefault('$id'),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Address.fromJson(json);
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return HttpAddressRepository(ref.watch(apiClientProvider));
});