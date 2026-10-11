import 'catalog_models.dart';

/// One line in the server cart (`items[]` of `GET /cart/`).
class CartItem {
  const CartItem({
    required this.id,
    required this.variantId,
    required this.variantLabel,
    required this.variantName,
    required this.price,
    required this.quantity,
    required this.lineTotal,
    this.tenantId,
    this.sellerName,
  });

  final int id;
  final int variantId;
  final String variantLabel;
  final String variantName;
  final double price;
  final int quantity;
  final double lineTotal;
  final int? tenantId;
  final String? sellerName;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final variant = (json['variant'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final name = (variant['name'] ?? '') as String;
    return CartItem(
      id: numToInt(json['id']),
      variantId: numToInt(variant['id']),
      variantLabel: (variant['label'] ?? name) as String,
      variantName: name,
      price: numToDouble(variant['price']),
      quantity: numToInt(json['quantity']),
      lineTotal: numToDouble(json['line_total']),
      tenantId: numToIntOrNull(json['tenant_id']),
      sellerName: json['seller_name'] as String?,
    );
  }
}

/// `GET /cart/` payload. Server is the source of truth for pricing (DESIGN §14).
class Cart {
  const Cart({
    required this.id,
    this.storeSlug,
    this.items = const [],
    this.totalItems = 0,
    this.subtotal = 0,
  });

  final int id;
  final String? storeSlug;
  final List<CartItem> items;
  final int totalItems;
  final double subtotal;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final store = (json['store'] as Map?)?.cast<String, dynamic>();
    return Cart(
      id: numToInt(json['id']),
      storeSlug: store?['slug'] as String?,
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList(),
      totalItems: numToInt(json['total_items']),
      subtotal: numToDouble(json['subtotal']),
    );
  }
}