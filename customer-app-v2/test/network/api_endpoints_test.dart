import 'package:easyget/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase-1 endpoints match the frozen contract exactly', () {
    expect(ApiEndpoints.login, '/auth/login/');
    expect(ApiEndpoints.refresh, '/auth/refresh/');
    expect(ApiEndpoints.register, '/auth/register/');
    expect(ApiEndpoints.googleAuth, '/auth/google/');
    expect(ApiEndpoints.me, '/users/me/');
    expect(ApiEndpoints.cart, '/cart/');
    expect(ApiEndpoints.cartMerge, '/cart/merge/');
    expect(ApiEndpoints.banners, '/banners/');
    expect(ApiEndpoints.storefront, '/storefront/easyget/');
    expect(ApiEndpoints.products, '/products/');
  });

  test('path builders produce contract paths', () {
    expect(ApiEndpoints.productDetail('fresh-milk'), '/products/fresh-milk/');
    expect(ApiEndpoints.cartItem('7'), '/cart/items/7/');
    expect(ApiEndpoints.orderDetail('12'), '/orders/12/');
  });
}
