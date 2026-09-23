import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cart_repository.dart';

/// The signed-in user's cart. Stays in `loading` for signed-out users
/// (screens gate on auth instead).
class CartController extends AsyncNotifier<Cart?> {
  @override
  Future<Cart?> build() async {
    return ref.watch(cartRepositoryProvider).current();
  }

  Future<String?> reload() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await ref.read(cartRepositoryProvider).current());
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> add({required int variantId, int quantity = 1}) async {
    try {
      await ref.read(cartRepositoryProvider).add(variantId: variantId, quantity: quantity);
      state = AsyncData(await ref.read(cartRepositoryProvider).current());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setQuantity({required int itemId, required int quantity}) async {
    try {
      if (quantity <= 0) {
        await ref.read(cartRepositoryProvider).remove(itemId: itemId);
      } else {
        await ref
            .read(cartRepositoryProvider)
            .setQuantity(itemId: itemId, quantity: quantity);
      }
      state = AsyncData(await ref.read(cartRepositoryProvider).current());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove({required int itemId}) async {
    try {
      await ref.read(cartRepositoryProvider).remove(itemId: itemId);
      state = AsyncData(await ref.read(cartRepositoryProvider).current());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> clear() async {
    try {
      await ref.read(cartRepositoryProvider).clear();
      state = AsyncData(await ref.read(cartRepositoryProvider).current());
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final cartControllerProvider =
    AsyncNotifierProvider<CartController, Cart?>(CartController.new);

/// Badge count for the tab bar / app bar, null-safe.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).value?.totalItems ?? 0;
});
