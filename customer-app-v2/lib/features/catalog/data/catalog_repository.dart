import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/catalog_models.dart';
import '../../../models/pincode_model.dart';
import '../../../models/storefront_models.dart';

/// Everything the Discover screens + PDP read. Abstract so screens/controllers
/// can be driven by fakes in tests.
abstract class CatalogRepository {
  Future<CatalogPage> products({
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minDiscount,
    bool? isFeatured,
    String? sort,
    int? page,
  });

  Future<ProductDetail> product(String slug);

  Future<List<Category>> categories();

  Future<List<Brand>> brands();

  Future<CatalogPage> search(
    String query, {
    String? sort,
    int page = 1,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
  });

  Future<PincodeInfo> pincode(String code);

  Future<StorefrontRender> platformStorefront();

  Future<StorefrontRender> storefront(String slug);
}

class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);

  final ApiClient _api;

  @override
  Future<CatalogPage> products({
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minDiscount,
    bool? isFeatured,
    String? sort,
    int? page,
  }) async {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category;
    if (brand != null) query['brand'] = brand;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (minDiscount != null) query['min_discount'] = minDiscount;
    if (isFeatured != null) query['is_featured'] = isFeatured;
    if (sort != null) query['sort'] = sort;
    if (page != null) query['page'] = page;

    final json = await _api.get<dynamic>(
      ApiEndpoints.products,
      query: query.isEmpty ? null : query,
    );
    return CatalogPage.fromJson(json);
  }

  @override
  Future<ProductDetail> product(String slug) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.productDetail(slug),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return ProductDetail.fromJson(json);
  }

  @override
  Future<List<Category>> categories() async {
    final json = await _api.get<dynamic>(ApiEndpoints.categories);
    final rows = _rows(json);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  @override
  Future<List<Brand>> brands() async {
    final json = await _api.get<dynamic>(ApiEndpoints.brands);
    return _rows(json)
        .whereType<Map<String, dynamic>>()
        .map(Brand.fromJson)
        .toList();
  }

  @override
  Future<CatalogPage> search(
    String query, {
    String? sort,
    int page = 1,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
  }) async {
    final body = <String, dynamic>{'q': query, 'page': page};
    if (sort != null) body['sort'] = sort;
    if (category != null) body['category'] = category;
    if (minPrice != null) body['min_price'] = minPrice;
    if (maxPrice != null) body['max_price'] = maxPrice;
    if (isFeatured != null) body['is_featured'] = isFeatured;

    final json = await _api.post<dynamic>(ApiEndpoints.search, body: body);
    return CatalogPage.fromJson(json);
  }

  @override
  Future<PincodeInfo> pincode(String code) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.pincodeCheck(code),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return PincodeInfo.fromJson(json);
  }

  @override
  Future<StorefrontRender> platformStorefront() async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.storefrontPlatform,
      decode: (j) => (j as Map<String, dynamic>),
    );
    return StorefrontRender.fromJson(json);
  }

  @override
  Future<StorefrontRender> storefront(String slug) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.storefront(slug),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return StorefrontRender.fromJson(json);
  }

  List<dynamic> _rows(dynamic json) {
    if (json is Map && json['results'] is List) return json['results'] as List;
    if (json is List) return json;
    return const [];
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return HttpCatalogRepository(ref.watch(apiClientProvider));
});
