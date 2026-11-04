import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/banner.dart';
import '../../../models/coupon.dart';

/// Home/Storefront repository: hero, banners, sections, rails.
class StorefrontRepository {
  StorefrontRepository(this._api);

  final ApiClient _api;

  Future<StorefrontData> getStorefront() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.storefront,
      decode: (j) => j as Map<String, dynamic>,
    );
    return StorefrontData.fromJson(data);
  }

  Future<List<Banner>> getBanners() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.banners,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Banner.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Coupon>> getActiveCoupons() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.couponsActive,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class StorefrontData {
  StorefrontData({
    required this.sections,
    required this.items,
    required this.theme,
  });

  final List<StorefrontSection> sections;
  final List<StorefrontItem> items;
  final StorefrontTheme theme;

  factory StorefrontData.fromJson(Map<String, dynamic> json) => StorefrontData(
        sections: (json['sections'] as List? ?? [])
            .map((e) => StorefrontSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        items: (json['items'] as List? ?? [])
            .map((e) => StorefrontItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        theme: StorefrontTheme.fromJson(json['theme'] as Map<String, dynamic>? ?? {}),
      );
}

class StorefrontSection {
  StorefrontSection({
    required this.id,
    required this.type,
    required this.order,
    required this.config,
  });

  final String id;
  final String type;
  final int order;
  final Map<String, dynamic> config;

  factory StorefrontSection.fromJson(Map<String, dynamic> json) =>
      StorefrontSection(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        config: json['config'] as Map<String, dynamic>? ?? {},
      );
}

class StorefrontItem {
  StorefrontItem({
    required this.id,
    required this.sectionId,
    required this.productId,
    required this.order,
    required this.style,
  });

  final String id;
  final String sectionId;
  final String productId;
  final int order;
  final Map<String, dynamic> style;

  factory StorefrontItem.fromJson(Map<String, dynamic> json) =>
      StorefrontItem(
        id: json['id']?.toString() ?? '',
        sectionId: json['section']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        style: json['style'] as Map<String, dynamic>? ?? {},
      );
}

class StorefrontTheme {
  StorefrontTheme({
    this.primaryColor,
    this.accentColor,
    this.fontFamily,
  });

  final String? primaryColor;
  final String? accentColor;
  final String? fontFamily;

  factory StorefrontTheme.fromJson(Map<String, dynamic> json) =>
      StorefrontTheme(
        primaryColor: json['primary_color']?.toString(),
        accentColor: json['accent_color']?.toString(),
        fontFamily: json['font_family']?.toString(),
      );
}

final storefrontRepositoryProvider = Provider<StorefrontRepository>((ref) {
  return StorefrontRepository(ref.watch(apiClientProvider));
});
