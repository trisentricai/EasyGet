import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/states.dart';
import '../../../models/catalog_models.dart';
import '../../catalog/presentation/widgets/filter_sheet.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/widgets/sort_sheet.dart';
import 'browse_providers.dart';

const _sortLabels = {
  'featured': 'Featured',
  'price_asc': 'Price: Low to High',
  'price_desc': 'Price: High to Low',
  'newest': 'Newest',
  'rating': 'Top rated',
};

/// S5 · Browse / PLP (`/browse?category=`, tab 2): pinned category chips →
/// toolbar (count + Filter + Sort) → 2-col grid (12dp gap) → infinite
/// scroll → FilterSheet / SortSheet. Filter or sort changes reset to page 1.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late final ScrollController _scroll = ScrollController()
    ..addListener(_onScroll);

  /// Last `?category=` the filter was synced from. The URL is the source of
  /// truth: chips navigate, and route changes (deep link, back button) sync
  /// the filter post-frame.
  String? _lastRouteCategory;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(browseItemsProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilter() async {
    final filter = ref.read(browseFilterProvider);
    final total = ref.read(browseItemsProvider).total;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => FilterSheet(
        filters: [
          FilterToggle(
              id: 'featured',
              label: 'Featured',
              value: filter.featured == true),
          FilterToggle(
              id: 'onsale',
              label: 'On sale',
              value: (filter.minDiscount ?? 0) > 0),
        ],
        resultCount: total,
        onApply: (ids) => ref
            .read(browseFilterProvider.notifier)
            .applyFilters(
              featured: ids.contains('featured') ? true : null,
              minDiscount: ids.contains('onsale') ? 10 : null,
            ),
      ),
    );
  }

  Future<void> _openSort() async {
    final selected = ref.read(browseFilterProvider).sortId;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => SortSheet(
        options: const [
          SortOption(id: 'featured', label: 'Featured'),
          SortOption(id: 'price_asc', label: 'Price: Low to High'),
          SortOption(id: 'price_desc', label: 'Price: High to Low'),
          SortOption(id: 'newest', label: 'Newest'),
          SortOption(id: 'rating', label: 'Top rated'),
        ],
        selectedId: selected,
        onSelect: (id) =>
            ref.read(browseFilterProvider.notifier).setSort(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawCategory =
        GoRouterState.of(context).uri.queryParameters['category'];
    final routeCategory =
        (rawCategory == null || rawCategory.isEmpty) ? null : rawCategory;
    if (routeCategory != _lastRouteCategory) {
      _lastRouteCategory = routeCategory;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(browseFilterProvider.notifier)
              .syncFromRoute(routeCategory);
        }
      });
    }

    final filter = ref.watch(browseFilterProvider);
    final items = ref.watch(browseItemsProvider);
    final categories = ref.watch(browseCategoriesProvider);

    return Scaffold(
      appBar: const EasyGetAppBar(
        title: 'Browse',
        bottom: AppSearchBar(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipsRow(
            categories: categories.value ?? const [],
            selected: filter.category,
            onSelect: (slug) =>
                context.go(slug == null ? '/browse' : '/browse?category=$slug'),
          ),
          _Toolbar(
            total: items.total,
            sortLabel: _sortLabels[filter.sortId] ?? 'Featured',
            onFilter: _openFilter,
            onSort: _openSort,
          ),
          Expanded(child: _Grid(items: items, controller: _scroll)),
        ],
      ),
    );
  }
}

/// Pinned category chips (All + catalog). Stays put under the app bar.
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 6),
        children: [
          AppChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSpace.sm),
            AppChip(
              label: category.name,
              selected: selected == category.slug,
              onTap: () => onSelect(category.slug),
            ),
          ],
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.total,
    required this.sortLabel,
    required this.onFilter,
    required this.onSort,
  });

  final int total;
  final String sortLabel;
  final VoidCallback onFilter;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: Row(
        children: [
          Text('$total items',
              style:
                  AppTypography.tabularNumber(scheme.onSurfaceVariant)),
          const Spacer(),
          TextButton.icon(
            onPressed: onFilter,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Filter'),
          ),
          TextButton.icon(
            onPressed: onSort,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            label: Text('Sort: $sortLabel'),
          ),
        ],
      ),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.items, required this.controller});

  final BrowseItemsState items;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.loading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: SkeletonGrid(count: 4),
        ),
      );
    }
    if (items.error != null) {
      return ErrorState(
        body: 'We could not load products.',
        onRetry: () => ref.read(browseItemsProvider.notifier).refresh(),
      );
    }
    if (items.items.isEmpty) {
      return EmptyState(
        title: 'No products here',
        body: 'Try a different category or clear your filters.',
        actionLabel: 'Clear filters',
        onAction: () {
          ref.read(browseFilterProvider.notifier).clearFilters();
          context.go('/browse');
        },
      );
    }

    final width =
        (MediaQuery.sizeOf(context).width - AppSpace.lg * 2 - AppSpace.md) / 2;
    return RefreshIndicator(
      onRefresh: () => ref.read(browseItemsProvider.notifier).refresh(),
      child: GridView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpace.md,
          crossAxisSpacing: AppSpace.md,
          childAspectRatio: 0.62,
        ),
        itemCount: items.items.length + (items.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= items.items.length) {
            return const Center(
              key: Key('browse-loading-more'),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final product = items.items[i];
          return ProductCard(
            product: product,
            density: ProductDensity.grid,
            width: width,
            onTap: () => context.go('/product/${product.slug}'),
          );
        },
      ),
    );
  }
}
