import 'package:easyget/features/engagement/data/order_watcher.dart';
import 'package:easyget/features/orders/data/orders_repository.dart';
import 'package:easyget/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order(int id, String status) => Order(
      id: id,
      orderNumber: 'EG10$id',
      status: status,
      subtotal: 400,
      deliveryFee: 30,
      discount: 0,
      total: 430,
      itemCount: 2,
    );

class _FakeOrdersRepo implements OrdersRepository {
  List<Order> rows = [_order(1, 'PENDING')];

  @override
  Future<List<Order>> list() async => List.of(rows);
  @override
  Future<OrderDetail> detail(int id) => throw UnimplementedError();
  @override
  Future<Order> create(
          {required int cartId,
          required String deliveryAddress,
          String? instructions}) =>
      throw UnimplementedError();
  @override
  Future<void> cancel(int id, String reason) async {}
  @override
  Future<Map<String, dynamic>> invoice(int id) =>
      throw UnimplementedError();
}

class _FakeNotifier implements LocalNotifier {
  bool permission = true;
  final List<Map<String, Object?>> shown = [];

  @override
  Future<bool> ensurePermission() async => permission;

  @override
  Future<void> orderUpdate(
      {required int orderId,
      required String orderNumber,
      required String status}) async {
    shown.add(
        {'orderId': orderId, 'orderNumber': orderNumber, 'status': status});
  }

  @override
  Future<void> showAlert(
      {required String title,
      required String body,
      String? payload}) async {
    shown.add({'title': title, 'body': body});
  }
}

Future<ProviderContainer> _pumpWatcher(
  WidgetTester tester, {
  required _FakeOrdersRepo orders,
  required _FakeNotifier notifier,
}) async {
  final container = ProviderContainer(overrides: [
    ordersRepositoryProvider.overrideWithValue(orders),
    localNotifierProvider.overrideWithValue(notifier),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SizedBox(),
    ),
  );
  container.read(orderWatcherProvider.notifier).start();
  await tester.pumpAndSettle();
  return container;
}

void _stop(ProviderContainer container) =>
    container.read(orderWatcherProvider.notifier).stop();

void main() {
  testWidgets('first poll baselines silently', (tester) async {
    final notifier = _FakeNotifier();
    final container = await _pumpWatcher(
      tester,
      orders: _FakeOrdersRepo(),
      notifier: notifier,
    );

    expect(notifier.shown, isEmpty);
    _stop(container);
  });

  testWidgets('new active order notifies once', (tester) async {
    final orders = _FakeOrdersRepo();
    final notifier = _FakeNotifier();
    final container = await _pumpWatcher(
        tester, orders: orders, notifier: notifier);

    orders.rows = [_order(1, 'PENDING'), _order(2, 'CONFIRMED')];
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single['orderId'], 2);
    _stop(container);
  });

  testWidgets('status change notifies with the new status', (tester) async {
    final orders = _FakeOrdersRepo();
    final notifier = _FakeNotifier();
    final container = await _pumpWatcher(
        tester, orders: orders, notifier: notifier);

    orders.rows = [_order(1, 'OUT_FOR_DELIVERY')];
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(notifier.shown.single['status'], 'OUT_FOR_DELIVERY');
    _stop(container);
  });

  testWidgets('unchanged snapshot stays silent', (tester) async {
    final orders = _FakeOrdersRepo();
    final notifier = _FakeNotifier();
    final container = await _pumpWatcher(
        tester, orders: orders, notifier: notifier);

    await tester.pump(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(notifier.shown, isEmpty);
    _stop(container);
  });

  testWidgets('permission denied stays silent without crashing',
      (tester) async {
    final orders = _FakeOrdersRepo();
    final notifier = _FakeNotifier()..permission = false;
    final container = await _pumpWatcher(
        tester, orders: orders, notifier: notifier);

    orders.rows = [_order(1, 'CONFIRMED')];
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(notifier.shown, isEmpty);
    _stop(container);
  });
}