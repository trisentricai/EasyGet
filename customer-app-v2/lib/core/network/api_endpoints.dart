/// EasyGet API endpoints — exact paths from CONTEXT.md (all under /api/v1/).
/// Single source of truth for every network call.
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String otpSend = '/auth/otp/send/';
  static const String otpVerify = '/auth/otp/verify/';
  static const String refresh = '/auth/refresh/';
  static const String googleAuth = '/auth/google/';
  static const String me = '/users/me/';

  // Storefront / Home
  static const String storefront = '/storefront/easyget/';
  static const String banners = '/banners/';
  static const String couponsActive = '/coupons/active/';
  static const String couponsValidate = '/coupons/validate/';

  // Catalog
  static const String products = '/products/';
  static const String categories = '/categories/';
  static const String brands = '/brands/';

  // Search
  static const String search = '/search/';
  static const String searchSuggestions = '/search/suggestions/';
  static const String searchTrending = '/search/trending/';

  // Cart
  static const String cart = '/cart/';
  static const String cartItems = '/cart/items/';
  static const String cartMerge = '/cart/merge/';

  // Wishlist
  static const String wishlist = '/wishlist/';

  // Orders
  static const String orders = '/orders/';

  // Payments
  static const String paymentMethods = '/payments/methods/';
  static const String paymentIntent = '/payments/intent/';
  static const String paymentConfirm = '/payments/confirm/';

  // Addresses
  static const String addresses = '/addresses/';

  // Pincode
  static const String pincode = '/pincode/';

  // Build helpers
  static String productDetail(String slug) => '/products/$slug/';
  static String productReviews(String slug) => '/products/$slug/reviews/';
  static String productRatingDist(String slug) =>
      '/products/$slug/rating-distribution/';
  static String cartItem(String id) => '/cart/items/$id/';
  static String orderDetail(String id) => '/orders/$id/';
  static String orderTrackDetail(String id) => '/orders/$id/track/';
  static String orderCancelDetail(String id) => '/orders/$id/cancel/';
  static String addressDetail(String id) => '/addresses/$id/';
  static String pincodeCheck(String code) => '/pincode/$code/';
  static String wishlistItem(String productId) => '/wishlist/$productId/';
}
