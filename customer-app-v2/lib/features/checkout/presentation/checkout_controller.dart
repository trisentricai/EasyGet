import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/address_model.dart';
import '../../../models/cart_models.dart';
import '../../../models/order_models.dart';
import '../../../models/payment_model.dart';
import '../../addresses/data/address_repository.dart';
import '../../cart/data/cart_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../payments/data/payment_repository.dart';

/// S9 · Checkout state. Slot choice is local (no slot endpoint exists) and
/// travels in `delivery_instructions`. Payments are COD + UPI-on-delivery
/// only, created AFTER the order (COD skips the payment call entirely).
class CheckoutState {
  const CheckoutState({
    this.addresses = const [],
    this.addressesLoading = true,
    this.addressesError,
    this.selectedAddressId,
    this.day = 'Today',
    this.window = '9 AM – 12 PM',
    this.method = 'cod',
    this.savedMethodId,
    this.methods = const [],
    this.cart,
    this.cartLoading = true,
    this.cartError,
    this.placing = false,
    this.placeError,
  });

  final List<Address> addresses;
  final bool addressesLoading;
  final Object? addressesError;
  final int? selectedAddressId;
  final String day;
  final String window;
  final String method;
  final int? savedMethodId;
  final List<PaymentMethod> methods;
  final Cart? cart;
  final bool cartLoading;
  final Object? cartError;
  final bool placing;
  final Object? placeError;

  Address? get selectedAddress {
    for (final address in addresses) {
      if (address.id == selectedAddressId) return address;
    }
    return null;
  }

  List<PaymentMethod> get upiMethods =>
      methods.where((m) => m.type == 'UPI').toList();

  String get slotText => 'Delivery slot: $day, $window';

  CheckoutState copyWith({
    List<Address>? addresses,
    bool? addressesLoading,
    Object? Function()? addressesError,
    int? Function()? selectedAddressId,
    String? day,
    String? window,
    String? method,
    int? Function()? savedMethodId,
    List<PaymentMethod>? methods,
    Cart? Function()? cart,
    bool? cartLoading,
    Object? Function()? cartError,
    bool? placing,
    Object? Function()? placeError,
  }) =>
      CheckoutState(
        addresses: addresses ?? this.addresses,
        addressesLoading: addressesLoading ?? this.addressesLoading,
        addressesError:
            addressesError == null ? this.addressesError : addressesError(),
        selectedAddressId: selectedAddressId == null
            ? this.selectedAddressId
            : selectedAddressId(),
        day: day ?? this.day,
        window: window ?? this.window,
        method: method ?? this.method,
        savedMethodId: savedMethodId == null
            ? this.savedMethodId
            : savedMethodId(),
        methods: methods ?? this.methods,
        cart: cart == null ? this.cart : cart(),
        cartLoading: cartLoading ?? this.cartLoading,
        cartError: cartError == null ? this.cartError : cartError(),
        placing: placing ?? this.placing,
        placeError:
            placeError == null ? this.placeError : placeError(),
      );
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    _load();
    return const CheckoutState();
  }

  Future<void> _load() async {
    final addressesFuture =
        ref.read(addressRepositoryProvider).list().then(
              (rows) => _AddressResult(rows, null),
              onError: (Object e) => _AddressResult(const [], e),
            );
    final cartFuture = ref.read(cartRepositoryProvider).fetchCart().then(
          (cart) => _CartResult(cart, null),
          onError: (Object e) => _CartResult(null, e),
        );
    // Saved methods are a nicety — COD is always offered even if this fails.
    List<PaymentMethod> methods = const [];
    try {
      methods = await ref.read(paymentRepositoryProvider).methods();
    } catch (_) {
      methods = const [];
    }
    final addresses = await addressesFuture;
    final cart = await cartFuture;

    int? selected;
    for (final address in addresses.rows) {
      if (address.isDefault) selected = address.id;
    }
    selected ??=
        addresses.rows.isEmpty ? null : addresses.rows.first.id;

    state = CheckoutState(
      addresses: addresses.rows,
      addressesLoading: false,
      addressesError: addresses.error,
      selectedAddressId: selected,
      methods: methods,
      cart: cart.value,
      cartLoading: false,
      cartError: cart.error,
    );
  }

  Future<void> refresh() => _load();

  void selectAddress(int id) {
    state = state.copyWith(selectedAddressId: () => id);
  }

  void setDay(String day) {
    state = state.copyWith(day: day);
  }

  void setWindow(String window) {
    state = state.copyWith(window: window);
  }

  void setMethod(String method, [int? savedMethodId]) {
    state = state.copyWith(
        method: method, savedMethodId: () => savedMethodId);
  }

  /// Places the order, then the UPI payment (COD skips it), then clears the
  /// cart. Returns the created order. Double-tap safe via [placing].
  Future<Order?> placeOrder() async {
    if (state.placing) return null;
    final cart = state.cart;
    final address = state.selectedAddress;
    if (cart == null || cart.items.isEmpty || address == null) {
      state = state.copyWith(placeError: () => 'Your cart is empty.');
      return null;
    }
    state = state.copyWith(placing: true, placeError: () => null);
    try {
      final order = await ref.read(ordersRepositoryProvider).create(
            cartId: cart.id,
            deliveryAddress: address.singleLine,
            instructions: state.slotText,
          );
      if (state.method != 'cod') {
        await ref.read(paymentRepositoryProvider).createForOrder(
              order: order.id,
              gateway: 'PHONEPE',
              amount: order.total,
              paymentMethodId: state.savedMethodId,
            );
      }
      await ref.read(cartRepositoryProvider).clear();
      state = state.copyWith(placing: false);
      return order;
    } catch (e) {
      state = state.copyWith(placing: false, placeError: () => e);
      return null;
    }
  }
}

class _AddressResult {
  _AddressResult(this.rows, this.error);
  final List<Address> rows;
  final Object? error;
}

class _CartResult {
  _CartResult(this.value, this.error);
  final Cart? value;
  final Object? error;
}

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(
  CheckoutController.new,
);