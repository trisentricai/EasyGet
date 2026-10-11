import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/catalog_models.dart';

/// S6 · Search data: live suggestions, paged results (via the catalog
/// `POST /search/`), plus local-only recents + recent views (session memory,
/// never the server).
abstract class SearchRepository {
  /// Live suggestions for [query]. Queries shorter than 2 chars return []
  /// without touching the network (backend minimum).
  Future<List<String>> suggestions(String query, {CancelToken? cancelToken});

  Future<CatalogPage> results(String query, {int page = 1});
}

class HttpSearchRepository implements SearchRepository {
  HttpSearchRepository(this._api, this._catalog);

  final ApiClient _api;
  final CatalogRepository _catalog;

  @override
  Future<List<String>> suggestions(String query,
      {CancelToken? cancelToken}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    return _api.get<List<String>>(
      ApiEndpoints.searchSuggestions,
      query: {'q': q},
      cancelToken: cancelToken,
      decode: (json) {
        final Object? list = json is List
            ? json
            : (json is Map
                ? (json['suggestions'] ?? json['results'] ?? const [])
                : const []);
        return (list as List).map((e) => '$e').toList();
      },
    );
  }

  @override
  Future<CatalogPage> results(String query, {int page = 1}) =>
      _catalog.search(query.trim(), page: page);
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return HttpSearchRepository(
    ref.watch(apiClientProvider),
    ref.watch(catalogRepositoryProvider),
  );
});

/// Recent submitted searches, newest first, capped at 10.
class SearchHistoryController extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return;
    state = [q, ...state.where((e) => e != q)].take(10).toList();
  }

  void clear() => state = const [];
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryController, List<String>>(
  SearchHistoryController.new,
);

/// Recently viewed products, newest first, capped at 10. Recorded by the PDP
/// (S7) on open.
class RecentlyViewedController extends Notifier<List<CatalogProduct>> {
  @override
  List<CatalogProduct> build() => const [];

  void viewed(CatalogProduct product) {
    state = [
      product,
      ...state.where((e) => e.slug != product.slug),
    ].take(10).toList();
  }

  void clear() => state = const [];
}

final recentlyViewedProvider =
    NotifierProvider<RecentlyViewedController, List<CatalogProduct>>(
  RecentlyViewedController.new,
);