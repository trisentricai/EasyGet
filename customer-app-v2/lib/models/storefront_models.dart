import 'catalog_models.dart';

/// Identity/header data for a rendered storefront.
class StoreInfo {
  const StoreInfo({
    required this.id,
    required this.name,
    required this.slug,
    this.city = '',
    this.description = '',
  });

  final int id;
  final String name;
  final String slug;
  final String city;
  final String description;

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
        id: numToInt(json['id']),
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        description: (json['description'] ?? '') as String,
      );
}

/// Visual theme for a storefront. Colors arrive as hex strings; renderers
/// convert to [Color] at the boundary, never here.
class StoreTheme {
  const StoreTheme({
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.fontFamily,
    this.logo,
    this.heroImage,
    this.buttonStyle,
    this.raw = const {},
  });

  final String? primaryColor;
  final String? secondaryColor;
  final String? backgroundColor;
  final String? fontFamily;
  final String? logo;
  final String? heroImage;
  final String? buttonStyle;
  final Map<String, dynamic> raw;

  factory StoreTheme.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return StoreTheme(
      primaryColor: map['primary_color'] as String?,
      secondaryColor: map['secondary_color'] as String?,
      backgroundColor: map['background_color'] as String?,
      fontFamily: map['font_family'] as String?,
      logo: map['logo'] as String?,
      heroImage: map['hero_image'] as String?,
      buttonStyle: map['button_style'] as String?,
      raw: map.cast<String, dynamic>(),
    );
  }
}

/// One item inside a storefront section (product/category/banner slot).
class SectionItem {
  const SectionItem({
    required this.id,
    this.itemType,
    this.productSlug,
    this.productPrice = 0,
    this.categorySlug,
    this.caption,
    this.image,
    this.link,
    this.config = const {},
  });

  final int id;
  final String? itemType;
  final String? productSlug;
  final double productPrice;
  final String? categorySlug;
  final String? caption;
  final String? image;
  final String? link;
  final Map<String, dynamic> config;

  factory SectionItem.fromJson(Map<String, dynamic> json) => SectionItem(
        id: numToInt(json['id']),
        itemType: json['item_type'] as String?,
        productSlug: json['product_slug'] as String?,
        productPrice: numToDouble(json['product_price']),
        categorySlug: json['category_slug'] as String?,
        caption: json['caption'] as String?,
        image: json['image'] as String?,
        link: json['link'] as String?,
        config: (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// A rendered storefront section (HERO, BANNER, CATEGORY_GRID, PRODUCT_ROW,
/// IMAGE_GALLERY, RICH_TEXT).
class StorefrontSection {
  const StorefrontSection({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.image,
    this.config = const {},
    this.items = const [],
  });

  final int id;
  final String type;
  final String? title;
  final String? subtitle;
  final String? image;
  final Map<String, dynamic> config;
  final List<SectionItem> items;

  factory StorefrontSection.fromJson(Map<String, dynamic> json) =>
      StorefrontSection(
        id: numToInt(json['id']),
        type: (json['type'] ?? '') as String,
        title: json['title'] as String?,
        subtitle: json['subtitle'] as String?,
        image: json['image'] as String?,
        config: (json['config'] as Map?)?.cast<String, dynamic>() ?? const {},
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SectionItem.fromJson)
            .toList(),
      );
}

/// Scrolling marquee strip.
class Ticker {
  const Ticker({
    required this.items,
    this.speed = 40,
    this.color,
    this.bg,
    this.symbol,
    this.fontSize,
    this.radius,
  });

  final List<String> items;
  final int speed;
  final String? color;
  final String? bg;
  final String? symbol;
  final double? fontSize;
  final double? radius;

  factory Ticker.fromJson(Map<String, dynamic> json) => Ticker(
        items: ((json['items'] as List?) ?? const []).map((e) => '$e').toList(),
        speed: numToInt(json['speed'], 40),
        color: json['color'] as String?,
        bg: json['bg'] as String?,
        symbol: json['symbol'] as String?,
        fontSize:
            json['font_size'] == null ? null : numToDouble(json['font_size']),
        radius: json['radius'] == null ? null : numToDouble(json['radius']),
      );
}

/// Full storefront render for `/storefront/platform/` or
/// `/storefront/{slug}/`.
class StorefrontRender {
  const StorefrontRender({
    required this.store,
    required this.theme,
    this.sections = const [],
    this.ticker,
  });

  final StoreInfo store;
  final StoreTheme theme;
  final List<StorefrontSection> sections;
  final Ticker? ticker;

  factory StorefrontRender.fromJson(Map<String, dynamic> json) =>
      StorefrontRender(
        store: StoreInfo.fromJson(
          (json['store'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        theme: StoreTheme.fromJson((json['theme'] as Map?)?.cast<String, dynamic>()),
        sections: ((json['sections'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StorefrontSection.fromJson)
            .toList(),
        ticker: json['ticker'] is Map<String, dynamic>
            ? Ticker.fromJson(json['ticker'] as Map<String, dynamic>)
            : null,
      );
}