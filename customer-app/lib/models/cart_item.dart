import 'product.dart';

/// Cart item with product reference and quantity.
class CartItem {
  CartItem({required this.product, required this.quantity});

  final Product product;
  int quantity;

  int get lineTotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>? ?? {}),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}