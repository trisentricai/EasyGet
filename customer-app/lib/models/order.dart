import 'cart_item.dart';
import 'address.dart';

/// Order model matching backend serializer.
class Order {
  Order({
    required this.id,
    required this.date,
    required this.status,
    this.etaMinutes,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    this.riderTip = 0,
    this.deliveryInstructions = const [],
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.events,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverRating,
    this.productReview,
  });

  final String id;
  final String date;
  final String status; // 'In Transit' | 'Delivered' | 'Cancelled'
  final int? etaMinutes;
  final List<CartItem> items;
  final int subtotal;
  final int discount;
  final int deliveryFee;
  final int riderTip;
  final List<String> deliveryInstructions;
  final int total;
  final Address address;
  final String paymentMethod;
  final List<OrderEvent> events;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final int? driverRating;
  final ProductReview? productReview;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
        items: (json['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toInt() ?? 0,
        deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
        riderTip: (json['rider_tip'] as num?)?.toInt() ?? 0,
        deliveryInstructions:
            (json['delivery_instructions'] as List? ?? []).map((e) => e.toString()).toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        address: Address.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
        paymentMethod: json['payment_method']?.toString() ?? '',
        events: (json['events'] as List? ?? [])
            .map((e) => OrderEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        driverName: json['driver_name']?.toString(),
        driverPhone: json['driver_phone']?.toString(),
        driverVehicle: json['driver_vehicle']?.toString(),
        driverRating: (json['driver_rating'] as num?)?.toInt(),
        productReview: json['product_review'] != null
            ? ProductReview.fromJson(json['product_review'] as Map<String, dynamic>)
            : null,
      );
}

class OrderEvent {
  OrderEvent({
    required this.status,
    required this.time,
    required this.description,
    required this.completed,
    required this.current,
  });

  final String status;
  final String time;
  final String description;
  final bool completed;
  final bool current;

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
        status: json['status']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        completed: json['completed'] ?? false,
        current: json['current'] ?? false,
      );
}

class ProductReview {
  ProductReview({
    required this.rating,
    required this.tags,
    required this.text,
  });

  final int rating;
  final List<String> tags;
  final String text;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
        text: json['text']?.toString() ?? '',
      );
}

class OrderTracking {
  OrderTracking({
    required this.events,
    this.driverName,
    this.driverPhone,
    this.driverVehicle,
    this.driverRating,
  });

  final List<OrderEvent> events;
  final String? driverName;
  final String? driverPhone;
  final String? driverVehicle;
  final int? driverRating;

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
        events: (json['events'] as List? ?? [])
            .map((e) => OrderEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        driverName: json['driver_name']?.toString(),
        driverPhone: json['driver_phone']?.toString(),
        driverVehicle: json['driver_vehicle']?.toString(),
        driverRating: (json['driver_rating'] as num?)?.toInt(),
      );
}