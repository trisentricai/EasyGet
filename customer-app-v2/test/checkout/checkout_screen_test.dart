import 'dart:async';

import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/addresses/data/address_repository.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/features/checkout/presentation/checkout_screen.dart';
import 'package:easyget/features/orders/data/orders_repository.dart';
import 'package:easyget/features/payments/data/payment_repository.dart';
import 'package:easyget/models/address_model.dart';
import 'package:easyget/models/cart_models.dart';
import 'package:easyget/models/order_models.dart';
import 'package:easyget/models/payment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _home = Address(
  id: 1,
  label: 'Home',
  line1: '12 MG Road',
  city: 'Bengaluru',
  state: 'KA',
  postalCode: '560001',
  country: 'India',
  phone: '9876543210',
  isDefault: true,
);
const _work = Address(
  id: 2,
  label: 'Work',
  line1: '99 Residency Rd',
  city: 'Bengaluru',
  state: 'KA',
  postalCode: '560025',
  country: 'India',
  phone: '9123456780',
);

class _FakeAddressRepo implements AddressRepository {
  _FakeAddressRepo({this.fail = false});

  bool fail;
  final rows = [_home, _work];
  final List<AddressDraft> created = [];
  final List<int> updated = [];

  @override
  Future<List<Address>> list() async {
    if (fail) throw Exception('boom');
    return List.of(rows);
  }

  @override
  Future<Address> create(AddressDraft draft) async {
    created.add(draft);
    final saved = Address(
      id: 3,
      label: draft.label,
      line1: draft.line1,
      line2: draft.line2 ?? '',
      city: draft.city,
      state: draft.state,
      postalCode: draft.postalCode,
      country: draft.country,
      phone: draft.phone,
    );
    rows.add(saved);
    return saved;
  }

  @override
  Future<Address> update(int id, AddressDraft draft) async {
    updated.add(id);
    return _home;
  }

  @override
  Future<void> delete(int id) async {}
  @override
  Future<Address> setDefault(int id) async => _home;
}

CartItem _line(int id, int variantId, double price, int qty) => CartItem(
      id: id,
      variantId: variantId,
      variantLabel: 'v$variantId',
      variantName: 'Item $variantId',
      price: price,
      quantity: qty,
      lineTotal: price * qty,
    );

class _FakeCartRepo implements CartRepository {
  final lines = [_line(1, 11, 199, 2), _line(2, 12, 100, 1)];
  bool cleared = false;

  @override
  Future<Cart> fetchCart() async => Cart(
        id: 7,
        items: List.of(lines),
        totalItems: lines.fold(0, (a, e) => a + e.quantity),
        subtotal: lines.fold(0.0, (a, e) => a + e.lineTotal),
      );
  @override
  Future<void> addItem({required int variantId, int quantity = 1}) async {}
  @override
  Future<void> updateQty(int itemId, int quantity) async {}
  @override
  Future<void> remove(int itemId) async {}
  @override
  Future<void> clear() async => cleared = true;
}

class _FakeOrdersRepo implements OrdersRepository {
  final List<Map<String, Object?>> creates = [];
  Completer<Order>? gate;

  @override
  Future<Order> create(
      {required int cartId,
      required String deliveryAddress,
      String? instructions}) async {
    creates.add({
      'cartId': cartId,
      'deliveryAddress': deliveryAddress,
      'instructions': instructions,
    });
    if (gate != null) return gate!.future;
    return const Order(
        id: 101,
        orderNumber: 'EG101',
        status: 'PENDING',
        subtotal: 498,
        deliveryFee: 30,
        discount: 0,
        total: 528);
  }

  @override
  Future<List<Order>> list() async => const [];
  @override
  Future<OrderDetail> detail(int id) => throw UnimplementedError();
  @override
  Future<void> cancel(int id, String reason) async {}
  @override
  Future<Map<String, dynamic>> invoice(int id) =>
      throw UnimplementedError();
}

class _FakePaymentRepo implements PaymentRepository {
  final List<Map<String, Object?>> payments = [];

  @override
  Future<List<PaymentMethod>> methods() async => const [
        PaymentMethod(
            id: 5, type: 'UPI', label: 'My UPI', upiId: 'user@upi'),
      ];

  @override
  Future<Payment> createForOrder(
      {required int order,
      required String gateway,
      required num amount,
      int? paymentMethodId}) async {
    payments.add({
      'order': order,
      'gateway': gateway,
      'amount': amount,
      'paymentMethodId': paymentMethodId,
    });
    return Payment(
        id: 9,
        order: order,
        gateway: gateway,
        status: 'PENDING',
        amount: amount.toDouble());
  }
}

