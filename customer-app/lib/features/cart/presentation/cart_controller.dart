import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../models/cart_item.dart';
import '../../../models/product.dart';

import '../data/cart_repository.dart';

/// Cart state managed by Riverpod.
class CartState {
  CartState({
    this.items = const [],
    this.riderTip = 20,
    this.deliveryInstructions = const ['leave_door'],
    this.substitutionPreference = 'call',
    this.appliedCoupon,
    this.isLoading = false,
  });

  final List<CartItem> items;
  final int riderTip;
  final List<String> deliveryInstructions;
  final String substitutionPreference;
  final CouponValidation? appliedCoupon;
  final bool isLoading;

  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  int get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  int get discount => appliedCoupon?.discount ?? 0;
  int get deliveryFee => (subtotal >= 300 || subtotal == 0) ? 0 : 25;
  int get total => (subtotal - discount + deliveryFee + riderTip).clamp(0, 999999);

  CartState copyWith({
    List<CartItem>? items,
    int? riderTip,
    List<String>? deliveryInstructions,
    String? substitutionPreference,
    CouponValidation? appliedCoupon,
    bool? isLoading,
  }) => CartState(
        items: items ?? this.items,
        riderTip: riderTip ?? this.riderTip,
        deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
        substitutionPreference: substitutionPreference ?? this.substitutionPreference,
        appliedCoupon: appliedCoupon ?? this.appliedCoupon,
        isLoading: isLoading ?? this.isLoading,
      );
}

class _CartNotifier extends ChangeNotifier {
  _CartNotifier(this._repo) : _state = CartState() {
    loadCart();
  }

  final CartRepository _repo;
  CartState _state = CartState();

  CartState get state => _state;

  void _update(CartState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadCart() async {
    _update(_state.copyWith(isLoading: true));
    try {
      final response = await _repo.getCart();
      _update(_state.copyWith(
        items: response.items,
        appliedCoupon: response.coupon != null
            ? CouponValidation(discount: response.discount, applied: true)
            : null,
        isLoading: false,
      ));
    } catch (_) {
      _update(_state.copyWith(isLoading: false));
    }
  }

  Future<void> addToCart(Product product, [int delta = 1]) async {
    final index = _state.items.indexWhere((i) => i.product.id == product.id);
    if (index > -1) {
      final newQty = _state.items[index].quantity + delta;
      if (newQty <= 0) {
        _update(_state.copyWith(
          items: _state.items.where((i) => i.product.id != product.id).toList(),
        ));
      } else {
        final updated = [..._state.items];
        updated[index] = CartItem(
          product: product,
          quantity: newQty.clamp(1, product.stockQty),
        );
        _update(_state.copyWith(items: updated));
      }
    } else if (delta > 0) {
      _update(_state.copyWith(
        items: [..._state.items, CartItem(product: product, quantity: delta)],
      ));
    }
    // Optimistic update - sync with server
    _syncWithServer(product.id, _state.items.firstWhere((i) => i.product.id == product.id).quantity);
  }

  Future<void> _syncWithServer(String productId, int qty) async {
    try {
      await _repo.addItem(productId: productId, qty: qty);
    } catch (_) {
      // Revert on failure - reload from server
      loadCart();
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _state.items.indexWhere((i) => i.product.id == productId);
    if (index == -1) return;

    if (quantity <= 0) {
      _update(_state.copyWith(
        items: _state.items.where((i) => i.product.id != productId).toList(),
      ));
    } else {
      final updated = [..._state.items];
      updated[index] = CartItem(
        product: updated[index].product,
        quantity: quantity.clamp(1, updated[index].product.stockQty),
      );
      _update(_state.copyWith(items: updated));
    }
    _syncWithServer(productId, quantity);
  }

  Future<void> removeItem(String productId) async {
    _update(_state.copyWith(
      items: _state.items.where((i) => i.product.id != productId).toList(),
    ));
    // Note: need cart item ID for server delete - simplified for now
    loadCart();
  }

  void setRiderTip(int tip) => _update(_state.copyWith(riderTip: tip));

  void toggleInstruction(String instruction) {
    final list = [..._state.deliveryInstructions];
    if (list.contains(instruction)) {
      list.remove(instruction);
    } else {
      list.add(instruction);
    }
    _update(_state.copyWith(deliveryInstructions: list));
  }

  void setSubstitution(String pref) => _update(_state.copyWith(substitutionPreference: pref));

  Future<CouponValidation> applyCoupon(String code, int subtotal) async {
    try {
      final validation = await _repo.validateCoupon(code, subtotal);
      if (validation.applied) {
        _update(_state.copyWith(
          appliedCoupon: CouponValidation(
            discount: validation.discount,
            applied: true,
            message: validation.message,
          ),
        ));
      }
      return validation;
    } catch (_) {
      return CouponValidation(discount: 0, applied: false);
    }
  }

  void removeCoupon() => _update(_state.copyWith(appliedCoupon: null));

  void clearCart() => _update(_state.copyWith(items: []));
}

/// Cart provider using ChangeNotifier.
final cartProvider = ChangeNotifierProvider<_CartNotifier>((ref) {
  return _CartNotifier(ref.watch(cartRepositoryProvider));
});

/// Cart count for bottom nav badge.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).state.count;
});