import 'catalog_models.dart';

/// Product review (`/products/{slug}/reviews/`).
class Review {
  const Review({
    required this.id,
    required this.rating,
    this.title = '',
    this.body = '',
    this.userName = '',
    this.verified = false,
    this.status,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String title;
  final String body;
  final String userName;
  final bool verified;
  final String? status;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: numToInt(json['id']),
        rating: numToInt(json['rating']),
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        userName: (json['user_name'] ?? json['author'] ?? '') as String,
        verified: json['verified'] == true,
        status: json['status'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}