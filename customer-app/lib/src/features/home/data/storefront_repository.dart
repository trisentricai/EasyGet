import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class StoreTheme {
  StoreTheme({
    this.primary,
    this.secondary,
    this.background,
    this.font,
    this.buttonStyle = 'ROUNDED',
  });

  final String? primary;
  final String? secondary;
  final String? background;
  final String? font;
  final String buttonStyle;

  factory StoreTheme.fromJson(Map<String, dynamic> json) => StoreTheme(
        primary: json['primary_color'] as String?,
        secondary: json['secondary_color'] as String?,
        background: json['background_color'] as String?,
        font: json['font_family'] as String?,
        buttonStyle: (json['button_style'] ?? 'ROUNDED') as String,
      );
}

class SectionItem {
  SectionItem({
    required this.caption,
    this.productSlug,
    this.productPrice,
    this.categorySlug,
    this.image,
  });

  final String caption;
  final String? productSlug;
  final String? productPrice;
  final String? categorySlug;
  final String? image;

  String get label {
    if (caption.isNotEmpty) return caption;
    return 'Featured item';
  }

  factory SectionItem.fromJson(Map<String, dynamic> json) => SectionItem(
        caption: (json['caption'] ?? '') as String,
        productSlug: json['product_slug'] as String?,
        productPrice: json['product_price']?.toString(),
        categorySlug: json['category_slug'] as String?,
        image: json['image'] as String?,
      );
}

class StoreSection {
  StoreSection({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.items,
    this.columns = 2,
  });

  final int id;
  final String type;
  final String title;
  final String subtitle;
  final List<SectionItem> items;
  final int columns;

  factory StoreSection.fromJson(Map<String, dynamic> json) {
    final config = (json['config'] as Map?) ?? {};
    return StoreSection(
      id: (json['id'] as num).toInt(),
      type: (json['section_type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      columns: (config['columns'] as num?)?.toInt() ?? 2,
      items: ((json['items'] as List?) ?? [])
          .map((e) => SectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Storefront {
  Storefront({required this.name, required this.city, this.theme, this.sections = const []});

  final String name;
  final String city;
  final StoreTheme? theme;
  final List<StoreSection> sections;

  factory Storefront.fromJson(Map<String, dynamic> json) {
    final store = (json['store'] as Map?) ?? {};
    final themeJson = json['theme'];
    return Storefront(
      name: (store['name'] ?? 'EasyGet') as String,
      city: (store['city'] ?? '') as String,
      theme: themeJson is Map<String, dynamic> ? StoreTheme.fromJson(themeJson) : null,
      sections: ((json['sections'] as List?) ?? [])
          .map((e) => StoreSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorefrontRepository {
  StorefrontRepository(this._api);

  final ApiClient _api;

  Future<Storefront> load(String slug) => _api.get<Storefront>(
        '/storefront/$slug/',
        decode: (j) => Storefront.fromJson(j as Map<String, dynamic>),
      );
}

final storefrontRepositoryProvider = Provider<StorefrontRepository>((ref) {
  return StorefrontRepository(ref.watch(apiClientProvider));
});
