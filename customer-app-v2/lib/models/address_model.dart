import 'catalog_models.dart';

/// Saved delivery address (`/users/me/addresses/`).
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
    this.isDefault = false,
  });

  final int id;
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: numToInt(json['id']),
        label: (json['label'] ?? '') as String,
        line1: (json['line1'] ?? '') as String,
        line2: (json['line2'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        state: (json['state'] ?? '') as String,
        postalCode: (json['postal_code'] ?? '') as String,
        country: (json['country'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        isDefault: json['is_default'] == true,
      );

  /// One-line summary for cards/checkout.
  String get singleLine => [
        line1,
        if (line2.isNotEmpty) line2,
        city,
        state,
        postalCode,
      ].where((p) => p.isNotEmpty).join(', ');
}

/// Editable address payload for create/update.
class AddressDraft {
  const AddressDraft({
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
  });

  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;

  Map<String, dynamic> toJson() => {
        'label': label,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
      };
}