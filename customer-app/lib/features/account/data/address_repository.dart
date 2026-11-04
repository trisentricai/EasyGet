import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/address.dart';

/// Address repository: CRUD for delivery addresses.
class AddressRepository {
  AddressRepository(this._api);

  final ApiClient _api;

  Future<List<Address>> getAddresses() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.addresses,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> addAddress({
    required String label,
    required String street,
    required String area,
    required String pincode,
    required String phone,
    String type = 'Home',
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.addresses,
      body: {
        'label': label,
        'street': street,
        'area': area,
        'pincode': pincode,
        'phone': phone,
        'type': type,
      },
      decode: (j) => j as Map<String, dynamic>,
    );
    return Address.fromJson(data);
  }

  Future<Address> updateAddress({
    required String id,
    String? label,
    String? street,
    String? area,
    String? pincode,
    String? phone,
    String? type,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (street != null) body['street'] = street;
    if (area != null) body['area'] = area;
    if (pincode != null) body['pincode'] = pincode;
    if (phone != null) body['phone'] = phone;
    if (type != null) body['type'] = type;
    if (isDefault != null) body['is_default'] = isDefault;

    final data = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.addressDetail(id),
      body: body,
      decode: (j) => j as Map<String, dynamic>,
    );
    return Address.fromJson(data);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete(ApiEndpoints.addressDetail(id));
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(apiClientProvider));
});
