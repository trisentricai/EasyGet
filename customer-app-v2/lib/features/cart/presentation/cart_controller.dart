import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/cart_models.dart';
import '../data/cart_repository.dart';
import '../data/coupon_repository.dart';

/// S8 · Cart screen state. Totals are server truth (`GET /cart/`); the only
/// client-side derivation is `payable = subtotal − coupon discount` (the
/// discount itself is server-validated; delivery resolves at checkout).
class CartViewState {
  const CartViewState({
    this.items = const [],
    this.subtotal = 0,
    this.totalItems = 0,
    this.loading = true,
    this.error,
    this.coupon,
    this.applyingCoupon = false,
    this.couponError,
    this.mutationError,
  });

  final List<CartItem> items;
  final double subtotal;
  final int totalItems;
  final bool loading;
  final Object? error;
  final CouponDiscount? coupon;
  final bool applyingCoupon;
  final String? couponError;
  final String? mutationError;

  double get discount => coupon?.discount ?? 0;
  double get payable => (subtotal - discount).clamp(0, double.infinity);

  CartViewState copyWith({
    List<CartItem>? items,
    double? subtotal,
    int? totalItems,
    bool? loading,
    Object? Function()? error,
    CouponDiscount? Function()? coupon,
    bool? applyingCoupon,
    String? Function()? couponError,
    String? Function()? mutationError,
  }) =>
      CartViewState(
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        totalItems: totalItems ?? this.totalItems,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        coupon: coupon == null ? this.coupon : coupon(),
        applyingCoupon: applyingCoupon ?? this.applyingCoupon,
        couponError: couponError == null ? this.couponError : couponError(),
        mutationError:
            mutationError == null ? this.mutationError : mutationError(),
      );
}

class CartController extends Notifier<CartViewState> {
  @override
  CartViewState build() {
    _load();
    return const CartViewState();
  }

  Future<void> _load() async {
    try {
      final cart = await ref.read(cartRepositoryProvider).fetchCart();
      state = CartViewState(
        items: cart.items,
        subtotal: cart.subtotal,
        totalItems: cart.totalItems,
        loading: false,
        coupon: state.coupon,
      );
    } catch (e) {
      state = CartViewState(error: e, loading: false, coupon: state.coupon);
    }
  }

  Future<void> refresh() => _load();

  void _fail(Object e) {
    state = state.copyWith(
        mutationError: () => e is ApiException ? e.message : '$e');
  }

  void clearNotice() {
    state = state.copyWith(mutationError: () => null);
  }

  Future<void> setQty(int itemId, int quantity) async {
    try {
      await ref.read(cartRepositoryProvider).updateQty(itemId, quantity);
      await _load();
    } catch (e) {
      _fail(e);
      await _load();
    }
  }

  /// Removes the line optimistically and returns it for the Undo snackbar.
  Future<CartItem?> removeLine(CartItem item) async {
    final previous = state.items;
    state = state.copyWith(
      items: previous.where((e) => e.id != item.id).toList(),
      subtotal: state.subtotal - item.lineTotal,
      totalItems: state.totalItems - item.quantity,
    );
    try {
      await ref.read(cartRepositoryProvider).remove(item.id);
      return item;
    } catch (e) {
      _fail(e);
      await _load();
      return null;
    }
  }

  Future<void> undoRemove(CartItem item) async {
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(variantId: item.variantId, quantity: item.quantity);
      await _load();
    } catch (e) {
      _fail(e);
      await _load();
    }
  }

  Future<void> applyCoupon(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return;
    state = state.copyWith(
        applyingCoupon: true, couponError: () => null);
    try {
      final discount = await ref.read(couponRepositoryProvider).validate(
            code: code,
            orderValue: state.subtotal,
          );
      state = state.copyWith(
          applyingCoupon: false, coupon: () => discount);
    } catch (e) {
      state = state.copyWith(
        applyingCoupon: false,
        couponError: () => e is ApiException ? e.message : '$e',
      );
    }
  }

  void removeCoupon() {
    state = state.copyWith(coupon: () => null, couponError: () => null);
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, CartViewState>(
  CartController.new,
);