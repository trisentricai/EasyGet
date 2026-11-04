import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-side enrichment for cart lines. The frozen cart serializer
/// (README §3.4) never ships product name/slug/image on a variant, so
/// `GET /cart/` alone can't render product titles or photos. We backfill
/// from product detail payloads (`GET /products/:slug/`), which carry
/// variants[] — every PDP view maps variantId → product name/slug/image.
/// Just-added lines are enriched at confirm time. No endpoint or backend
/// changes.
class CartVariantProduct {
  const CartVariantProduct({
    required this.productName,
    required this.productSlug,
    this.imageUrl,
  });

  final String productName;
  final String productSlug;
  final String? imageUrl;
}

class CartEnrichmentController
    extends Notifier<Map<int, CartVariantProduct>> {
  @override
  Map<int, CartVariantProduct> build() => {};

  void record(int variantId, {
    required String productName,
    required String productSlug,
    String? imageUrl,
  }) {
    state = {
      ...state,
      variantId: CartVariantProduct(
        productName: productName,
        productSlug: productSlug,
        imageUrl: imageUrl,
      ),
    };
  }

  void recordAll(Map<int, CartVariantProduct> entries) {
    state = {...state, ...entries};
  }

  CartVariantProduct? forVariant(int variantId) => state[variantId];
}

final cartEnrichmentProvider =
    NotifierProvider<CartEnrichmentController, Map<int, CartVariantProduct>>(
  CartEnrichmentController.new,
);
