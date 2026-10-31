import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/order_models.dart';

/// Orders (list/detail/create/cancel/invoice). Abstract for fake tests.
abstract class OrdersRepository {
  Future<List<Order>> list();

  Future<OrderDetail> detail(int id);

  Future<Order> create({
    required int cartId,
    required String deliveryAddress,
    String? instructions,
  });

  Future<void> cancel(int id, String reason);

  Future<Map<String, dynamic>> invoice(int id);
}

class HttpOrdersRepository implements OrdersRepository {
  HttpOrdersRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Order>> list() async {
    final json = await _api.get<dynamic>(ApiEndpoints.orders);
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList();
  }

  @override
  Future<OrderDetail> detail(int id) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail('$id'),
      decode: (j) => (j as Map<String, dynamic>),
    );
    return OrderDetail.fromJson(json);
  }

  @override
  Future<Order> create({
    required int cartId,
    required String deliveryAddress,
    String? instructions,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      body: {
        'cart_id': cartId,
        'delivery_address': deliveryAddress,
        'delivery_instructions': ?instructions,
      },
      decode: (j) => (j as Map<String, dynamic>),
    );
    // Cart with items from multiple sellers splits into one order per tenant:
    // { "orders": [ ... ] }.
    final orders = (json['orders'] as List?) ?? const [];
    final first = orders.isNotEmpty ? orders.first : json;
    return Order.fromJson((first as Map).cast<String, dynamic>());
  }

  @override
  Future<void> cancel(int id, String reason) async {
    await _api.post<dynamic>(
      ApiEndpoints.ordersCancel('$id'),
      body: {'reason': reason},
    );
  }

  @override
  Future<Map<String, dynamic>> invoice(int id) => _api.get<Map<String, dynamic>>(
        ApiEndpoints.ordersInvoice('$id'),
        decode: (j) => (j as Map<String, dynamic>),
      );
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return HttpOrdersRepository(ref.watch(apiClientProvider));
});