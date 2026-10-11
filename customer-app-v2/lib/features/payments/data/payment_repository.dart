import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/payment_model.dart';

/// Payments (v1: COD + UPI-on-delivery; direct create, no intent/confirm).
abstract class PaymentRepository {
  Future<List<PaymentMethod>> methods();

  Future<Payment> createForOrder({
    required int order,
    required String gateway,
    required num amount,
    int? paymentMethodId,
  });
}

class HttpPaymentRepository implements PaymentRepository {
  HttpPaymentRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PaymentMethod>> methods() async {
    final json = await _api.get<dynamic>(ApiEndpoints.paymentMethods);
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(PaymentMethod.fromJson)
        .toList();
  }

  @override
  Future<Payment> createForOrder({
    required int order,
    required String gateway,
    required num amount,
    int? paymentMethodId,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.paymentBase,
      body: {
        'order': order,
        'gateway': gateway,
        'amount': amount,
        'payment_method_id': ?paymentMethodId,
      },
      decode: (j) => (j as Map<String, dynamic>),
    );
    return Payment.fromJson(json);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return HttpPaymentRepository(ref.watch(apiClientProvider));
});