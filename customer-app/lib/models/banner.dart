/// Banner model matching backend serializer.
class Banner {
  Banner({
    required this.id,
    required this.title,
    required this.image,
    this.link,
    this.position = 0,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String image;
  final String? link;
  final int position;
  final bool isActive;

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        link: json['link']?.toString(),
        position: (json['position'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] ?? true,
      );
}