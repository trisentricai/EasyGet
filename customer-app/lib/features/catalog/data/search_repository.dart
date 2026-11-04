import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/product.dart';

/// Search repository: debounced search, suggestions, trending.
class SearchRepository {
  SearchRepository(this._api);

  final ApiClient _api;

  Future<SearchResult> search(String query) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.search,
      query: {'q': query},
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = (data['results'] as List? ?? [])
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    final suggestions = (data['suggestions'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    return SearchResult(
      results: results,
      suggestions: suggestions,
      total: (data['total'] as num?)?.toInt() ?? results.length,
    );
  }

  Future<List<String>> getSuggestions(String query) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.searchSuggestions,
      query: {'q': query},
      decode: (j) => j as Map<String, dynamic>,
    );
    return (data['results'] as List? ?? data as List)
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> getTrending() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.searchTrending,
      decode: (j) => j as Map<String, dynamic>,
    );
    return (data['results'] as List? ?? data as List)
        .map((e) => e.toString())
        .toList();
  }
}

class SearchResult {
  SearchResult({
    required this.results,
    required this.suggestions,
    required this.total,
  });

  final List<Product> results;
  final List<String> suggestions;
  final int total;
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});
