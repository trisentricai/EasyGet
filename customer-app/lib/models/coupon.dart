/// Coupon model matching backend serializer.
class Coupon {
  Coupon({
    required this.code,
    required this.title,
    required this.discountAmount,
    required this.minOrder,
    required this.description,
    required this.expiry,
    this.type = 'percentage',
    this.value = 0,
    this.isActive = true,
  });

  final String code;
  final String title;
  final int discountAmount;
  final int minOrder;
  final String description;
  final String expiry;
  final String type; // 'percentage' | 'fixed'
  final int value;
  final bool isActive;

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
        minOrder: (json['min_order'] as num?)?.toInt() ?? 0,
        description: json['description']?.toString() ?? '',
        expiry: json['expires_at']?.toString() ?? '',
        type: json['type']?.toString() ?? 'percentage',
        value: (json['value'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] ?? true,
      );
}