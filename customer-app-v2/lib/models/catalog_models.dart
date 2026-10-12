/// Numeric coercion tolerating the API's mixed shapes: DRF returns Decimals
/// as strings ("289.00"), ints, doubles, or null.
double numToDouble(Object? value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int numToInt(Object? value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? numToIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// `/products/brands/` row.
class Brand {
  const Brand({required this.id, required this.name, required this.slug, this.logo});

  final int id;
  final String name;
  final String slug;
  final String? logo;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: numToInt(json['id']),
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        logo: json['logo'] as String?,
      );
}

/// `/categories/` row (flat list).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parent,
    this.image,
    this.hasChildren = false,
    this.productCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final int? parent;
  final String? image;
  final bool hasChildren;
  final int productCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: numToInt(json['id']),
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        parent: numToIntOrNull(json['parent']),
        image: json['image'] as String?,
        hasChildren: json['has_children'] == true,
        productCount: numToInt(json['product_count']),
      );
}

/// Product as it appears in list/search payloads (no variants/images).
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    required this.mrp,
    required this.basePrice,
    this.discountPercent = 0,
    this.isFeatured = false,
    this.primaryImage,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String? brand;
  final double mrp;
  final double basePrice;
  final int discountPercent;
  final bool isFeatured;
  final String? primaryImage;
  final double ratingAvg;
  final int ratingCount;

  bool get hasDiscount => mrp > basePrice;

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final brand = json['brand'];
    return CatalogProduct(
      id: numToInt(json['id']),
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      brand: brand is Map
          ? (brand['name'] as String?)
          : brand as String?,
      mrp: numToDouble(json['mrp']),
      basePrice: numToDouble(json['base_price']),
      discountPercent: numToInt(json['discount_percent']),
      isFeatured: json['is_featured'] == true,
      primaryImage: json['primary_image'] as String?,
      ratingAvg: numToDouble(json['rating_avg']),
      ratingCount: numToInt(json['rating_count']),
    );
  }
}

/// A page of catalog products (from `/products/` or `POST /search/`).
class CatalogPage {
  const CatalogPage({
    required this.results,
    required this.total,
    required this.page,
    this.pageSize,
  });

  final List<CatalogProduct> results;
  final int total;
  final int page;
  final int? pageSize;

  bool get hasMore => page * (pageSize ?? results.length) < total;

  factory CatalogPage.fromJson(Object? json) {
    final map =
        json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rows = (map['results'] as List?) ??
        (json is List ? json : const <dynamic>[]);
    return CatalogPage(
      results: rows
          .whereType<Map<String, dynamic>>()
          .map(CatalogProduct.fromJson)
          .toList(),
      total: numToInt(map['total'], rows.length),
      page: numToInt(map['page'], 1),
      pageSize: numToIntOrNull(map['page_size']),
    );
  }
}

/// Coupon surfaced on the PDP (`offers[]`, top-5).
class Offer {
  const Offer({
    required this.code,
    this.name,
    this.description,
    this.discountType,
    this.discountValue = 0,
    this.maxDiscount,
  });

  final String code;
  final String? name;
  final String? description;
  final String? discountType;
  final double discountValue;
  final double? maxDiscount;

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        code: (json['code'] ?? '') as String,
        name: json['name'] as String?,
        description: json['description'] as String?,
        discountType: json['discount_type'] as String?,
        discountValue: numToDouble(json['discount_value']),
        maxDiscount: json['max_discount'] == null
            ? null
            : numToDouble(json['max_discount']),
      );
}

/// Buyable variant.
class Variant {
  const Variant({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.discountPercent = 0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? sku;
  final double price;
  final int discountPercent;
  final bool isActive;

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        id: numToInt(json['id']),
        name: (json['name'] ?? '') as String,
        sku: json['sku'] as String?,
        price: numToDouble(json['price']),
        discountPercent: numToInt(json['discount_percent']),
        isActive: json['is_active'] != false,
      );
}

/// PDP image with focal/zoom metadata for the storefront renderer.
class ProductImage {
  const ProductImage({
    required this.url,
    this.isPrimary = false,
    this.alignX = 0.5,
    this.alignY = 0.5,
    this.zoom = 1,
    this.effect,
    this.transitionMs,
  });

  final String url;
  final bool isPrimary;
  final double alignX;
  final double alignY;
  final double zoom;
  final String? effect;
  final int? transitionMs;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    // Live backend names the file key `image` (probed 2026-10-11); older
    // fixtures use `url`. Alignment arrives as percent (50) or fraction.
    final url = (json['image'] ?? json['url'] ?? '') as String;
    double align(Object? value, double fallback) {
      final parsed = numToDouble(value, fallback);
      if (parsed > 1) return (parsed / 100).clamp(0.0, 1.0);
      return parsed;
    }

    return ProductImage(
      url: url,
      isPrimary: json['is_primary'] == true,
      alignX: align(json['align_x'], 0.5),
      alignY: align(json['align_y'], 0.5),
      zoom: numToDouble(json['zoom'], 1),
      effect: json['effect'] as String?,
      transitionMs: numToIntOrNull(json['transition_ms']),
    );
  }
}

/// Full PDP payload.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    required this.mrp,
    required this.basePrice,
    this.discountPercent = 0,
    this.isFeatured = false,
    this.primaryImage,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.description = '',
    this.offers = const [],
    this.variants = const [],
    this.images = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? brand;
  final double mrp;
  final double basePrice;
  final int discountPercent;
  final bool isFeatured;
  final String? primaryImage;
  final double ratingAvg;
  final int ratingCount;
  final String description;
  final List<Offer> offers;
  final List<Variant> variants;
  final List<ProductImage> images;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(parse)
            .toList();
    final brand = json['brand'];
    return ProductDetail(
      id: numToInt(json['id']),
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      brand: brand is Map ? (brand['name'] as String?) : brand as String?,
      mrp: numToDouble(json['mrp']),
      basePrice: numToDouble(json['base_price']),
      discountPercent: numToInt(json['discount_percent']),
      isFeatured: json['is_featured'] == true,
      primaryImage: json['primary_image'] as String?,
      ratingAvg: numToDouble(json['rating_avg']),
      ratingCount: numToInt(json['rating_count']),
      description: (json['description'] ?? '') as String,
      offers: rows('offers', Offer.fromJson),
      variants: rows('variants', Variant.fromJson),
      images: rows('images', ProductImage.fromJson),
    );
  }
}