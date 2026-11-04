/// Delivery address model matching backend serializer.
class Address {
  Address({
    required this.id,
    required this.type,
    required this.label,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    required this.phone,
    this.isDefault = false,
    this.coordinates,
  });

  final String id;
  final String type; // 'Home' | 'Work' | 'Other'
  final String label;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final String phone;
  final bool isDefault;
  final AddressCoordinates? coordinates;

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Home',
        label: json['label']?.toString() ?? '',
        street: json['street']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isDefault: json['is_default'] ?? false,
        coordinates: json['coordinates'] != null
            ? AddressCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>)
            : null,
      );

  String get fullAddress => '$street, $area, $city - $pincode';
}

class AddressCoordinates {
  AddressCoordinates({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory AddressCoordinates.fromJson(Map<String, dynamic> json) => AddressCoordinates(
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      );
}