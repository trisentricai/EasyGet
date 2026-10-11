import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../../models/catalog_models.dart';
import '../../../models/storefront_models.dart';

/// S4 · Home data: the platform render drives ticker/banners/rails/story;
/// the category grid reads the catalog (8 tiles + See all).
final homeStorefrontProvider = FutureProvider<StorefrontRender>(
  (ref) => ref.watch(catalogRepositoryProvider).platformStorefront(),
);

final homeCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Fallback rails: rendered ONLY when the storefront carries no product
/// rows, so Home always shows products (Hot sales / Top rated / New).
final hotSalesProvider = FutureProvider<CatalogPage>(
  (ref) => ref.watch(catalogRepositoryProvider).products(isFeatured: true),
);

final topRatedProvider = FutureProvider<CatalogPage>(
  (ref) =>
      ref.watch(catalogRepositoryProvider).products(sort: 'rating'),
);

final newArrivalsProvider = FutureProvider<CatalogPage>(
  (ref) =>
      ref.watch(catalogRepositoryProvider).products(sort: 'newest'),
);

/// "All products" paged grid at the bottom of Home (Amazon-style): bare
/// 20-item backend pages — a full page means "maybe more".
class AllProductsState {
  const AllProductsState({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<CatalogProduct> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final Object? error;
}

class AllProductsController extends Notifier<AllProductsState> {
  static const serverPageSize = 20;

  int _generation = 0;

  @override
  AllProductsState build() {
    _load(reset: true);
    return const AllProductsState();
  }

  static bool _hasMore(CatalogPage res) =>
      (res.hasMore || res.results.length >= serverPageSize) &&
      res.results.isNotEmpty;

  Future<void> _load({required bool reset}) async {
    final generation = ++_generation;
    if (reset) {
      state = const AllProductsState();
    } else {
      state = AllProductsState(
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        loading: false,
        loadingMore: true,
      );
    }
    try {
      final nextPage = reset ? 1 : state.page + 1;
      final res = await ref
          .read(catalogRepositoryProvider)
          .products(page: nextPage);
      if (generation != _generation) return;
      state = AllProductsState(
        items: reset ? res.results : [...state.items, ...res.results],
        page: nextPage,
        hasMore: _hasMore(res),
        loading: false,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = reset
          ? AllProductsState(loading: false, error: e)
          : AllProductsState(
              items: state.items,
              page: state.page,
              hasMore: state.hasMore,
              loadingMore: false,
            );
    }
  }

  Future<void> loadMore() {
    if (!state.hasMore || state.loadingMore || state.loading) {
      return Future.value();
    }
    return _load(reset: false);
  }

  Future<void> refresh() => _load(reset: true);
}

final allProductsProvider =
    NotifierProvider<AllProductsController, AllProductsState>(
  AllProductsController.new,
);