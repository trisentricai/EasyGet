/// EasyGet Fresh Market — Product model matching backend serializer.
class Product {
  Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.weight,
    required this.price,
    required this.mrp,
    this.savingsText,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.stockQty,
    required this.isVeg,
    required this.image,
    this.gallery = const [],
    this.description = '',
    this.story = '',
    this.origin = '',
    this.shelfLife = '',
    this.dietaryTags = const [],
    this.nutrition = const [],
  });

  final String id;
  final String slug;
  final String name;
  final String category;
  final String weight;
  final int price;
  final int mrp;
  final String? savingsText;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int stockQty;
  final bool isVeg;
  final String image;
  final List<String> gallery;
  final String description;
  final String story;
  final String origin;
  final String shelfLife;
  final List<String> dietaryTags;
  final List<NutritionItem> nutrition;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        weight: json['weight']?.toString() ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        mrp: (json['mrp'] as num?)?.toInt() ?? 0,
        savingsText: json['savings_text']?.toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        inStock: json['in_stock'] ?? false,
        stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
        isVeg: json['is_veg'] ?? true,
        image: json['image']?.toString() ?? '',
        gallery: (json['gallery'] as List?)?.map((e) => e.toString()).toList() ?? [],
        description: json['description']?.toString() ?? '',
        story: json['story']?.toString() ?? '',
        origin: json['origin']?.toString() ?? '',
        shelfLife: json['shelf_life']?.toString() ?? '',
        dietaryTags: (json['dietary_tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        nutrition: (json['nutrition'] as List? ?? [])
            .map((e) => NutritionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NutritionItem {
  NutritionItem({required this.label, required this.value});

  final String label;
  final String value;

  factory NutritionItem.fromJson(Map<String, dynamic> json) => NutritionItem(
        label: json['label']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
      );
}