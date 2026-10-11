import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/nav.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/catalog_models.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/quick_add.dart';
import '../data/wishlist_repository.dart';
import 'wishlist_controller.dart';

/// Saved products for the wishlist screen.
final wishlistProductsProvider = FutureProvider<List<CatalogProduct>>(
  (ref) => ref.watch(wishlistRepositoryProvider).fetchProducts(),
);

/// W1 · Wishlist (`/wishlist`, pushed from Account): 2-col grid of saved
/// products. Tapping a card opens its PDP (variant choice lives there);
/// unhearting removes the row with an Undo snackbar.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(wishlistProductsProvider);

    return Scaffold(
      appBar: EasyGetAppBar(
        showBack: true,
        onBack: () => popOrHome(context),
        title: 'Wishlist',
      ),
      body: products.when(
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: SkeletonGrid(count: 4),
          ),
        ),
        error: (_, _) => ErrorState(
          body: 'We could not load your wishlist.',
          onRetry: () => ref.invalidate(wishlistProductsProvider),
        ),
        data: (rows) {
          // Reactive intersect: unhearting drops the row instantly (Undo
          // brings it back) with no refetch round-trip.
          final hearts =
              ref.watch(wishlistControllerProvider).value;
          final visible = hearts == null
              ? rows
              : rows
                  .where((p) => hearts.contains(p.slug))
                  .toList();
          if (visible.isEmpty) {
            return EmptyState(
              title: 'No saved items yet',
              body: 'Tap a heart on any product to keep it here.',
              actionLabel: 'Browse products',
              onAction: () => context.go('/browse'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(wishlistProductsProvider);
              await ref
                  .read(wishlistControllerProvider.notifier)
                  .refresh();
            },
            child: _Grid(rows: visible),
          );
        },
      ),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.rows});

  final List<CatalogProduct> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width =
        (MediaQuery.sizeOf(context).width - AppSpace.lg * 2 - AppSpace.md) / 2;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xxl),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpace.md,
        crossAxisSpacing: AppSpace.md,
        childAspectRatio: ProductCard.gridAspect(width),
      ),
      itemCount: rows.length,
              itemBuilder: (_, i) {
                final product = rows[i];
                return ProductCard(
                  product: product,
                  density: ProductDensity.grid,
                  width: width,
                  onTap: () =>
                      context.push('/product/${product.slug}'),
                  // No variant data on a saved row: Add runs the shared
                  // quick-add pipeline (sheet when variants exist).
                  onChanged: (_) =>
                      context.push('/product/${product.slug}'),
                  onQuickAdd: () =>
                      quickAddFromCard(context, product),
                  onHearted: (nowHearted) {
                    if (nowHearted) return;
                    // The container outlives this row: Undo must survive
                    // the grid unmounting when its last card leaves.
                    final container =
                        ProviderScope.containerOf(context);
                    if (!context.mounted) return;
                    showAppSnackbar(
                      context,
                      'Removed from wishlist.',
                      actionLabel: 'Undo',
                      onAction: () => container
                          .read(wishlistControllerProvider.notifier)
                          .toggle(product.slug),
                    );
                  },
                );
              },
    );
  }
}
