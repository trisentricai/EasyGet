import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/catalog_models.dart';

/// Result of a heart toggle: `{added, slug, count}`.
class WishlistToggle {
  const WishlistToggle({
    required this.added,
    required this.slug,
    this.count = 0,
  });

  final bool added;
  final String slug;
  final int count;

  factory WishlistToggle.fromJson(Map<String, dynamic> json) => WishlistToggle(
        added: json['added'] == true,
        slug: (json['slug'] ?? '') as String,
        count: numToInt(json['count']),
      );
}

/// Hearts-only wishlist (v1). Abstract for fake-driven tests.
abstract class WishlistRepository {
  /// Product slugs currently hearted.
  Future<List<String>> fetch();

  /// Full saved product rows for the wishlist screen.
  Future<List<CatalogProduct>> fetchProducts();

  /// Adds when [hearted] is false, removes when true; returns the new state.
  Future<WishlistToggle> toggle(String slug, {bool hearted = false});
}

class HttpWishlistRepository implements WishlistRepository {
  HttpWishlistRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<String>> fetch() async {
    final json = await _api.get<dynamic>(ApiEndpoints.wishlistBase);
    return _slugs(json);
  }

  @override
  Future<List<CatalogProduct>> fetchProducts() async {
    final json = await _api.get<dynamic>(ApiEndpoints.wishlistBase);
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(CatalogProduct.fromJson)
        .toList();
  }

  @override
  Future<WishlistToggle> toggle(String slug, {bool hearted = false}) async {
    final path = ApiEndpoints.wishlistItem(slug);
    final json = hearted
        ? await _api.delete<Map<String, dynamic>>(
            path,
            decode: (j) => (j as Map<String, dynamic>),
          )
        : await _api.post<Map<String, dynamic>>(
            path,
            decode: (j) => (j as Map<String, dynamic>),
          );
    return WishlistToggle.fromJson(json!);
  }

  List<String> _slugs(dynamic json) {
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .map((r) {
          if (r is String) return r;
          if (r is Map && r['slug'] is String) return r['slug'] as String;
          return null;
        })
        .whereType<String>()
        .toList();
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return HttpWishlistRepository(ref.watch(apiClientProvider));
});