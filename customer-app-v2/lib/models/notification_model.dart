/// A notification row (`GET /notifications/`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body = '',
    this.type,
    this.isRead = false,
    this.createdAt,
    this.data = const {},
  });

  final int id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        type: json['type'] as String?,
        isRead: json['is_read'] == true,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}