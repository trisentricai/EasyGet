import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/cart_item.dart';
import '../../../models/coupon.dart';

/// Cart repository: server-backed cart with guest merge support.
class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<CartResponse> getCart() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.cart,
      decode: (j) => j as Map<String, dynamic>,
    );
    return CartResponse.fromJson(data);
  }

  Future<CartItem> addItem({
    required String productId,
    String? variantId,
    required int qty,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      body: {
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'qty': qty,
      },
      decode: (j) => j as Map<String, dynamic>,
    );
    return CartItem.fromJson(data);
  }

  Future<CartItem> updateItem(String itemId, int qty) async {
    final data = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.cartItem(itemId),
      body: {'qty': qty},
      decode: (j) => j as Map<String, dynamic>,
    );
    return CartItem.fromJson(data);
  }

  Future<void> removeItem(String itemId) async {
    await _api.delete(ApiEndpoints.cartItem(itemId));
  }

  Future<void> mergeGuestCart(String guestToken) async {
    await _api.post<dynamic>(
      ApiEndpoints.cartMerge,
      body: {'guest_token': guestToken},
    );
  }

  Future<CouponValidation> validateCoupon(String code, int subtotal) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.couponsValidate,
      body: {'code': code, 'cart_subtotal': subtotal},
      decode: (j) => j as Map<String, dynamic>,
    );
    return CouponValidation.fromJson(data);
  }
}

class CartResponse {
  CartResponse({
    required this.items,
    required this.subtotal,
    this.coupon,
    this.discount = 0,
    this.deliveryFee = 0,
    this.total = 0,
  });

  final List<CartItem> items;
  final int subtotal;
  final Coupon? coupon;
  final int discount;
  final int deliveryFee;
  final int total;

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
        items: (json['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        coupon: json['coupon'] != null
            ? Coupon.fromJson(json['coupon'] as Map<String, dynamic>)
            : null,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class CouponValidation {
  CouponValidation({
    required this.discount,
    required this.applied,
    this.message,
  });

  final int discount;
  final bool applied;
  final String? message;

  factory CouponValidation.fromJson(Map<String, dynamic> json) => CouponValidation(
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        applied: json['applied'] ?? false,
        message: json['message']?.toString(),
      );
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});
