import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../../models/catalog_models.dart';

/// S5 · Browse filter state. `sortId` is one of featured / price_asc /
/// price_desc / newest / rating (`featured` sends no sort param; `relevance`
/// is search-only and never offered here).
class BrowseFilter {
  const BrowseFilter({
    this.category,
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.minDiscount,
    this.featured,
    this.sortId = 'featured',
  });

  final String? category;
  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final double? minDiscount;
  final bool? featured;
  final String sortId;

  BrowseFilter copyWith({
    String? Function()? category,
    String? Function()? brand,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? minDiscount,
    bool? Function()? featured,
    String? sortId,
  }) =>
      BrowseFilter(
        category: category == null ? this.category : category(),
        brand: brand == null ? this.brand : brand(),
        minPrice: minPrice == null ? this.minPrice : minPrice(),
        maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
        minDiscount:
            minDiscount == null ? this.minDiscount : minDiscount(),
        featured: featured == null ? this.featured : featured(),
        sortId: sortId ?? this.sortId,
      );

  @override
  bool operator ==(Object other) =>
      other is BrowseFilter &&
      other.category == category &&
      other.brand == brand &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.minDiscount == minDiscount &&
      other.featured == featured &&
      other.sortId == sortId;

  @override
  int get hashCode => Object.hash(
      category, brand, minPrice, maxPrice, minDiscount, featured, sortId);
}

class BrowseFilterController extends Notifier<BrowseFilter> {
  @override
  BrowseFilter build() => const BrowseFilter();

  /// One-way sync from the `?category=` URL (the URL is the source of truth;
  /// chips navigate instead of mutating state directly).
  void syncFromRoute(String? slug) {
    final normalized = (slug == null || slug.isEmpty) ? null : slug;
    if (state.category != normalized) {
      state = state.copyWith(category: () => normalized);
    }
  }

  void setCategory(String? slug) {
    if (state.category != slug) state = state.copyWith(category: () => slug);
  }

  void setSort(String sortId) {
    if (state.sortId != sortId) state = state.copyWith(sortId: sortId);
  }

  void applyFilters({bool? featured, double? minDiscount}) {
    state = state.copyWith(
      featured: () => featured,
      minDiscount: () => minDiscount,
    );
  }

  void clearFilters() => state = const BrowseFilter();
}

final browseFilterProvider =
    NotifierProvider<BrowseFilterController, BrowseFilter>(
  BrowseFilterController.new,
);

/// Accumulated paged result for the current [BrowseFilter]. Filter changes
/// reset to page 1; [loadMore] appends while [hasMore].
class BrowseItemsState {
  const BrowseItemsState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.totalKnown = false,
    this.hasMore = false,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<CatalogProduct> items;
  final int page;
  final int total;

  /// False for bare-list backends (no envelope): the toolbar then shows the
  /// loaded count instead of a meaningless fallback total.
  final bool totalKnown;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final Object? error;

  BrowseItemsState copyWith({
    List<CatalogProduct>? items,
    int? page,
    int? total,
    bool? totalKnown,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    Object? Function()? error,
  }) =>
      BrowseItemsState(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total ?? this.total,
        totalKnown: totalKnown ?? this.totalKnown,
        hasMore: hasMore ?? this.hasMore,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error == null ? this.error : error(),
      );
}

class BrowseItemsController extends Notifier<BrowseItemsState> {
  /// Backend page size: GET /products/ returns bare 20-item lists with no
  /// envelope (probed 2026-10-11), so a full page means "maybe more" and an
  /// empty/short page terminates the chain.
  static const serverPageSize = 20;

  int _generation = 0;

  @override
  BrowseItemsState build() {
    final filter = ref.watch(browseFilterProvider);
    _load(filter, reset: true);
    return const BrowseItemsState();
  }

  static bool _hasMore(CatalogPage res) =>
      (res.hasMore || res.results.length >= serverPageSize) &&
      res.results.isNotEmpty;

  Future<void> _load(BrowseFilter filter, {required bool reset}) async {
    final generation = ++_generation;
    if (reset) {
      state = const BrowseItemsState();
    } else {
      state = state.copyWith(loadingMore: true);
    }
    try {
      final nextPage = reset ? 1 : state.page + 1;
      final res =
          await ref.read(catalogRepositoryProvider).products(
                category: filter.category,
                brand: filter.brand,
                minPrice: filter.minPrice,
                maxPrice: filter.maxPrice,
                minDiscount: filter.minDiscount,
                isFeatured: filter.featured,
                sort: filter.sortId == 'featured' ? null : filter.sortId,
                page: nextPage,
              );
      if (generation != _generation) return;
      state = BrowseItemsState(
        items: reset ? res.results : [...state.items, ...res.results],
        // The requested page, not the response echo (bare lists echo page 1).
        page: nextPage,
        total: res.total,
        totalKnown:
            res.pageSize != null || res.total > res.results.length,
        hasMore: _hasMore(res),
        loading: false,
      );
    } catch (e) {
      if (generation != _generation) return;
      state = reset
          ? BrowseItemsState(error: e, loading: false)
          : state.copyWith(loadingMore: false);
    }
  }

  Future<void> loadMore() {
    if (!state.hasMore || state.loadingMore || state.loading) {
      return Future.value();
    }
    return _load(ref.read(browseFilterProvider), reset: false);
  }

  Future<void> refresh() =>
      _load(ref.read(browseFilterProvider), reset: true);
}

final browseItemsProvider =
    NotifierProvider<BrowseItemsController, BrowseItemsState>(
  BrowseItemsController.new,
);

final browseCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);