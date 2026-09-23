import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

String? absImg(String? path) {
  final url = AppConfig.mediaUrl(path);
  return (url == null || url.isEmpty) ? null : url;
}

class Category {
  Category({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
      );
}

class ProductVariant {
  ProductVariant({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.active,
  });

  final int id;
  final String name;
  final String sku;
  final String price;
  final bool active;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        sku: (json['sku'] ?? '') as String,
        price: (json['price'] ?? '0') as String,
        active: (json['is_active'] ?? true) as bool,
      );
}

class ProductImage {
  ProductImage({required this.url, required this.caption});

  final String url;
  final String caption;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        url: absImg(json['image'] as String?) ?? '',
        caption: (json['caption'] ?? '') as String,
      );
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.brand,
    this.category,
    this.mrp,
    this.basePrice,
    this.discountPercent = 0,
    this.featured = false,
    this.primaryImage,
    this.description = '',
    this.variants = const [],
    this.images = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String brand;
  final Category? category;
  final String? mrp;
  final String? basePrice;
  final int discountPercent;
  final bool featured;
  final String? primaryImage;
  final String description;
  final List<ProductVariant> variants;
  final List<ProductImage> images;

  factory Product.fromJson(Map<String, dynamic> json) {
    Category? cat;
    final rawCat = json['category'];
    if (rawCat is Map<String, dynamic>) cat = Category.fromJson(rawCat);
    String? img;
    final rawImg = json['primary_image'];
    if (rawImg is String) {
      img = absImg(rawImg);
    } else if (rawImg is Map<String, dynamic>) {
      img = absImg(rawImg['image'] as String?);
    }
    return Product(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      brand: (json['brand'] ?? '') as String,
      category: cat,
      mrp: json['mrp']?.toString(),
      basePrice: json['base_price']?.toString(),
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      featured: (json['is_featured'] ?? false) as bool,
      primaryImage: img,
      description: (json['description'] ?? '') as String,
      variants: (json['variants'] as List? ?? [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductPage {
  ProductPage({required this.items, required this.total, required this.hasMore});

  final List<Product> items;
  final int total;
  final bool hasMore;
}

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  static List<Product> _asList(dynamic json) {
    if (json is List) {
      return json.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    final results = (json as Map<String, dynamic>)['results'] as List? ?? [];
    return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductPage> products({
    String? category,
    String? sort,
    String? minPrice,
    String? maxPrice,
    bool featured = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (minPrice != null && minPrice.isNotEmpty) params['min_price'] = minPrice;
    if (maxPrice != null && maxPrice.isNotEmpty) params['max_price'] = maxPrice;
    if (featured) params['is_featured'] = 'true';
    final json = await _api.get<dynamic>('/products/', query: params);
    if (json is List) {
      final items = _asList(json);
      return ProductPage(items: items, total: items.length, hasMore: false);
    }
    final map = json as Map<String, dynamic>;
    final items = _asList(map);
    final total = (map['count'] as num?)?.toInt() ?? items.length;
    return ProductPage(
      items: items,
      total: total,
      hasMore: map['next'] != null,
    );
  }

  /// Whole catalog for client-side fallback paths (capped page walk).
  Future<List<Product>> allProducts({int pageSize = 100, int maxPages = 10}) async {
    final out = <Product>[];
    for (var page = 1; page <= maxPages; page++) {
      final chunk = await products(page: page, pageSize: pageSize);
      out.addAll(chunk.items);
      if (!chunk.hasMore) break;
    }
    return out;
  }

  Future<Product> product(String slug) => _api.get<Product>(
        '/products/$slug/',
        decode: (j) => Product.fromJson(j as Map<String, dynamic>),
      );

  Future<List<Category>> categories() async {
    final json = await _api.get<dynamic>('/categories/');
    final list = json is List ? json : (json as Map)['results'] as List? ?? [];
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> stores() async {
    final json = await _api.get<dynamic>('/stores/');
    final list = json is List ? json : (json as Map)['results'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});
