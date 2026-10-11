import 'package:easyget/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins every path string in [ApiEndpoints] to the VERIFIED live backend
/// (reconciled 2026-10-11). Paths that no longer exist on the real API are
/// simply absent from the class — calling `ApiEndpoints.otpSend` etc. is a
/// compile error, which the analyzer enforces for us.
void main() {
  group('auth + users', () {
    test('auth endpoints match the live backend', () {
      expect(ApiEndpoints.login, '/auth/login/');
      expect(ApiEndpoints.refresh, '/auth/refresh/');
      expect(ApiEndpoints.register, '/auth/register/');
      expect(ApiEndpoints.logout, '/auth/logout/');
      expect(ApiEndpoints.googleAuth, '/auth/google/');
    });

    test('user/profile + address endpoints sit under /users/me', () {
      expect(ApiEndpoints.me, '/users/me/');
      expect(ApiEndpoints.addressesBase, '/users/me/addresses/');
      expect(ApiEndpoints.addressDetail('12'), '/users/me/addresses/12/');
      expect(ApiEndpoints.addressSetDefault('12'),
          '/users/me/addresses/12/set-default/');
    });
  });

  group('catalog + search', () {
    test('catalog endpoints use the live /products/... paths', () {
      expect(ApiEndpoints.products, '/products/');
      expect(ApiEndpoints.productDetail('fresh-milk'), '/products/fresh-milk/');
      expect(ApiEndpoints.categories, '/categories/');
      expect(ApiEndpoints.brands, '/products/brands/');
      expect(ApiEndpoints.wishlistBase, '/products/wishlist/');
      expect(ApiEndpoints.wishlistItem('fresh-milk'),
          '/products/wishlist/fresh-milk/');
      expect(ApiEndpoints.productReviews('fresh-milk'),
          '/products/fresh-milk/reviews/');
    });

    test('search endpoints (POST /search/ + suggestions)', () {
      expect(ApiEndpoints.search, '/search/');
      expect(ApiEndpoints.searchSuggestions, '/search/suggestions/');
    });
  });

  group('commerce', () {
    test('cart endpoints', () {
      expect(ApiEndpoints.cart, '/cart/');
      expect(ApiEndpoints.cartItems, '/cart/items/');
      expect(ApiEndpoints.cartItem('7'), '/cart/items/7/');
      expect(ApiEndpoints.cartMerge, '/cart/merge/');
      expect(ApiEndpoints.cartClear, '/cart/clear/');
    });

    test('orders endpoints + builders', () {
      expect(ApiEndpoints.orders, '/orders/');
      expect(ApiEndpoints.orderDetail('12'), '/orders/12/');
      expect(ApiEndpoints.ordersCancel('12'), '/orders/12/cancel/');
      expect(ApiEndpoints.ordersInvoice('12'), '/orders/12/invoice/');
    });

    test('payments endpoints (direct create — no intent/confirm)', () {
      expect(ApiEndpoints.paymentMethods, '/payments/methods/');
      expect(ApiEndpoints.paymentBase, '/payments/');
    });

    test('pincode + coupon validation endpoints', () {
      expect(ApiEndpoints.pincodeCheck('560001'), '/pincode/560001/');
      expect(ApiEndpoints.couponsValidate, '/admin/coupons/validate/');
    });
  });

  group('home + engagement', () {
    test('storefront + banners endpoints', () {
      expect(ApiEndpoints.storefrontPlatform, '/storefront/platform/');
      expect(ApiEndpoints.storefront('my-store'), '/storefront/my-store/');
      expect(ApiEndpoints.banners, '/banners/');
    });

    test('notifications endpoints', () {
      expect(ApiEndpoints.notifications, '/notifications/');
      expect(ApiEndpoints.notificationMarkRead('3'),
          '/notifications/3/mark_read/');
      expect(ApiEndpoints.notificationsMarkAllRead,
          '/notifications/mark_all_read/');
      expect(ApiEndpoints.notificationsUnreadCount,
          '/notifications/unread_count/');
    });

    test('realtime device + analytics + app-update endpoints', () {
      expect(ApiEndpoints.realtimeDevices, '/realtime/devices/');
      expect(ApiEndpoints.analyticsEvents, '/analytics/events/');
      expect(ApiEndpoints.analyticsBatch, '/analytics/events/batch/');
      expect(ApiEndpoints.pwaUpdatesCheck, '/pwa/updates/check/');
    });
  });
}