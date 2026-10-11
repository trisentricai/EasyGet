import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../../models/catalog_models.dart';
import '../data/search_repository.dart';

/// S6 · Search interaction state: debounced suggestions (300ms, in-flight
/// cancelled) + submitted results (paged). Typing after a submit shows the
/// suggestion list until the next submit.
class SearchState {
  const SearchState({
    this.draft = '',
    this.query = '',
    this.suggestions = const [],
    this.suggestionsLoading = false,
    this.results = const [],
    this.page = 0,
    this.total = 0,
    this.pageSize = 20,
    this.hasMore = false,
    this.loadingResults = false,
    this.loadingMore = false,
    this.resultsError,
  });

  final String draft;
  final String query;
  final List<String> suggestions;
  final bool suggestionsLoading;
  final List<CatalogProduct> results;
  final int page;
  final int total;
  final int pageSize;
  final bool hasMore;
  final bool loadingResults;
  final bool loadingMore;
  final Object? resultsError;

  bool get submitted => query.isNotEmpty;
  bool get refining => submitted && draft != query;

  SearchState copyWith({
    String? draft,
    String? query,
    List<String>? suggestions,
    bool? suggestionsLoading,
    List<CatalogProduct>? results,
    int? page,
    int? total,
    int? pageSize,
    bool? hasMore,
    bool? loadingResults,
    bool? loadingMore,
    Object? Function()? resultsError,
  }) =>
      SearchState(
        draft: draft ?? this.draft,
        query: query ?? this.query,
        suggestions: suggestions ?? this.suggestions,
        suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
        results: results ?? this.results,
        page: page ?? this.page,
        total: total ?? this.total,
        pageSize: pageSize ?? this.pageSize,
        hasMore: hasMore ?? this.hasMore,
        loadingResults: loadingResults ?? this.loadingResults,
        loadingMore: loadingMore ?? this.loadingMore,
        resultsError:
            resultsError == null ? this.resultsError : resultsError(),
      );
}

/// Defensive "more available": trusts the server flag, but ALSO treats a
/// shortfall (shown < total) as more — unless the last page came back empty,
/// which always terminates the chain.
bool _hasMore(CatalogPage res, int accumulated) =>
    (res.hasMore || accumulated < res.total) && res.results.isNotEmpty;

class SearchController extends Notifier<SearchState> {
  static const debounce = Duration(milliseconds: 300);

  Timer? _debounce;
  CancelToken? _suggestToken;
  int _generation = 0;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _suggestToken?.cancel();
    });
    return const SearchState();
  }

  void setDraft(String value) {
    _debounce?.cancel();
    _suggestToken?.cancel();
    state = state.copyWith(
      draft: value,
      suggestions: const [],
      suggestionsLoading: false,
    );
    final q = value.trim();
    if (q.length < 2) return;
    state = state.copyWith(suggestionsLoading: true);
    _debounce = Timer(debounce, () => _fetchSuggestions(q));
  }

  Future<void> _fetchSuggestions(String q) async {
    final generation = ++_generation;
    final token = _suggestToken = CancelToken();
    try {
      final rows = await ref
          .read(searchRepositoryProvider)
          .suggestions(q, cancelToken: token);
      if (generation != _generation || state.draft.trim() != q) return;
      state = state.copyWith(suggestions: rows, suggestionsLoading: false);
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(
          suggestions: const [], suggestionsLoading: false);
    }
  }

  Future<void> submit(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    _suggestToken?.cancel();
    ref.read(searchHistoryProvider.notifier).add(q);
    state = state.copyWith(
      query: q,
      draft: q,
      suggestions: const [],
      suggestionsLoading: false,
      results: const [],
      page: 0,
      total: 0,
      hasMore: false,
      loadingResults: true,
      resultsError: () => null,
    );
    try {
      final res = await ref.read(searchRepositoryProvider).results(q);
      state = state.copyWith(
        results: res.results,
        page: res.page,
        total: res.total,
        pageSize: res.pageSize ?? res.results.length,
        hasMore: _hasMore(res, res.results.length),
        loadingResults: false,
      );
    } catch (e) {
      state = state.copyWith(
          loadingResults: false, resultsError: () => e);
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loadingResults) {
      return;
    }
    state = state.copyWith(loadingMore: true);
    try {
      final res = await ref
          .read(searchRepositoryProvider)
          .results(state.query, page: state.page + 1);
      final accumulated = [...state.results, ...res.results];
      state = state.copyWith(
        results: accumulated,
        page: res.page,
        total: res.total,
        pageSize: res.pageSize ?? state.pageSize,
        hasMore: _hasMore(res, accumulated.length),
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<void> retry() => submit(state.query);

  void clearSearch() {
    _debounce?.cancel();
    _suggestToken?.cancel();
    state = const SearchState();
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(
  SearchController.new,
);

final searchCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);