import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/states.dart';
import '../data/catalog_repository.dart';

class BrowseFilter {
  BrowseFilter({
    this.category = '',
    this.sort = '',
    this.minPrice = '',
    this.maxPrice = '',
    this.featuredOnly = false,
  });

  final String category;
  final String sort;
  final String minPrice;
  final String maxPrice;
  final bool featuredOnly;

  BrowseFilter copyWith({
    String? category,
    String? sort,
    String? minPrice,
    String? maxPrice,
    bool? featuredOnly,
  }) {
    return BrowseFilter(
      category: category ?? this.category,
      sort: sort ?? this.sort,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }
}

class BrowseState {
  BrowseState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.loadingMore = false,
  });

  final List<Product> items;
  final int total;
  final int page;
  final bool loadingMore;

  bool get hasMore => items.length < total;

  BrowseState copyWith({
    List<Product>? items,
    int? total,
    int? page,
    bool? loadingMore,
  }) {
    return BrowseState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class BrowseController extends AsyncNotifier<BrowseState> {
  BrowseFilter _filter = BrowseFilter();

  @override
  Future<BrowseState> build() async {
    final arg = ref.watch(_browseFilterArgProvider);
    if (arg != null) _filter = _filter.copyWith(category: arg);
    return _loadPage(1, const []);
  }

  Future<BrowseState> _loadPage(int page, List<Product> current) async {
    final repo = ref.read(catalogRepositoryProvider);
    final res = await repo.products(
      category: _filter.category,
      sort: _filter.sort.isEmpty ? null : _filter.sort,
      minPrice: _filter.minPrice.isEmpty ? null : _filter.minPrice,
      maxPrice: _filter.maxPrice.isEmpty ? null : _filter.maxPrice,
      featured: _filter.featuredOnly,
      page: page,
    );
    return BrowseState(
      items: [...current, ...res.items],
      total: res.total,
      page: page,
    );
  }

  Future<void> apply(BrowseFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1, const []));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _loadPage(current.page + 1, current.items);
      state = AsyncData(next);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}

final _browseFilterArgProvider = Provider<String?>((_) => null);

final browseControllerProvider =
    AsyncNotifierProvider.autoDispose<BrowseController, BrowseState>(
        BrowseController.new);

final categoryListProvider = FutureProvider((ref) {
  return ref.watch(catalogRepositoryProvider).categories();
});

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    // Seeds the controller's first load (e.g. home category deep-links).
    return ProviderScope(
      overrides: [
        _browseFilterArgProvider.overrideWithValue(initialCategory),
      ],
      child: const _BrowseBody(),
    );
  }
}

class _BrowseBody extends ConsumerStatefulWidget {
  const _BrowseBody();

  @override
  ConsumerState<_BrowseBody> createState() => _BrowseBodyState();
}

class _BrowseBodyState extends ConsumerState<_BrowseBody> {
  late final TextEditingController _min = TextEditingController();
  late final TextEditingController _max = TextEditingController();
  String _category = '';
  String _sort = '';
  bool _featured = false;

  @override
  void initState() {
    super.initState();
    _category = ref.read(_browseFilterArgProvider) ?? '';
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(browseControllerProvider.notifier).apply(
          BrowseFilter(
            category: _category,
            sort: _sort,
            minPrice: _min.text.trim(),
            maxPrice: _max.text.trim(),
            featuredOnly: _featured,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final products = ref.watch(browseControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _category.isEmpty,
                  onTap: () {
                    setState(() => _category = '');
                    _apply();
                  },
                ),
                ...?categories.value?.map(
                  (c) => _FilterChip(
                    label: c.name,
                    selected: _category == c.slug,
                    onTap: () {
                      setState(() => _category = c.slug);
                      _apply();
                    },
                  ),
                ),
                _FilterChip(
                  label: '★ Featured',
                  selected: _featured,
                  onTap: () {
                    setState(() => _featured = !_featured);
                    _apply();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Default')),
                      DropdownMenuItem(
                          value: 'price_asc', child: Text('Price ↑')),
                      DropdownMenuItem(
                          value: 'price_desc', child: Text('Price ↓')),
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    ],
                    onChanged: (v) {
                      setState(() => _sort = v ?? '');
                      _apply();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min ₹',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _apply(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max ₹',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _apply(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.when(
              loading: () => const LoadingGrid(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(browseControllerProvider),
              ),
              data: (s) {
                if (s.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No products found',
                    text: 'Try clearing the filters.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(browseControllerProvider),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => ProductCard(
                              product: s.items[i],
                              onTap: () => context.push(
                                  '/product/${s.items[i].slug}'),
                            ),
                            childCount: s.items.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            children: [
                              Text(
                                'Showing ${s.items.length} of ${s.total}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              if (s.hasMore)
                                FilledButton.tonal(
                                  onPressed: s.loadingMore
                                      ? null
                                      : () => ref
                                          .read(browseControllerProvider
                                              .notifier)
                                          .loadMore(),
                                  child: s.loadingMore
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(
                                          'Load more (${s.total - s.items.length} left)'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
