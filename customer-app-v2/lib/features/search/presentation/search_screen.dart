import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../catalog/presentation/widgets/category_tile.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../data/search_repository.dart';
import '../data/voice_search.dart';
import 'search_controller.dart';

/// S6 · Search (`/search?q=`, tab 3): autofocus field → recents + category
/// shortcuts when empty → debounced suggestions (300ms, in-flight cancelled)
/// → submitted results as a PLP grid → recent-views rail at the bottom.
/// Empty queries never render blank.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _field = TextEditingController();
  late final ScrollController _scroll = ScrollController()
    ..addListener(_onScroll);

  /// Last `?q=` the screen submitted from. Deep links submit once post-frame;
  /// afterwards the field owns the query.
  String? _lastRouteQuery;

  /// Last `?listen=` seen: `1` auto-starts voice search once per arrival.
  String? _lastListenFlag;

  /// True while the mic is hot. Stopped on dispose + on submit.
  bool _listening = false;

  /// Service captured at listen time so dispose() never touches `ref`
  /// (unsafe once the element deactivates).
  VoiceSearchService? _voiceService;

  @override
  void dispose() {
    unawaited(_voiceService?.stop());
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  void _clearAll() {
    _stopVoice();
    _field.clear();
    ref.read(searchControllerProvider.notifier).clearSearch();
  }

  Future<void> _startVoice() async {
    final service = ref.read(voiceSearchProvider);
    if (!await service.ensurePermission()) {
      if (!mounted) return;
      showAppSnackbar(context, 'Microphone is unavailable.');
      return;
    }
    if (!mounted) return;
    _voiceService = service;
    setState(() => _listening = true);
    await service.listen(onResult: (text, finalResult) {
      if (!mounted) return;
      _field.text = text;
      ref.read(searchControllerProvider.notifier).setDraft(text);
      if (finalResult) {
        _stopVoice();
        if (text.trim().isNotEmpty) {
          ref.read(searchControllerProvider.notifier).submit(text);
        }
      }
    });
  }

  void _stopVoice() {
    if (!_listening) return;
    setState(() => _listening = false);
    unawaited(_voiceService?.stop());
    _voiceService = null;
  }

  void _pickSuggestion(String term) {
    _field.text = term;
    ref.read(searchControllerProvider.notifier).submit(term);
  }

  Widget _content(SearchState state) {
    // Typing (submitted or not) surfaces the live suggestion list; the grid
    // only owns the screen when the draft matches the submitted query.
    if (!state.submitted && state.draft.trim().length < 2) {
      return const _EmptyMode();
    }
    if (!state.submitted || state.refining) {
      return _SuggestionsList(
        suggestions: state.suggestions,
        loading: state.suggestionsLoading,
        onPick: _pickSuggestion,
      );
    }
    return _ResultsView(state: state, controller: _scroll);
  }

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final routeQuery = (params['q'] ?? '').trim();
    if (routeQuery != _lastRouteQuery) {
      _lastRouteQuery = routeQuery;
      if (routeQuery.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _field.text = routeQuery;
            ref.read(searchControllerProvider.notifier).submit(routeQuery);
          }
        });
      }
    }
    final listenFlag = params['listen'] ?? '';
    if (listenFlag != _lastListenFlag) {
      _lastListenFlag = listenFlag;
      if (listenFlag == '1') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startVoice();
        });
      }
    }

    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
              child: _SearchField(
                controller: _field,
                listening: _listening,
                onChanged: (v) => ref
                    .read(searchControllerProvider.notifier)
                    .setDraft(v),
                onSubmitted: (v) => ref
                    .read(searchControllerProvider.notifier)
                    .submit(v),
                onClear: _clearAll,
                onMic: _listening ? _stopVoice : _startVoice,
              ),
            ),
            Expanded(child: _content(state)),
            if (state.submitted && !state.refining) _ViewsRail(compact: true),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.listening,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool listening;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Row(
            children: [
              Icon(Icons.search,
                  color: scheme.onSurfaceVariant, size: 22),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: TextField(
                  key: const Key('search-field'),
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: AppTypography.body(scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: listening
                        ? 'Listening…'
                        : 'Search atta, milk, soap…',
                    hintStyle:
                        AppTypography.body(scheme.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                key: const Key('search-mic'),
                onPressed: onMic,
                tooltip: listening ? 'Stop listening' : 'Voice search',
                icon: Icon(
                  listening ? Icons.stop_circle : Icons.mic_none,
                  color: listening
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, child) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        key: const Key('search-clear'),
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        color: scheme.onSurfaceVariant,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty query: recents → category shortcuts → recent views. Never blank:
//  falls back to a hint state when everything is empty.
class _EmptyMode extends ConsumerWidget {
  const _EmptyMode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    final categories = ref.watch(searchCategoriesProvider);
    final views = ref.watch(recentlyViewedProvider);
    final cats = categories.value ?? const [];

    if (history.isEmpty && cats.isEmpty && views.isEmpty) {
      return const EmptyState(
        title: 'Search the store',
        body: 'Type above to find atta, milk, soap and more.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            _RowLabel(
              label: 'Recent searches',
              actionLabel: 'Clear',
              onAction: () =>
                  ref.read(searchHistoryProvider.notifier).clear(),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final term in history)
                  AppChip(
                    label: term,
                    onTap: () => ref
                        .read(searchControllerProvider.notifier)
                        .submit(term),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          if (cats.isNotEmpty) ...[
            const _RowLabel(label: 'Browse categories'),
            const SizedBox(height: AppSpace.sm),
            // Trendy 2-column image grid (deliberately different from the
            // home track and the old row list): photo, scrim name, count.
            GridView.builder(
              key: const Key('search-category-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpace.md,
                crossAxisSpacing: AppSpace.md,
                childAspectRatio: 1.5,
              ),
              itemCount: cats.length,
              itemBuilder: (_, i) => CategoryGridCard(
                category: cats[i],
                onTap: () =>
                    context.go('/browse?category=${cats[i].slug}'),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
          ],
          if (views.isNotEmpty) ...[
            const SectionHeader(title: 'Recently viewed'),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 336,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: views.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpace.md),
                itemBuilder: (_, i) => ProductCard(
                  product: views[i],
                  density: ProductDensity.rail,
                  width: 148,
                  onTap: () =>
                      context.push('/product/${views[i].slug}'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.label, this.actionLabel, this.onAction});

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.productName(scheme.onSurface, size: 17)
                .copyWith(fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm, vertical: AppSpace.xs),
              child: Text(actionLabel!,
                  style: AppTypography.label(scheme.primary)),
            ),
          ),
      ],
    );
  }
}

/// Live suggestions (debounced). Tapping one submits it.
class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.loading,
    required this.onPick,
  });

  final List<String> suggestions;
  final bool loading;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading && suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpace.lg),
        child: Column(
          children: [
            SkeletonLine(),
            SizedBox(height: AppSpace.sm),
            SkeletonLine(),
            SizedBox(height: AppSpace.sm),
            SkeletonLine(width: 200),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: AppSpace.xxl),
      itemBuilder: (_, i) => ListTile(
        key: Key('suggestion-$i'),
        leading: Icon(Icons.search,
            size: 20, color: scheme.onSurfaceVariant),
        title: Text(suggestions[i],
            style: AppTypography.body(scheme.onSurface)),
        onTap: () => onPick(suggestions[i]),
      ),
    );
  }
}

