import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Address {
  Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postalCode,
    this.line2 = '',
    this.state = '',
    this.country = '',
    this.phone = '',
    this.isDefault = false,
  });

  final dynamic id;
  final String label;
  final String line1;
  final String city;
  final String postalCode;
  final String line2;
  final String state;
  final String country;
  final String phone;
  final bool isDefault;

  String get summary {
    final bits = [line1, line2, city, postalCode].where((s) => s.trim().isNotEmpty);
    return bits.join(', ');
  }

  Map<String, Object?> toPayload() => {
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
      };

  /// Backend expects a free-form address object on order creation.
  Map<String, Object?> toOrderPayload() => {
        'label': label,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'],
        label: (json['label'] ?? 'Home') as String,
        line1: (json['line1'] ?? '') as String,
        line2: (json['line2'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        state: (json['state'] ?? '') as String,
        postalCode: (json['postal_code'] ?? '') as String,
        country: (json['country'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        isDefault: (json['is_default'] ?? false) as bool,
      );
}

class CheckoutRepository {
  CheckoutRepository(this._api);

  final ApiClient _api;

  static List<Address> _asList(dynamic json) {
    final list = json is List ? json : (json as Map)['results'] as List? ?? [];
    return list.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Address>> addresses() async {
    final json = await _api.get<dynamic>('/users/me/addresses/');
    return _asList(json);
  }

  Future<Address> addAddress(Map<String, Object?> body) => _api.post<Address>(
        '/users/me/addresses/',
        body: body,
        decode: (j) => Address.fromJson(j as Map<String, dynamic>),
      );

  Future<void> deleteAddress(dynamic id) => _api.delete('/users/me/addresses/$id/');

  Future<Address> setDefault(dynamic id) => _api.post<Address>(
        '/users/me/addresses/$id/set-default/',
        decode: (j) => Address.fromJson(j as Map<String, dynamic>),
      );

  /// Returns the created order id when the backend includes one,
  /// otherwise null (caller falls back to the orders list).
  Future<String?> placeOrder({
    required String cartId,
    required int store,
    required Map<String, Object?> address,
    String instructions = '',
  }) async {
    final json = await _api.post<dynamic>('/orders/', body: {
      'cart_id': cartId,
      'store': store,
      'delivery_address': address,
      if (instructions.trim().isNotEmpty) 'delivery_instructions': instructions.trim(),
    });
    if (json is Map<String, dynamic>) return json['id']?.toString();
    return null;
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider));
});