Future<void> _pumpCheckout(
  WidgetTester tester, {
  required _FakeAddressRepo addresses,
  required _FakeCartRepo cart,
  required _FakeOrdersRepo orders,
  required _FakePaymentRepo payments,
}) async {
  final router = GoRouter(
    initialLocation: '/checkout',
    routes: [
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: '/browse',
        builder: (_, _) =>
            const Scaffold(key: Key('browse-page'), body: Text('BROWSE')),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, _) =>
            const Scaffold(key: Key('orders-page'), body: Text('ORDERS')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addressRepositoryProvider.overrideWithValue(addresses),
        cartRepositoryProvider.overrideWithValue(cart),
        ordersRepositoryProvider.overrideWithValue(orders),
        paymentRepositoryProvider.overrideWithValue(payments),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders steps, default address, slots, methods and bill',
      (tester) async {
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: _FakeCartRepo(),
      orders: _FakeOrdersRepo(),
      payments: _FakePaymentRepo(),
    );

    expect(find.text('Address'), findsWidgets);
    expect(find.text('Slot'), findsOneWidget);
    expect(find.text('Payment'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('9 AM – 12 PM'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.text('My UPI'), findsOneWidget);
    expect(find.text('Place order · ₹498'), findsOneWidget);
  });

  testWidgets('slot choice lands in delivery_instructions', (tester) async {
    final orders = _FakeOrdersRepo();
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: _FakeCartRepo(),
      orders: orders,
      payments: _FakePaymentRepo(),
    );

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('6 – 9 PM'));
    await tester.tap(find.text('6 – 9 PM'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('checkout-place')));
    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pumpAndSettle();

    expect(orders.creates.single['cartId'], 7);
    expect(orders.creates.single['deliveryAddress'],
        contains('12 MG Road'));
    expect(orders.creates.single['instructions'],
        'Delivery slot: Tomorrow, 6 – 9 PM');
  });

  testWidgets('COD skips the payment call; UPI creates one', (tester) async {
    final orders = _FakeOrdersRepo();
    final payments = _FakePaymentRepo();
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: _FakeCartRepo(),
      orders: orders,
      payments: payments,
    );

    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pumpAndSettle();
    expect(orders.creates, hasLength(1));
    expect(payments.payments, isEmpty);

    // Back to checkout is impossible post-order; re-pump for the UPI path.
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: _FakeCartRepo(),
      orders: orders,
      payments: payments,
    );
    await scrollTo(tester, find.byKey(const Key('pay-upi-5')));
    await tester.tap(find.byKey(const Key('pay-upi-5')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('checkout-place')));
    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pumpAndSettle();

    expect(payments.payments.single['gateway'], 'PHONEPE');
    expect(payments.payments.single['paymentMethodId'], 5);
    expect(payments.payments.single['order'], 101);
  });

  testWidgets('double tap places a single order', (tester) async {
    final orders = _FakeOrdersRepo()..gate = Completer<Order>();
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: _FakeCartRepo(),
      orders: orders,
      payments: _FakePaymentRepo(),
    );

    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pump();
    expect(orders.creates, hasLength(1));

    orders.gate!.complete(const Order(
        id: 101,
        orderNumber: 'EG101',
        status: 'PENDING',
        subtotal: 498,
        deliveryFee: 30,
        discount: 0,
        total: 528));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('orders-page')), findsOneWidget);
  });

  testWidgets('success clears the cart and lands on orders', (tester) async {
    final cart = _FakeCartRepo();
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: cart,
      orders: _FakeOrdersRepo(),
      payments: _FakePaymentRepo(),
    );

    await tester.tap(find.byKey(const Key('checkout-place')));
    await tester.pumpAndSettle();

    expect(cart.cleared, isTrue);
    expect(find.byKey(const Key('orders-page')), findsOneWidget);
  });

  testWidgets('add-address sheet creates and selects', (tester) async {
    final addresses = _FakeAddressRepo();
    await _pumpCheckout(
      tester,
      addresses: addresses,
      cart: _FakeCartRepo(),
      orders: _FakeOrdersRepo(),
      payments: _FakePaymentRepo(),
    );

    await tester.tap(find.text('Add new'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('addr-line1')), '5 Lake View');
    await tester.enterText(find.byKey(const Key('addr-city')), 'Bengaluru');
    await tester.enterText(find.byKey(const Key('addr-state')), 'KA');
    await tester.enterText(find.byKey(const Key('addr-postal')), '560002');
    await tester.enterText(find.byKey(const Key('addr-phone')), '9000000001');
    await tester.tap(find.byKey(const Key('addr-save')));
    await tester.pumpAndSettle();

    expect(addresses.created.single.line1, '5 Lake View');
    expect(find.textContaining('5 Lake View'), findsOneWidget);
  });

  testWidgets('empty cart shows EmptyState', (tester) async {
    final cart = _FakeCartRepo()..lines.clear();
    await _pumpCheckout(
      tester,
      addresses: _FakeAddressRepo(),
      cart: cart,
      orders: _FakeOrdersRepo(),
      payments: _FakePaymentRepo(),
    );

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('addresses failure shows ErrorState with Retry', (tester) async {
    final addresses = _FakeAddressRepo(fail: true);
    await _pumpCheckout(
      tester,
      addresses: addresses,
      cart: _FakeCartRepo(),
      orders: _FakeOrdersRepo(),
      payments: _FakePaymentRepo(),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    addresses.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
  });
}