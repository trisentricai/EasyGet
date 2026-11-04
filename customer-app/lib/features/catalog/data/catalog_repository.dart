import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';

/// Catalog repository: products, categories, brands, search.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<Product>> getProducts({
    String? category,
    String? brand,
    int? minPrice,
    int? maxPrice,
    bool? discount,
    String? sort,
    int page = 1,
  }) async {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category;
    if (brand != null) query['brand'] = brand;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (discount != null) query['discount'] = discount;
    if (sort != null) query['sort'] = sort;
    query['page'] = page;

    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      query: query,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? [];
    return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> getProduct(String slug) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.productDetail(slug),
      decode: (j) => j as Map<String, dynamic>,
    );
    return Product.fromJson(data);
  }

  Future<List<Category>> getCategories() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> getBrands() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.brands,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => e['name']?.toString() ?? e.toString()).toList();
  }

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

  Future<List<String>> searchSuggestions(String query) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.searchSuggestions,
      query: {'q': query},
      decode: (j) => j as Map<String, dynamic>,
    );
    return (data['results'] as List? ?? data as List)
        .map((e) => e.toString())
        .toList();
  }

  Future<List<String>> searchTrending() async {
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

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});
