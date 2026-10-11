import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/features/engagement/data/analytics_repository.dart';
import 'package:easyget/main.dart';
import 'package:easyget/models/cart_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

final _user = AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER');

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.store);
  final TokenStore store;

  @override
  Future<AppUser> me() async => _user;
  @override
  Future<AppUser> login({required String email, required String password}) async => _user;
  @override
  Future<AppUser> loginWithGoogle(String idToken) async => _user;
  @override
  Future<void> register({
    required String email, required String password, required String name,
    String phone = '', String role = 'CUSTOMER',
  }) async {}
  @override
  Future<void> logout() async => store.clear();
  @override
  Future<void> mergeGuestCart() async {}
}

class _FakeCartRepo implements CartRepository {
  _FakeCartRepo(this.totalItems);
  final int totalItems;

  @override
  Future<Cart> fetchCart() async =>
      Cart(id: 1, items: const [], totalItems: totalItems, subtotal: 0);
  @override
  Future<void> addItem({required int variantId, int quantity = 1}) async {}
  @override
  Future<void> updateQty(int itemId, int quantity) async {}
  @override
  Future<void> remove(int itemId) async {}
  @override
  Future<void> clear() async {}
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient() : super(Dio());
  @override
  Future<void> warmUp() async {}
}

class _NoopAnalytics implements AnalyticsRepository {
  @override
  Future<void> track({
    required String eventType,
    Map<String, dynamic> properties = const {},
  }) async {}
  @override
  Future<void> trackBatch(List<AnalyticsEvent> events) async {}
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required bool signedIn,
  int cartItems = 0,
}) async {
  final store = InMemoryTokenStore();
  if (signedIn) await store.save(access: 'A', refresh: 'R');

  final container = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(_FakeAuthRepo(store)),
    apiClientProvider.overrideWithValue(_NoopApiClient()),
    analyticsRepositoryProvider.overrideWithValue(_NoopAnalytics()),
    cartRepositoryProvider.overrideWithValue(_FakeCartRepo(cartItems)),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EasyGetApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('guest (no session) is bounced to /login', (tester) async {
    await _pumpApp(tester, signedIn: false);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byKey(const Key('placeholder-home')), findsNothing);
  });

  testWidgets('signed-in lands on /home with the 5-tab BottomNav',
      (tester) async {
    await _pumpApp(tester, signedIn: true);

    expect(find.byKey(const Key('placeholder-home')), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('home AppBar shows the address row + ETA pill slots',
      (tester) async {
    await _pumpApp(tester, signedIn: true);

    expect(find.byKey(const Key('home-address-row')), findsOneWidget);
    expect(find.byKey(const Key('home-eta-pill')), findsOneWidget);
    expect(find.byKey(const Key('app-search-bar')), findsOneWidget);
  });

  testWidgets('cart badge is hidden at 0 and shown when items exist',
      (tester) async {
    await _pumpApp(tester, signedIn: true, cartItems: 0);
    expect(find.byKey(const Key('cart-badge')), findsNothing);

    await _pumpApp(tester, signedIn: true, cartItems: 3);
    expect(find.byKey(const Key('cart-badge')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping Browse switches branch and shows its placeholder',
      (tester) async {
    await _pumpApp(tester, signedIn: true);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder-browse')), findsOneWidget);
    expect(find.byKey(const Key('placeholder-home')), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placeholder-home')), findsOneWidget);
  });

  testWidgets('tapping the SearchBar opens the /search tab', (tester) async {
    await _pumpApp(tester, signedIn: true);

    await tester.tap(find.byKey(const Key('app-search-bar')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder-search')), findsOneWidget);
  });
}