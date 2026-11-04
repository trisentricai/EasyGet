import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/product_card.dart';
import '../../../shared_widgets/custom_app_bar.dart';
import '../../../features/catalog/data/catalog_repository.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';

/// Browse / PLP screen (Tab 2).
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String? _selectedCategory;
  String _sort = 'relevance';
  bool _vegOnly = false;
  bool _inStockOnly = false;
  Set<String> _dietaryFilters = {};
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    // In real app, would append to existing list
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _hasMore = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final categoriesAsync = ref.watch(categoryListProvider);
    final productsAsync = ref.watch(_browseProductsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App bar
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Browse',
                showSearch: true,
                onSearchTap: () => context.push('/search'),
              ),
            ),
            // Sticky category chips
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryChipsDelegate(
                categoriesAsync: categoriesAsync,
                selectedCategory: _selectedCategory,
                onCategoryTap: (slug) {
                  setState(() {
                    _selectedCategory = slug;
                    _hasMore = true;
                  });
                },
              ),
            ),
            // Toolbar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: productsAsync.when(
                        data: (products) => Text(
                          'Showing ${products.length} items',
                          style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: Text(
                        'Filter',
                        style: AppTypography.label(theme.colorScheme.onSurface),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _hasActiveFilters ? colors.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(
                        'Sort',
                        style: AppTypography.label(theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product grid
            productsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => Container(
                      decoration: BoxDecoration(
                        color: colors.sunken,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    childCount: 6,
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(_browseProductsProvider),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      message: 'No items in this filter',
                      actionLabel: 'Reset Filters',
                      onAction: () {
                        setState(() {
                          _selectedCategory = null;
                          _vegOnly = false;
                          _inStockOnly = false;
                          _dietaryFilters.clear();
                          _sort = 'relevance';
                        });
                      },
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(
                        product: products[i],
                        variant: ProductVariant.grid,
                      ),
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
            // Load more indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                ),
              ),
            // End cap
            if (!_hasMore && !_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'You\'ve seen everything',
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilters => _vegOnly || _inStockOnly || _dietaryFilters.isNotEmpty;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        vegOnly: _vegOnly,
        inStockOnly: _inStockOnly,
        dietaryFilters: _dietaryFilters,
        onApply: (v, i, d) {
          setState(() {
            _vegOnly = v;
            _inStockOnly = i;
            _dietaryFilters = d;
            _hasMore = true;
          });
        },
        onClear: () {
          setState(() {
            _vegOnly = false;
            _inStockOnly = false;
            _dietaryFilters.clear();
            _hasMore = true;
          });
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        currentSort: _sort,
        onSelect: (s) {
          setState(() {
            _sort = s;
            _hasMore = true;
          });
        },
      ),
    );
  }
}

/// Category list provider.
final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

/// Browse products provider.
final _browseProductsProvider = FutureProvider<List<Product>>((ref) async {
  // This would use the actual category/sort/filters from the browse controller
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProducts(sort: 'relevance', page: 1);
});

/// Category chips delegate for sticky header.
class _CategoryChipsDelegate extends SliverPersistentHeaderDelegate {
  _CategoryChipsDelegate({
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final AsyncValue<List<Category>> categoriesAsync;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: overlapsContent ? 1 : 0,
      child: categoriesAsync.when(
        loading: () => _buildChips(context, []),
        error: (_, __) => _buildChips(context, []),
        data: (categories) => _buildChips(context, categories),
      ),
    );
  }

  Widget _buildChips(BuildContext context, List<Category> categories) {
    final allCategories = [
      Category(id: 'all', name: 'All Aisles', slug: '', image: null, itemCount: 0),
      ...categories,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: allCategories.map((cat) {
          final isSelected = selectedCategory == null || selectedCategory == cat.slug;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.name, style: AppTypography.label(
                isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                size: 12,
              )),
              selected: isSelected,
              onSelected: (_) => onCategoryTap(cat.slug),
              selectedColor: Theme.of(context).freshColors.primary,
              checkmarkColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isSelected ? Theme.of(context).freshColors.primary : Theme.of(context).colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

/// Filter bottom sheet.
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({
    required this.vegOnly,
    required this.inStockOnly,
    required this.dietaryFilters,
    required this.onApply,
    required this.onClear,
  });

  final bool vegOnly;
  final bool inStockOnly;
  final Set<String> dietaryFilters;
  final void Function(bool, bool, Set<String>) onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final dietaryOptions = ['Organic Certified', 'Gluten-Free', 'Vegan', 'Cold-Pressed'];
    final localDietary = Set<String>.from(dietaryFilters);

    return StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Filters', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                  const Spacer(),
                  TextButton(onPressed: onClear, child: Text('Clear All', style: AppTypography.label(colors.marigold))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SwitchListTile(
                    title: Text('Vegetarian Only', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                    value: vegOnly,
                    onChanged: (v) => setState(() => localDietary.contains('veg') ? localDietary.remove('veg') : localDietary.add('veg')),
                    activeThumbColor: colors.primary,
                  ),
                  SwitchListTile(
                    title: Text('In Stock Immediately', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                    value: inStockOnly,
                    onChanged: (v) => setState(() => localDietary.contains('stock') ? localDietary.remove('stock') : localDietary.add('stock')),
                    activeThumbColor: colors.primary,
                  ),
                  const Divider(),
                  Text('Dietary Lifestyle', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dietaryOptions.map((d) {
                      final selected = localDietary.contains(d);
                      return FilterChip(
                        label: Text(d, style: AppTypography.label(
                          selected ? Colors.white : theme.colorScheme.onSurface,
                          size: 12,
                        )),
                        selected: selected,
                        onSelected: (_) => setState(() => selected ? localDietary.remove(d) : localDietary.add(d)),
                        selectedColor: colors.primary,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClear,
                          child: Text('Clear All', style: AppTypography.label(colors.marigold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => onApply(
                            localDietary.contains('veg'),
                            localDietary.contains('stock'),
                            localDietary.where((d) => dietaryOptions.contains(d)).toSet(),
                          ),
                          child: Text('Apply Filters', style: AppTypography.label(colors.onPrimary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sort bottom sheet.
class _SortSheet extends StatelessWidget {
  const _SortSheet({
    required this.currentSort,
    required this.onSelect,
  });

  final String currentSort;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final options = [
      ('relevance', 'Relevance'),
      ('rating', 'Highest Rated'),
      ('price_asc', 'Price: Low to High'),
      ('price_desc', 'Price: High to Low'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Sort By', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: currentSort,
            onChanged: (v) {
              if (v != null) {
                onSelect(v);
                Navigator.pop(context);
              }
            },
            child: Column(
              children: [
                ...options.map((opt) => RadioListTile<String>(
                  title: Text(opt.$2, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  value: opt.$1,
                  activeColor: colors.primary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: colors.faint),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.body(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// Error state widget.
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.danger),
          const SizedBox(height: 16),
          Text('Something went wrong', style: AppTypography.bodyMedium(theme.colorScheme.onSurface), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}