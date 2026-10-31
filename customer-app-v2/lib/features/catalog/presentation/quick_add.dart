import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/snackbar.dart';
import '../../../models/catalog_models.dart';
import '../../cart/data/cart_repository.dart';
import '../../product/presentation/product_providers.dart';
import '../data/catalog_repository.dart';
import 'widgets/variant_sheet.dart';

/// What a card Add tap resolves to once the variants are known.
enum QuickAddKind { added, pick, unavailable }

class QuickAddOutcome {
  const QuickAddOutcome._(this.kind, {this.variantId, this.options = const []});

  const QuickAddOutcome.added(int variantId)
      : this._(QuickAddKind.added, variantId: variantId);

  const QuickAddOutcome.pick(List<VariantOption> options)
      : this._(QuickAddKind.pick, options: options);

  const QuickAddOutcome.unavailable() : this._(QuickAddKind.unavailable);

  final QuickAddKind kind;
  final int? variantId;
  final List<VariantOption> options;
}

/// Resolves a card Add tap: no buyable variants → unavailable; exactly one →
/// direct add; several → let the shopper pick in a VariantSheet. Pure logic,
/// fully unit-testable (the sheet + snackbars live in [quickAddFromCard]).
Future<QuickAddOutcome> resolveQuickAdd(
    CatalogRepository repo, String slug) async {
  final detail = await repo.product(slug);
  final active = detail.variants.where((v) => v.isActive).toList();
  if (active.isEmpty) return const QuickAddOutcome.unavailable();
  if (active.length == 1) {
    return QuickAddOutcome.added(active.first.id);
  }
  return QuickAddOutcome.pick([
    for (final v in active)
      VariantOption(id: v.id, name: v.name, price: v.price),
  ]);
}

/// Card Add pipeline (MNC workflow): resolve → single unit goes straight
/// into the cart with a quantity-confirming snackbar (+ View cart), multiple
/// variants open the sheet first. Refreshes the shell cart badge.
Future<void> quickAddFromCard(
    BuildContext context, CatalogProduct product) async {
  final container = ProviderScope.containerOf(context);
  final catalog = container.read(catalogRepositoryProvider);
  final cart = container.read(cartRepositoryProvider);

  late final QuickAddOutcome outcome;
  try {
    outcome = await resolveQuickAdd(catalog, product.slug);
  } catch (_) {
    if (context.mounted) {
      showAppSnackbar(context, 'Could not add that right now.');
    }
    return;
  }

  Future<void> commit(int variantId, String name, double price) async {
    try {
      await cart.addItem(variantId: variantId, quantity: 1);
      container
          .read(cardAdditionsProvider.notifier)
          .record(product.slug, variantId);
      await container
          .read(pdpCartControllerProvider.notifier)
          .refresh();
      container.invalidate(cartCountProvider);
      if (!context.mounted) return;
      showAppSnackbar(
        context,
        'Added 1 × $name (₹${_rupees(price)})',
        // The cart is a tab root: go(), never push() — pushing a shell
        // branch trips the Navigator duplicate-page-key assertion.
        actionLabel: 'View cart',
        onAction: () => context.go('/cart'),
      );
    } catch (_) {
      container
          .read(cardAdditionsProvider.notifier)
          .forget(product.slug);
      if (context.mounted) {
        showAppSnackbar(context, 'Could not add that right now.');
      }
    }
  }

  // Known variant (added before, this session): skip resolve + sheet and
  // commit one more unit straight away.
  final known = container.read(cardAdditionsProvider)[product.slug];
  if (known != null) {
    final detail = await _detailOrNull(catalog, product.slug);
    var price = product.basePrice;
    if (detail != null) {
      for (final v in detail.variants) {
        if (v.id == known) price = v.price;
      }
    }
    await commit(known, product.name, price);
    return;
  }

  switch (outcome.kind) {
    case QuickAddKind.unavailable:
      if (context.mounted) {
        showAppSnackbar(context, 'Unavailable right now.');
      }
    case QuickAddKind.added:
      await commit(outcome.variantId!, product.name, product.basePrice);
    case QuickAddKind.pick:
      if (!context.mounted) return;
      final picked = await VariantSheet.show(
        context,
        options: outcome.options,
      );
      if (picked == null || !context.mounted) return;
      await commit(picked.id, picked.name, picked.price);
  }
}

/// Best-effort detail fetch for price display; null when offline.
Future<ProductDetail?> _detailOrNull(
    CatalogRepository repo, String slug) async {
  try {
    return await repo.product(slug);
  } catch (_) {
    return null;
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

/// Remembers which variant backs each card (slug → variantId) so cards can
/// show LIVE cart quantities after the first add, instead of a dead pill.
/// Written by quick-add commits and PDP confirms; keyed by slug, so it is
/// strictly session memory (server truth stays on PDP/cart).
class CardAdditionsController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void record(String slug, int variantId) {
    if (state[slug] == variantId) return;
    state = {...state, slug: variantId};
  }

  void forget(String slug) {
    if (!state.containsKey(slug)) return;
    final next = {...state}..remove(slug);
    state = next;
  }
}

final cardAdditionsProvider =
    NotifierProvider<CardAdditionsController, Map<String, int>>(
  CardAdditionsController.new,
);
