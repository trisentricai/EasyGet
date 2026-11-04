import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/product_card.dart';
import '../../../shared_widgets/custom_app_bar.dart';
import '../../../features/catalog/data/search_repository.dart';
import '../../../models/product.dart';

/// Search & Discovery screen (Tab 3).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  List<String> _recentSearches = [];
  List<String> _trending = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _query = widget.initialQuery ?? '';
    _focusNode.requestFocus();
    _loadTrending();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    try {
      final repo = ref.read(searchRepositoryProvider);
      final trending = await repo.getTrending();
      if (mounted) setState(() => _trending = trending);
    } catch (_) {}
  }

  Future<void> _loadRecent() async {
    // In real app, load from SharedPreferences/Hive
    if (mounted) {
      setState(() => _recentSearches = ['Avocado', 'A2 Gir Cow Milk', 'Hass Avocado', 'Organic Bananas']);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    // Debounced search would go here
  }

  void _onSubmit(String value) {
    if (value.trim().isEmpty) return;
    _saveRecent(value.trim());
    context.push('/search?q=${Uri.encodeComponent(value.trim())}');
  }

  void _saveRecent(String query) {
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 8) _recentSearches = _recentSearches.take(8).toList();
    });
    // Save to local storage
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _onSubmit(suggestion);
  }

  void _openVoiceSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VoiceSearchModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final searchAsync = ref.watch(_searchProvider(_query));

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            flexibleSpace: CustomAppBar(
              title: 'Search',
              showSearch: true,
              onSearchTap: () {},
            ),
          ),
          // Search input bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search atta, milk, soap…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: () => _controller.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                      IconButton(
                        onPressed: _openVoiceSearch,
                        icon: const Icon(Icons.mic),
                      ),
                    ],
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _onSubmit,
              ),
            ),
          ),
          // Suggestions dropdown when typing
          if (_query.isNotEmpty)
            SliverToBoxAdapter(
              child: _SuggestionsDropdown(
                query: _query,
                onSelect: _selectSuggestion,
              ),
            ),
          // Results or empty state
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _EmptySearchView(
                recentSearches: _recentSearches,
                trending: _trending,
                onRecentTap: _selectSuggestion,
                onTrendingTap: _selectSuggestion,
                onClearRecent: () => setState(() => _recentSearches.clear()),
              ),
            )
          else
            searchAsync.when(
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
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Search failed: $e',
                      style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              data: (results) {
                if (results.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 64, color: colors.faint),
                            const SizedBox(height: 16),
                            Text('No results for "$_query"', style: AppTypography.body(theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
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
                        product: results[i],
                        variant: ProductVariant.grid,
                      ),
                      childCount: results.length,
                    ),
                  ),
                );
              },
            ),
          // Recent views rail at bottom
          SliverToBoxAdapter(
            child: _RecentViewsRail(),
          ),
        ],
      ),
    );
  }
}

/// Search provider.
final _searchProvider = FutureProvider.autoDispose.family<List<Product>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.read(searchRepositoryProvider);
  final result = await repo.search(query);
  return result.results;
});

/// Suggestions dropdown.
class _SuggestionsDropdown extends ConsumerWidget {
  const _SuggestionsDropdown({
    required this.query,
    required this.onSelect,
  });

  final String query;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final suggestionsAsync = ref.watch(_suggestionsProvider(query));

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((s) => ListTile(
              title: Text(s, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
              trailing: Icon(Icons.north_west, color: theme.colorScheme.onSurfaceVariant),
              onTap: () => onSelect(s),
            )).toList(),
          ),
        );
      },
    );
  }
}

final _suggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  final repo = ref.read(searchRepositoryProvider);
  return repo.getSuggestions(query);
});

/// Empty search view with recent + trending.
class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView({
    required this.recentSearches,
    required this.trending,
    required this.onRecentTap,
    required this.onTrendingTap,
    required this.onClearRecent,
  });

  final List<String> recentSearches;
  final List<String> trending;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onTrendingTap;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Text('Recent Searches', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                const Spacer(),
                TextButton(onPressed: onClearRecent, child: Text('Clear', style: AppTypography.label(colors.marigold))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentSearches.map((s) => ActionChip(
                label: Text(s, style: AppTypography.body(theme.colorScheme.onSurface)),
                onPressed: () => onRecentTap(s),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (trending.isNotEmpty) ...[
            Text('Trending Searches', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            ...trending.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onTrendingTap(e.value),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: AppTypography.tabularNumber(colors.primary, size: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.value, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.marigoldWash,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '12 MIN',
                          style: AppTypography.tabularSmall(colors.marigold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),
          ],
          Text('Popular in Your Neighborhood', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: colors.sunken,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent views rail.
class _RecentViewsRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recently Viewed', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 148,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colors.sunken,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voice Search Modal.
class _VoiceSearchModal extends StatelessWidget {
  const _VoiceSearchModal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                Text('Voice Search', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic, size: 48, color: colors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Listening... say "Avocado" or "Gir cow milk"',
                    style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      'Organic Hass Avocado',
                      'A2 Gir Cow Milk',
                      'Country Sourdough Loaf',
                    ].map((s) => ActionChip(
                      label: Text(s, style: AppTypography.body(theme.colorScheme.onSurface)),
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to search with this query
                      },
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}