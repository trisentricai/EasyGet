import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/orders/data/orders_repository.dart';
import 'package:easyget/features/orders/presentation/orders_screen.dart';
import 'package:easyget/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  _FakeOrdersRepo({this.fail = false});

  bool fail;
  final rows = [
    _order(1, 'PENDING'),
    _order(2, 'OUT_FOR_DELIVERY'),
    _order(3, 'DELIVERED'),
  ];
  final List<Map<String, Object?>> cancels = [];

  @override
  Future<List<Order>> list() async {
    if (fail) throw Exception('boom');
    return List.of(rows);
  }

  @override
  Future<void> cancel(int id, String reason) async {
    cancels.add({'id': id, 'reason': reason});
    final at = rows.indexWhere((o) => o.id == id);
    rows[at] = _order(id, 'CANCELLED');
  }

  @override
  Future<OrderDetail> detail(int id) => throw UnimplementedError();
  @override
  Future<Order> create(
          {required int cartId,
          required String deliveryAddress,
          String? instructions}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> invoice(int id) =>
      throw UnimplementedError();
}

Future<void> _pumpOrders(
  WidgetTester tester, {
  required _FakeOrdersRepo repo,
}) async {
  final router = GoRouter(
    initialLocation: '/orders',
    routes: [
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: '/order/:id',
        builder: (_, _) => const Scaffold(
            key: Key('order-detail-page'), body: Text('DETAIL')),
      ),
      GoRoute(
        path: '/browse',
        builder: (_, _) =>
            const Scaffold(key: Key('browse-page'), body: Text('BROWSE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ordersRepositoryProvider.overrideWithValue(repo)],
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

  testWidgets('Active shows ongoing orders with pills and totals',
      (tester) async {
    await _pumpOrders(tester, repo: _FakeOrdersRepo());

    expect(find.byKey(const Key('order-card-1')), findsOneWidget);
    expect(find.byKey(const Key('order-card-2')), findsOneWidget);
    expect(find.byKey(const Key('order-card-3')), findsNothing);
    expect(find.text('EG101'), findsOneWidget);
    expect(find.text('2 items · ₹430'), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
  });

  testWidgets('Past tab shows delivered orders', (tester) async {
    await _pumpOrders(tester, repo: _FakeOrdersRepo());

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-card-3')), findsOneWidget);
    expect(find.byKey(const Key('order-card-1')), findsNothing);
  });

  testWidgets('card tap opens the detail', (tester) async {
    await _pumpOrders(tester, repo: _FakeOrdersRepo());

    await tester.tap(find.byKey(const Key('order-card-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-detail-page')), findsOneWidget);
  });

  testWidgets('cancel asks for a reason, cancels and refreshes', (tester) async {
    final repo = _FakeOrdersRepo();
    await _pumpOrders(tester, repo: repo);

    expect(find.byKey(const Key('order-cancel-1')), findsOneWidget);
    expect(find.byKey(const Key('order-cancel-3')), findsNothing);

    await tester.tap(find.byKey(const Key('order-cancel-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel-reason')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('cancel-reason')), 'Ordered twice');
    await tester.tap(find.byKey(const Key('cancel-confirm')));
    await tester.pumpAndSettle();

    expect(repo.cancels.single, {'id': 1, 'reason': 'Ordered twice'});
    expect(find.byKey(const Key('order-card-1')), findsNothing);
    expect(find.text('Order cancelled.'), findsOneWidget);
  });

  testWidgets('empty shows EmptyState', (tester) async {
    final repo = _FakeOrdersRepo()..rows.clear();
    await _pumpOrders(tester, repo: repo);

    expect(find.text('No active orders'), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeOrdersRepo(fail: true);
    await _pumpOrders(tester, repo: repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-card-1')), findsOneWidget);
  });
}