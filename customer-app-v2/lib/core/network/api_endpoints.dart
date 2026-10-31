/// EasyGet API endpoints — reconciled 2026-10-11 against the VERIFIED live
/// backend. Paths that no longer exist on the real API are omitted (e.g.
/// phone OTP, `/search/trending/`, `/payments/intent`, `/brands/`).
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String register = '/auth/register/';
  static const String logout = '/auth/logout/';
  static const String googleAuth = '/auth/google/';

  // Users / profile / addresses
  static const String me = '/users/me/';
  static const String addressesBase = '/users/me/addresses/';
  static String addressDetail(String id) => '/users/me/addresses/$id/';
  static String addressSetDefault(String id) =>
      '/users/me/addresses/$id/set-default/';

  // Storefront / Home
  static const String storefrontPlatform = '/storefront/platform/';
  static String storefront(String slug) => '/storefront/$slug/';
  static const String banners = '/banners/';

  // Catalog
  static const String products = '/products/';
  static const String categories = '/categories/';
  static const String brands = '/products/brands/';
  static String productDetail(String slug) => '/products/$slug/';
  static String productReviews(String slug) => '/products/$slug/reviews/';

  // Wishlist (lives under /products/ on the real backend)
  static const String wishlistBase = '/products/wishlist/';
  static String wishlistItem(String slug) => '/products/wishlist/$slug/';

  // Search (main search is POST /search/; GET aliases autocomplete)
  static const String search = '/search/';
  static const String searchSuggestions = '/search/suggestions/';

  // Cart
  static const String cart = '/cart/';
  static const String cartItems = '/cart/items/';
  static String cartItem(String id) => '/cart/items/$id/';
  static const String cartMerge = '/cart/merge/';
  static const String cartClear = '/cart/clear/';

  // Orders
  static const String orders = '/orders/';
  static String orderDetail(String id) => '/orders/$id/';
  static String ordersCancel(String id) => '/orders/$id/cancel/';
  static String ordersInvoice(String id) => '/orders/$id/invoice/';

  // Payments (direct create — no intent/confirm on the real backend)
  static const String paymentMethods = '/payments/methods/';
  static const String paymentBase = '/payments/';

  // Pincode / delivery
  static String pincodeCheck(String code) => '/pincode/$code/';

  // Coupon validation (any authenticated user, admin-scoped URL)
  static const String couponsValidate = '/admin/coupons/validate/';

  // Notifications
  static const String notifications = '/notifications/';
  static String notificationMarkRead(String id) =>
      '/notifications/$id/mark_read/';
  static const String notificationsMarkAllRead =
      '/notifications/mark_all_read/';
  static const String notificationsUnreadCount = '/notifications/unread_count/';

  // Realtime device registration (mobile push token)
  static const String realtimeDevices = '/realtime/devices/';

  // Analytics telemetry
  static const String analyticsEvents = '/analytics/events/';
  static const String analyticsBatch = '/analytics/events/batch/';

  // App update check
  static const String pwaUpdatesCheck = '/pwa/updates/check/';
}