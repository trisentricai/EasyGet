import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/orders/data/orders_repository.dart';
import 'package:easyget/features/orders/presentation/order_detail_screen.dart';
import 'package:easyget/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

OrderDetail _detail(String status) => OrderDetail(
      id: 42,
      orderNumber: 'EG1042',
      status: status,
      subtotal: 400,
      deliveryFee: 30,
      discount: 20,
      total: 410,
      itemCount: 3,
      items: const [
        OrderItem(
            id: 1,
            variantName: 'Amul Butter 200 g',
            variantLabel: 'Amul Butter 200 g',
            quantity: 2,
            unitPrice: 199,
            lineTotal: 398),
        OrderItem(
            id: 2,
            variantName: 'Whole Wheat Atta 5 kg',
            variantLabel: 'Whole Wheat Atta 5 kg',
            quantity: 1,
            unitPrice: 100,
            lineTotal: 100),
      ],
      statusHistory: const [
        OrderStatusEvent(from: '', to: 'PENDING'),
        OrderStatusEvent(from: 'PENDING', to: 'CONFIRMED'),
        OrderStatusEvent(
            from: 'CONFIRMED', to: 'OUT_FOR_DELIVERY', note: 'Left the store'),
      ],
    );

class _FakeOrdersRepo implements OrdersRepository {
  _FakeOrdersRepo({this.fail = false});

  bool fail;
  String status = 'OUT_FOR_DELIVERY';
  int detailCalls = 0;
  final List<Map<String, Object?>> cancels = [];

  @override
  Future<OrderDetail> detail(int id) async {
    detailCalls++;
    if (fail) throw Exception('boom');
    return _detail(status);
  }

  @override
  Future<void> cancel(int id, String reason) async {
    cancels.add({'id': id, 'reason': reason});
    status = 'CANCELLED';
  }

  @override
  Future<List<Order>> list() async => const [];
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

Future<void> _pumpDetail(
  WidgetTester tester, {
  required _FakeOrdersRepo repo,
}) async {
  final router = GoRouter(
    initialLocation: '/order/42',
    routes: [
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrderDetailScreen(key: ValueKey(id), orderId: id);
        },
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

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders hero, timeline, items and bill', (tester) async {
    await _pumpDetail(tester, repo: _FakeOrdersRepo());

    expect(find.text('EG1042'), findsOneWidget);
    expect(find.text('Out for delivery'), findsWidgets);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Left the store'), findsOneWidget);
    expect(find.text('Amul Butter 200 g × 2'), findsOneWidget);
    expect(find.text('₹398'), findsOneWidget);
    expect(find.text('₹410'), findsWidgets);
  });

  testWidgets('active orders re-poll every 30s', (tester) async {
    final repo = _FakeOrdersRepo();
    await _pumpDetail(tester, repo: repo);
    expect(repo.detailCalls, 1);

    await tester.pump(const Duration(seconds: 31));
    expect(repo.detailCalls, 2);
  });

  testWidgets('polling stops on terminal statuses', (tester) async {
    final repo = _FakeOrdersRepo()..status = 'DELIVERED';
    await _pumpDetail(tester, repo: repo);
    expect(repo.detailCalls, 1);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 31));
    expect(repo.detailCalls, 1);
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('cancel from detail refreshes to cancelled', (tester) async {
    final repo = _FakeOrdersRepo()..status = 'PENDING';
    await _pumpDetail(tester, repo: repo);

    await _scrollTo(tester, find.byKey(const Key('order-detail-cancel')));
    await tester.tap(find.byKey(const Key('order-detail-cancel')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('cancel-reason')), 'Ordered twice');
    await tester.tap(find.byKey(const Key('cancel-confirm')));
    await tester.pumpAndSettle();

    expect(repo.cancels.single, {'id': 42, 'reason': 'Ordered twice'});
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('delivered orders offer no cancel', (tester) async {
    final repo = _FakeOrdersRepo()..status = 'DELIVERED';
    await _pumpDetail(tester, repo: repo);

    expect(find.byKey(const Key('order-detail-cancel')), findsNothing);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeOrdersRepo(fail: true);
    await _pumpDetail(tester, repo: repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('EG1042'), findsOneWidget);
  });
}