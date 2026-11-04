import 'package:flutter_test/flutter_test.dart';
import 'package:easyget_customer_app/models/coupon.dart';

void main() {
  group('Coupon', () {
    test('fromJson parses correctly', () {
      final json = {
        'code': 'FRESH20',
        'title': 'Fresh 20',
        'discount_amount': 50,
        'min_order': 200,
        'description': '₹50 off',
        'expires_at': '2026-12-31',
        'type': 'fixed',
        'value': 50,
        'is_active': true,
      };
      final coupon = Coupon.fromJson(json);
      expect(coupon.code, 'FRESH20');
      expect(coupon.discountAmount, 50);
      expect(coupon.minOrder, 200);
    });
  });
}
