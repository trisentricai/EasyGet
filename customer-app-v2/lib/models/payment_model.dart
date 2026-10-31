import 'catalog_models.dart';

/// Saved payment method (`GET /payments/methods/`).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.last4,
    this.upiId,
    this.gatewayToken,
  });

  final int id;

  /// CARD | UPI | WALLET | COD
  final String type;
  final String label;
  final String? last4;
  final String? upiId;
  final String? gatewayToken;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: numToInt(json['id']),
        type: (json['type'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        last4: json['last4'] as String?,
        upiId: json['upi_id'] as String?,
        gatewayToken: json['gateway_token'] as String?,
      );
}

/// Payment row returned by `POST /payments/` (direct create, no intent).
class Payment {
  const Payment({
    required this.id,
    required this.order,
    required this.gateway,
    required this.status,
    required this.amount,
    this.reference,
  });

  final int id;
  final int order;
  final String gateway;
  final String status;
  final double amount;
  final String? reference;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: numToInt(json['id']),
        order: numToInt(json['order']),
        gateway: (json['gateway'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        amount: numToDouble(json['amount']),
        reference: json['reference'] as String?,
      );
}