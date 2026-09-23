import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'catalog_repository.dart';

class SearchResult {
  SearchResult({required this.items, required this.total});

  final List<Product> items;
  final int total;
}

class SearchRepository {
  SearchRepository(this._api, this._catalog);

  final ApiClient _api;
  final CatalogRepository _catalog;

  /// Backend full-text search with graceful client-side fallback
  /// (mirrors the web shop behaviour on SQLite-backed backends).
  Future<SearchResult> search({required String q, String? sort}) async {
    try {
      final json = await _api.post<Map<String, dynamic>>(
        '/search/',
        body: {'q': q, if (sort != null) 'sort': sort},
        decode: (j) => j as Map<String, dynamic>,
      );
      final results = (json['results'] as List? ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return SearchResult(
        items: results,
        total: (json['total'] as num?)?.toInt() ?? results.length,
      );
    } catch (_) {
      final all = await _catalog.allProducts();
      final needle = q.trim().toLowerCase();
      final matched = needle.isEmpty
          ? all
          : all.where((p) {
              return p.name.toLowerCase().contains(needle) ||
                  p.brand.toLowerCase().contains(needle) ||
                  (p.category?.name.toLowerCase().contains(needle) ?? false);
            }).toList();
      return SearchResult(items: matched.take(40).toList(), total: matched.length);
    }
  }

  Future<List<String>> suggestions(String q) async {
    try {
      final json = await _api.get<dynamic>('/search/suggestions/', query: {'q': q});
      if (json is List) return json.map((e) => e.toString()).toList();
      return [];
    } catch (_) {
      return [];
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    ref.watch(apiClientProvider),
    ref.watch(catalogRepositoryProvider),
  );
});
