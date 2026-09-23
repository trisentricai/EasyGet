import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../catalog/data/catalog_repository.dart';

class CartVariant {
  CartVariant({required this.id, required this.name, required this.sku, required this.price});

  final int id;
  final String name;
  final String sku;
  final String price;

  factory CartVariant.fromJson(Map<String, dynamic> json) => CartVariant(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        sku: (json['sku'] ?? '') as String,
        price: (json['price'] ?? '0') as String,
      );
}

class CartItem {
  CartItem({
    required this.id,
    required this.variant,
    required this.quantity,
    required this.lineTotal,
    this.product,
  });

  final int id;
  final CartVariant variant;
  final int quantity;
  final String lineTotal;
  final Product? product;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: (json['id'] as num).toInt(),
        variant: CartVariant.fromJson(json['variant'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num).toInt(),
        lineTotal: (json['line_total'] ?? '0').toString(),
        product: json['product'] is Map<String, dynamic>
            ? Product.fromJson(json['product'] as Map<String, dynamic>)
            : null,
      );
}

class Cart {
  Cart({
    required this.id,
    required this.items,
    required this.totalItems,
    required this.subtotal,
    this.store,
  });

  final String id;
  final List<CartItem> items;
  final int totalItems;
  final String subtotal;
  final int? store;

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: (json['id'] ?? '').toString(),
        items: ((json['items'] as List?) ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
        subtotal: (json['subtotal'] ?? '0').toString(),
        store: (json['store'] as num?)?.toInt(),
      );
}

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<Cart> current() => _api.get<Cart>(
        '/cart/',
        decode: (j) => Cart.fromJson(j as Map<String, dynamic>),
      );

  Future<void> add({required int variantId, int quantity = 1}) async {
    await _api.post<dynamic>('/cart/items/',
        body: {'variant_id': variantId, 'quantity': quantity});
  }

  Future<void> setQuantity({required int itemId, required int quantity}) async {
    await _api.patch<dynamic>('/cart/items/$itemId/', body: {'quantity': quantity});
  }

  Future<void> remove({required int itemId}) async {
    await _api.delete('/cart/items/$itemId/');
  }

  Future<void> clear() => _api.delete('/cart/clear/');
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});
