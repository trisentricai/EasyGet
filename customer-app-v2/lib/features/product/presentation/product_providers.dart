import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/data/cart_repository.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../reviews/data/review_repository.dart';
import '../../../models/catalog_models.dart';
import '../../../models/pincode_model.dart';
import '../../../models/review_model.dart';

/// S7 · PDP data: detail + reviews + related per slug, pincode checker, and a
/// PDP cart helper that seeds qty from the server cart (+ → addItem,
/// − → PATCH/DELETE by resolved line id).
final productDetailProvider =
    FutureProvider.family<ProductDetail, String>(
  (ref, slug) => ref.watch(catalogRepositoryProvider).product(slug),
);

final productReviewsProvider =
    FutureProvider.family<List<Review>, String>(
  (ref, slug) => ref.watch(reviewRepositoryProvider).list(slug),
);

/// Related rail: featured products excluding the current one (the catalog
/// payloads carry no category field, so same-category lookup is impossible).
final relatedProductsProvider =
    FutureProvider.family<List<CatalogProduct>, String>(
  (ref, slug) async {
    final page = await ref
        .watch(catalogRepositoryProvider)
        .products(isFeatured: true);
    return page.results.where((p) => p.slug != slug).toList();
  },
);

class PincodeState {
  const PincodeState({
    this.code = '',
    this.checking = false,
    this.info,
    this.error,
  });

  final String code;
  final bool checking;
  final PincodeInfo? info;
  final Object? error;
}

class PincodeController extends Notifier<PincodeState> {
  @override
  PincodeState build() => const PincodeState();

  Future<void> check(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) return;
    state = PincodeState(code: code, checking: true);
    try {
      final info =
          await ref.read(catalogRepositoryProvider).pincode(code);
      state = PincodeState(code: code, info: info);
    } catch (e) {
      state = PincodeState(code: code, error: e);
    }
  }

  void clear() => state = const PincodeState();
}

final pincodeControllerProvider =
    NotifierProvider<PincodeController, PincodeState>(
  PincodeController.new,
);

class PdpCartState {
  const PdpCartState({
    this.qtyByVariant = const {},
    this.busy = false,
  });

  final Map<int, int> qtyByVariant;
  final bool busy;
}

class PdpCartController extends Notifier<PdpCartState> {
  @override
  PdpCartState build() => const PdpCartState();

  Future<void> refresh() async {
    try {
      final cart = await ref.read(cartRepositoryProvider).fetchCart();
      state = PdpCartState(
        qtyByVariant: {
          for (final item in cart.items) item.variantId: item.quantity,
        },
      );
    } catch (_) {
      // Best-effort seed: the stepper still works, ops surface their errors.
    }
  }

  Future<void> increment(int variantId) async {
    if (state.busy) return;
    state = PdpCartState(qtyByVariant: state.qtyByVariant, busy: true);
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(variantId: variantId, quantity: 1);
      await refresh();
    } finally {
      if (ref.mounted) {
        state = PdpCartState(qtyByVariant: state.qtyByVariant);
      }
    }
  }

  Future<void> decrement(int variantId) async {
    if (state.busy) return;
    state = PdpCartState(qtyByVariant: state.qtyByVariant, busy: true);
    try {
      final repo = ref.read(cartRepositoryProvider);
      final cart = await repo.fetchCart();
      CartLine? line;
      for (final item in cart.items) {
        if (item.variantId == variantId) {
          line = (id: item.id, quantity: item.quantity);
          break;
        }
      }
      if (line != null) {
        if (line.quantity - 1 <= 0) {
          await repo.remove(line.id);
        } else {
          await repo.updateQty(line.id, line.quantity - 1);
        }
      }
      await refresh();
    } finally {
      if (ref.mounted) {
        state = PdpCartState(qtyByVariant: state.qtyByVariant);
      }
    }
  }
}

/// Resolved server line for decrement (id + current qty).
typedef CartLine = ({int id, int quantity});

final pdpCartControllerProvider =
    NotifierProvider<PdpCartController, PdpCartState>(
  PdpCartController.new,
);