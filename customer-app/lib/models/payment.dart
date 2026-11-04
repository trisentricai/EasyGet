/// Payment method model matching backend serializer.
class PaymentMethod {
  PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    this.details,
    this.isDefault = false,
  });

  final String id;
  final String type; // 'upi' | 'card' | 'cod'
  final String name;
  final Map<String, dynamic>? details;
  final bool isDefault;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        details: json['details'] as Map<String, dynamic>?,
        isDefault: json['is_default'] ?? false,
      );
}