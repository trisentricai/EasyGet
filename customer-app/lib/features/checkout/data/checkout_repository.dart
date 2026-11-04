import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/address.dart';

/// Checkout repository: addresses, payment methods, order placement.
class CheckoutRepository {
  CheckoutRepository(this._api);

  final ApiClient _api;

  Future<List<Address>> getAddresses() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.addresses,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.paymentMethods,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentIntentResponse> createPaymentIntent({
    required String orderId,
    required String gateway,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.paymentIntent,
      body: {'order_id': orderId, 'gateway': gateway},
      decode: (j) => j as Map<String, dynamic>,
    );
    return PaymentIntentResponse.fromJson(data);
  }

  Future<PaymentConfirmResponse> confirmPayment({
    required String intentId,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.paymentConfirm,
      body: {'intent_id': intentId, 'payload': payload},
      decode: (j) => j as Map<String, dynamic>,
    );
    return PaymentConfirmResponse.fromJson(data);
  }
}

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

class PaymentIntentResponse {
  PaymentIntentResponse({
    required this.intentId,
    required this.clientSecret,
    this.gatewayData,
  });

  final String intentId;
  final String clientSecret;
  final Map<String, dynamic>? gatewayData;

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) =>
      PaymentIntentResponse(
        intentId: json['intent_id']?.toString() ?? '',
        clientSecret: json['client_secret']?.toString() ?? '',
        gatewayData: json['gateway_data'] as Map<String, dynamic>?,
      );
}

class PaymentConfirmResponse {
  PaymentConfirmResponse({
    required this.success,
    this.message,
    this.orderId,
  });

  final bool success;
  final String? message;
  final String? orderId;

  factory PaymentConfirmResponse.fromJson(Map<String, dynamic> json) =>
      PaymentConfirmResponse(
        success: json['success'] ?? false,
        message: json['message']?.toString(),
        orderId: json['order_id']?.toString(),
      );
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(apiClientProvider));
});
