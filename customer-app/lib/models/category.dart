/// Category model matching backend serializer.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.parent,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? image;
  final String? parent;
  final int itemCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        image: json['image']?.toString(),
        parent: json['parent']?.toString(),
        itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      );
}