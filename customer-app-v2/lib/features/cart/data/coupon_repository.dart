import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/catalog_models.dart';

/// A server-validated coupon discount.
class CouponDiscount {
  const CouponDiscount({
    required this.code,
    required this.discount,
    this.discountType,
  });

  final String code;
  final double discount;
  final String? discountType;

  factory CouponDiscount.fromJson(Map<String, dynamic> json) =>
      CouponDiscount(
        code: (json['code'] ?? json['coupon'] ?? '') as String,
        discount: numToDouble(json['discount']),
        discountType: json['discount_type'] as String?,
      );
}

/// Coupon validation (`POST /admin/coupons/validate/`, any authenticated
/// user; 400 means invalid and surfaces as an [ApiException]).
abstract class CouponRepository {
  Future<CouponDiscount> validate({
    required String code,
    required double orderValue,
  });
}

class HttpCouponRepository implements CouponRepository {
  HttpCouponRepository(this._api);

  final ApiClient _api;

  @override
  Future<CouponDiscount> validate({
    required String code,
    required double orderValue,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.couponsValidate,
      body: {'code': code, 'order_value': orderValue},
      decode: (j) => (j as Map).cast<String, dynamic>(),
    );
    return CouponDiscount.fromJson({...json, 'code': code});
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return HttpCouponRepository(ref.watch(apiClientProvider));
});