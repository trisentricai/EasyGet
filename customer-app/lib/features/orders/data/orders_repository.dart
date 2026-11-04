import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/order.dart';

/// Orders repository: order history, placement, tracking, cancellation.
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<List<Order>> getOrders() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orders,
      decode: (j) => j as Map<String, dynamic>,
    );
    final results = data['results'] as List? ?? data as List;
    return results.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(String id) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail(id),
      decode: (j) => j as Map<String, dynamic>,
    );
    return Order.fromJson(data);
  }

  Future<Order> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? couponCode,
    String? slot,
    int? riderTip,
    List<String>? instructions,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      body: {
        'address_id': addressId,
        'payment_method': paymentMethod,
        if (couponCode != null) 'coupon_code': couponCode,
        if (slot != null) 'slot': slot,
        if (riderTip != null) 'rider_tip': riderTip,
        if (instructions != null) 'delivery_instructions': instructions,
      },
      decode: (j) => j as Map<String, dynamic>,
    );
    return Order.fromJson(data);
  }

  Future<void> cancelOrder(String id, {String? reason}) async {
    await _api.post<dynamic>(
      ApiEndpoints.orderCancelDetail(id),
      body: {'reason': reason ?? ''},
    );
  }

  Future<OrderTracking> trackOrder(String id) async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderTrackDetail(id),
      decode: (j) => j as Map<String, dynamic>,
    );
    return OrderTracking.fromJson(data);
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

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});
