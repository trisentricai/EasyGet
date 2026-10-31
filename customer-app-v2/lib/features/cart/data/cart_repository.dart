import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/cart_models.dart';

/// The server cart. Server is the source of truth for every price; the client
/// never computes totals (DESIGN §14). Abstract for fake-driven tests.
abstract class CartRepository {
  Future<Cart> fetchCart();

  Future<void> addItem({required int variantId, int quantity = 1});

  Future<void> updateQty(int itemId, int quantity);

  Future<void> remove(int itemId);

  Future<void> clear();
}

class HttpCartRepository implements CartRepository {
  HttpCartRepository(this._api);

  final ApiClient _api;

  @override
  Future<Cart> fetchCart() async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.cart,
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Cart.fromJson(json);
  }

  @override
  Future<void> addItem({required int variantId, int quantity = 1}) async {
    await _api.post<dynamic>(
      ApiEndpoints.cartItems,
      body: {'variant_id': variantId, 'quantity': quantity},
    );
  }

  /// Qty rewrite. NOTE: `PATCH /cart/items/:id/` 405s on the deployed
  /// backend (`Method "PATCH" not allowed`, probed 2026-10-11), so a rewrite
  /// is DELETE + re-POST with the same semantics (server re-validates).
  @override
  Future<void> updateQty(int itemId, int quantity) async {
    if (quantity <= 0) {
      await remove(itemId);
      return;
    }
    final cart = await fetchCart();
    CartItem? line;
    for (final item in cart.items) {
      if (item.id == itemId) line = item;
    }
    final target = line;
    if (target == null) return;
    await _api.delete<dynamic>(ApiEndpoints.cartItem('$itemId'));
    await addItem(variantId: target.variantId, quantity: quantity);
  }

  @override
  Future<void> remove(int itemId) async {
    await _api.delete<dynamic>(ApiEndpoints.cartItem('$itemId'));
  }

  @override
  Future<void> clear() async {
    await _api.delete<dynamic>(ApiEndpoints.cartClear);
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return HttpCartRepository(ref.watch(apiClientProvider));
});

/// Live item count for the shell's cart badge (DESIGN §11.5). Screens that
/// need the full cart watch [cartRepositoryProvider] directly.
final cartCountProvider = FutureProvider<int>((ref) async {
  final cart = await ref.watch(cartRepositoryProvider).fetchCart();
  return cart.totalItems;
});