/// Submitted results: count toolbar + 2-col grid + infinite scroll.
class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.state, required this.controller});

  final SearchState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (state.loadingResults) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: SkeletonGrid(count: 4),
        ),
      );
    }
    if (state.resultsError != null) {
      return ErrorState(
        body: 'We could not run that search.',
        onRetry: () =>
            ref.read(searchControllerProvider.notifier).retry(),
      );
    }
    if (state.results.isEmpty) {
      return EmptyState(
        title: 'No results for "${state.query}"',
        body: 'Check the spelling or try another search.',
        actionLabel: 'Clear search',
        onAction: () =>
            ref.read(searchControllerProvider.notifier).clearSearch(),
      );
    }

    final width =
        (MediaQuery.sizeOf(context).width - AppSpace.lg * 2 - AppSpace.md) / 2;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xs),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${state.total} results',
                style: AppTypography.tabularNumber(
                    scheme.onSurfaceVariant)),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(searchControllerProvider.notifier).retry(),
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.md),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpace.md,
                crossAxisSpacing: AppSpace.md,
                childAspectRatio: ProductCard.gridAspect(width),
              ),
              itemCount: state.results.length,
              itemBuilder: (_, i) {
                final product = state.results[i];
                return ProductCard(
                  product: product,
                  density: ProductDensity.grid,
                  width: width,
                  onTap: () =>
                      context.push('/product/${product.slug}'),
                );
              },
            ),
          ),
        ),
        _ResultsFooter(state: state),
      ],
    );
  }
}

/// End-of-list truth: explicit Show-more while items remain, a spinner
/// while loading, and an end marker when everything is on screen — the
/// list can never end silently at 20 again.
class _ResultsFooter extends ConsumerWidget {
  const _ResultsFooter({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    Widget body;
    if (state.loadingMore) {
      // Column, not row: the spinner sits on the true center line instead
      // of hanging left of its label.
      body = Column(
        key: const Key('search-loading-more'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: AppSpace.xs),
          Text('Loading more…',
              style:
                  AppTypography.body(scheme.onSurfaceVariant)),
        ],
      );
    } else if (state.hasMore) {
      body = TextButton(
        key: const Key('search-show-more'),
        onPressed: () =>
            ref.read(searchControllerProvider.notifier).loadMore(),
        child: Text(
          'Show more · ${state.results.length} of ${state.total}',
          style: AppTypography.label(scheme.primary, size: 14),
        ),
      );
    } else if (state.total > state.pageSize) {
      body = Text(
        key: const Key('search-end'),
        'You have seen all ${state.total} products',
        style: AppTypography.caption(scheme.onSurfaceVariant),
      );
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.sm),
      child: Center(child: body),
    );
  }
}

/// Recent-views rail pinned under submitted results.
class _ViewsRail extends ConsumerWidget {
  const _ViewsRail({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(recentlyViewedProvider);
    if (views.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 336,
      padding: const EdgeInsets.only(top: AppSpace.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SectionHeader(title: 'Recently viewed'),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg),
              itemCount: views.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpace.md),
              itemBuilder: (_, i) => ProductCard(
                product: views[i],
                density: ProductDensity.rail,
                width: 132,
                onTap: () =>
                    context.push('/product/${views[i].slug}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}