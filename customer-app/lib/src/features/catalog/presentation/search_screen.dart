import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/states.dart';
import '../data/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _q =
      TextEditingController(text: widget.initialQuery ?? '');
  Timer? _debounce;
  List<String> _suggest = [];
  bool _showSuggest = false;

  AsyncValue<SearchResult>? _result;

  @override
  void dispose() {
    _q.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _suggest = [];
        _showSuggest = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final s = await ref
          .read(searchRepositoryProvider)
          .suggestions(v.trim());
      if (mounted) {
        setState(() {
          _suggest = s;
          _showSuggest = s.isNotEmpty;
        });
      }
    });
  }

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showSuggest = false;
      _result = const AsyncLoading();
    });
    final value = await AsyncValue.guard(
      () => ref.read(searchRepositoryProvider).search(q: _q.text.trim()),
    );
    if (mounted) setState(() => _result = value);
  }

  @override
  void initState() {
    super.initState();
    if ((widget.initialQuery ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              controller: _q,
              hintText: 'Search products, brands…',
              leading: const Icon(Icons.search_outlined),
              trailing: [
                if (_q.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _q.clear();
                      _onChanged('');
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (v) {
                _onChanged(v);
                setState(() {});
              },
              onSubmitted: (_) => _run(),
            ),
          ),
          if (_showSuggest)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggest
                    .map(
                      (s) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.north_west_rounded, size: 18),
                        title: Text(s,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          _q.text = s;
                          _run();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: res == null
                ? const EmptyState(
                    icon: Icons.search_outlined,
                    title: 'Find anything',
                    text: 'Try “rice”, “soap” or a brand name.',
                  )
                : res.when(
                    loading: () => const LoadingGrid(),
                    error: (e, _) => ErrorState(
                        message: e.toString(), onRetry: _run),
                    data: (r) {
                      if (r.items.isEmpty) {
                        return const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'No matches',
                          text: 'Try a different spelling or word.',
                        );
                      }
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Text(
                                '${r.total} result${r.total == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => ProductCard(
                                  product: r.items[i],
                                  onTap: () => context.push(
                                      '/product/${r.items[i].slug}'),
                                ),
                                childCount: r.items.length,
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
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
