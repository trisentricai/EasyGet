import 'catalog_models.dart';

/// Order summary as it appears in `GET /orders/`. Pricing is server truth
/// (DESIGN §14) — the client never recomputes totals.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.createdAt,
    this.itemCount = 0,
  });

  final int id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final DateTime? createdAt;
  final int itemCount;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: numToInt(json['id']),
        orderNumber: (json['order_number'] ?? json['number'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        subtotal: numToDouble(json['subtotal']),
        deliveryFee: numToDouble(json['delivery_fee']),
        discount: numToDouble(json['discount']),
        total: numToDouble(json['total']),
        createdAt: _date(json['created_at']),
        itemCount: numToInt(json['item_count']),
      );
}

/// One line on an order (`items[]` of `GET /orders/{id}/`).
class OrderItem {
  const OrderItem({
    required this.id,
    required this.variantName,
    required this.variantLabel,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int id;
  final String variantName;
  final String variantLabel;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final variant = (json['variant'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final name = (variant['name'] ?? '') as String;
    return OrderItem(
      id: numToInt(json['id']),
      variantName: name,
      variantLabel: (variant['label'] ?? name) as String,
      quantity: numToInt(json['quantity']),
      unitPrice: numToDouble(json['unit_price']),
      lineTotal: numToDouble(json['line_total']),
    );
  }
}

/// One node of the order status timeline (`status_history[]`).
class OrderStatusEvent {
  const OrderStatusEvent({
    required this.from,
    required this.to,
    this.note,
    this.createdAt,
  });

  final String from;
  final String to;
  final String? note;
  final DateTime? createdAt;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        from: (json['from_status'] ?? '') as String,
        to: (json['to_status'] ?? '') as String,
        note: json['note'] as String?,
        createdAt: _date(json['created_at']),
      );
}

/// Full order (`GET /orders/{id}/`), adding items + timeline + timestamps.
class OrderDetail extends Order {
  const OrderDetail({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.subtotal,
    required super.deliveryFee,
    required super.discount,
    required super.total,
    super.createdAt,
    super.itemCount,
    this.items = const [],
    this.statusHistory = const [],
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  final List<OrderItem> items;
  final List<OrderStatusEvent> statusHistory;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
        id: numToInt(json['id']),
        orderNumber: (json['order_number'] ?? json['number'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        subtotal: numToDouble(json['subtotal']),
        deliveryFee: numToDouble(json['delivery_fee']),
        discount: numToDouble(json['discount']),
        total: numToDouble(json['total']),
        createdAt: _date(json['created_at']),
        itemCount: numToInt(json['item_count']),
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromJson)
            .toList(),
        statusHistory: ((json['status_history'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OrderStatusEvent.fromJson)
            .toList(),
        estimatedDeliveryAt: _date(json['estimated_delivery_at']),
        deliveredAt: _date(json['delivered_at']),
        cancelledAt: _date(json['cancelled_at']),
        cancellationReason: json['cancellation_reason'] as String?,
      );
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}