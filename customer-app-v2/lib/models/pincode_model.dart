import 'catalog_models.dart';

/// `/pincode/{code}/` result. Fees arrive as strings and 404 means
/// "not serviceable" (surfaced upstream as an [ApiException]).
class PincodeInfo {
  const PincodeInfo({
    required this.valid,
    required this.pincode,
    this.city = '',
    this.state = '',
    this.etaDays = 0,
    this.deliveryFee = 0,
    this.freeDeliveryOver = 0,
    this.source,
  });

  final bool valid;
  final String pincode;
  final String city;
  final String state;
  final int etaDays;
  final double deliveryFee;
  final double freeDeliveryOver;
  final String? source;

  factory PincodeInfo.fromJson(Map<String, dynamic> json) => PincodeInfo(
        valid: json['valid'] == true,
        pincode: (json['pincode'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        state: (json['state'] ?? '') as String,
        etaDays: numToInt(json['eta_days']),
        deliveryFee: numToDouble(json['delivery_fee']),
        freeDeliveryOver: numToDouble(json['free_delivery_over']),
        source: json['source'] as String?,
      );
}