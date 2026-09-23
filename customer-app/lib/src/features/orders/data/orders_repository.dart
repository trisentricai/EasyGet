import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class OrderLine {
  OrderLine({
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String productName;
  final String variantName;
  final String sku;
  final String unitPrice;
  final int quantity;
  final String lineTotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        productName: (json['product_name'] ?? '') as String,
        variantName: (json['variant_name'] ?? '') as String,
        sku: (json['sku'] ?? '') as String,
        unitPrice: (json['unit_price'] ?? '0').toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        lineTotal: (json['line_total'] ?? '0').toString(),
      );
}

class StatusEvent {
  StatusEvent({required this.from, required this.to, required this.at, this.note = ''});

  final String from;
  final String to;
  final String at;
  final String note;

  factory StatusEvent.fromJson(Map<String, dynamic> json) => StatusEvent(
        from: (json['from_status'] ?? '') as String,
        to: (json['to_status'] ?? '') as String,
        at: (json['created_at'] ?? '') as String,
        note: (json['note'] ?? '') as String,
      );
}

class Order {
  Order({
    required this.id,
    required this.number,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.createdAt,
    this.storeName,
    this.itemCount = 0,
    this.items = const [],
    this.history = const [],
    this.instructions = '',
  });

  final String id;
  final String number;
  final String status;
  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String total;
  final String createdAt;
  final String? storeName;
  final int itemCount;
  final List<OrderLine> items;
  final List<StatusEvent> history;
  final String instructions;

  bool get cancellable => status == 'PENDING' || status == 'CONFIRMED';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] ?? '').toString(),
        number: (json['order_number'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        subtotal: (json['subtotal'] ?? '0').toString(),
        deliveryFee: (json['delivery_fee'] ?? '0').toString(),
        discount: (json['discount'] ?? '0').toString(),
        total: (json['total'] ?? '0').toString(),
        createdAt: (json['created_at'] ?? '') as String,
        storeName: json['store_name'] as String?,
        itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
        items: ((json['items'] as List?) ?? [])
            .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: ((json['status_history'] as List?) ?? [])
            .map((e) => StatusEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        instructions: (json['delivery_instructions'] ?? '') as String,
      );
}

class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<List<Order>> list() async {
    final json = await _api.get<dynamic>('/orders/');
    final list = json is List ? json : (json as Map)['results'] as List? ?? [];
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> detail(String id) => _api.get<Order>(
        '/orders/$id/',
        decode: (j) => Order.fromJson(j as Map<String, dynamic>),
      );

  Future<Order> cancel({required String id, required String reason}) =>
      _api.post<Order>(
        '/orders/$id/cancel/',
        body: {'reason': reason},
        decode: (j) => Order.fromJson(j as Map<String, dynamic>),
      );
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});
