import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/engagement/data/notifications_repository.dart';
import 'package:easyget/features/engagement/presentation/notifications_screen.dart';
import 'package:easyget/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

AppNotification _notif(int id, {bool read = false, String type = 'ORDER'}) =>
    AppNotification(
      id: id,
      title: 'Order #$id update',
      body: 'Your order is on its way.',
      type: type,
      isRead: read,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

class _FakeNotificationsRepo implements NotificationsRepository {
  _FakeNotificationsRepo({this.fail = false});

  bool fail;
  final rows = [_notif(1), _notif(2, read: true, type: 'OFFER')];
  final List<int> marked = [];
  bool markedAll = false;

  @override
  Future<List<AppNotification>> list() async {
    if (fail) throw Exception('boom');
    return List.of(rows);
  }

  @override
  Future<int> unreadCount() async => 3;

  @override
  Future<void> markRead(int id) async {
    marked.add(id);
    final at = rows.indexWhere((n) => n.id == id);
    rows[at] = _notif(id, read: true);
  }

  @override
  Future<void> markAllRead() async {
    markedAll = true;
    for (var i = 0; i < rows.length; i++) {
      rows[i] = _notif(rows[i].id, read: true);
    }
  }
}

Future<void> _pumpInbox(
  WidgetTester tester, {
  required _FakeNotificationsRepo repo,
}) async {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo)
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

  testWidgets('rows show icon, text, age and unread dots', (tester) async {
    await _pumpInbox(tester, repo: _FakeNotificationsRepo());

    expect(find.byKey(const Key('notif-1')), findsOneWidget);
    expect(find.byKey(const Key('notif-2')), findsOneWidget);
    expect(find.text('Order #1 update'), findsOneWidget);
    expect(find.text('2h ago'), findsWidgets);
    expect(find.byKey(const Key('notif-dot-1')), findsOneWidget);
    expect(find.byKey(const Key('notif-dot-2')), findsNothing);
  });

  testWidgets('tap marks read and clears the dot', (tester) async {
    final repo = _FakeNotificationsRepo();
    await _pumpInbox(tester, repo: repo);

    await tester.tap(find.byKey(const Key('notif-1')));
    await tester.pumpAndSettle();

    expect(repo.marked, [1]);
    expect(find.byKey(const Key('notif-dot-1')), findsNothing);
  });

  testWidgets('mark-all-read clears every dot', (tester) async {
    final repo = _FakeNotificationsRepo();
    await _pumpInbox(tester, repo: repo);

    await tester.tap(find.byKey(const Key('notif-mark-all')));
    await tester.pumpAndSettle();

    expect(repo.markedAll, isTrue);
    expect(find.byKey(const Key('notif-dot-1')), findsNothing);
  });

  testWidgets('empty shows the caught-up state', (tester) async {
    final repo = _FakeNotificationsRepo()..rows.clear();
    await _pumpInbox(tester, repo: repo);

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeNotificationsRepo(fail: true);
    await _pumpInbox(tester, repo: repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notif-1')), findsOneWidget);
  });
}