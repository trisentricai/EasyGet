import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/account/data/profile_repository.dart';
import 'package:easyget/features/account/presentation/account_providers.dart';
import 'package:easyget/features/account/presentation/account_screen.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/auth/presentation/auth_state.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/wishlist/data/wishlist_repository.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeProfileRepo implements ProfileRepository {
  var user = AppUser(
    id: 1,
    email: 'a@b.c',
    role: 'CUSTOMER',
    firstName: 'Asha',
    lastName: 'K',
    phone: '9876543210',
  );
  final List<Map<String, String?>> updates = [];
  bool fail = false;

  @override
  Future<AppUser> fetch() async {
    if (fail) throw Exception('boom');
    return user;
  }

  @override
  Future<AppUser> update(
      {String? firstName, String? lastName, String? phone}) async {
    updates.add(
        {'firstName': firstName, 'lastName': lastName, 'phone': phone});
    user = AppUser(
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: firstName ?? user.firstName,
      lastName: lastName ?? user.lastName,
      phone: phone ?? user.phone,
    );
    return user;
  }
}

class _FakeWishlistRepo implements WishlistRepository {
  @override
  Future<List<String>> fetch() async => ['p-1', 'p-2'];

  @override
  Future<List<CatalogProduct>> fetchProducts() async => const [];
  @override
  Future<WishlistToggle> toggle(String slug, {bool hearted = false}) =>
      throw UnimplementedError();
}

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.store);
  final InMemoryTokenStore store;

  @override
  Future<AppUser> me() async => AppUser(
      id: 1, email: 'a@b.c', role: 'CUSTOMER', firstName: 'Asha');
  @override
  Future<AppUser> login(
          {required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AppUser> loginWithGoogle(String idToken) =>
      throw UnimplementedError();
  @override
  Future<void> register(
          {required String email,
          required String password,
          required String name,
          String phone = '',
          String role = 'CUSTOMER'}) =>
      throw UnimplementedError();
  @override
  Future<void> logout() async => store.clear();
  @override
  Future<void> mergeGuestCart() async {}
}

class _EmptyCatalogRepo implements CatalogRepository {
  @override
  Future<StorefrontRender> platformStorefront() async =>
      const StorefrontRender(
        store: StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: StoreTheme(),
      );
  @override
  Future<List<Category>> categories() async => const [];
  @override
  Future<CatalogPage> products(
          {String? category,
          String? brand,
          double? minPrice,
          double? maxPrice,
          double? minDiscount,
          bool? isFeatured,
          String? sort,
          int? page}) async =>
      const CatalogPage(results: [], total: 0, page: 1);
  @override
  Future<ProductDetail> product(String slug) => throw UnimplementedError();
  @override
  Future<List<Brand>> brands() => throw UnimplementedError();
  @override
  Future<CatalogPage> search(String query,
          {String? sort,
          int page = 1,
          String? category,
          double? minPrice,
          double? maxPrice,
          bool? isFeatured}) =>
      throw UnimplementedError();
  @override
  Future<PincodeInfo> pincode(String code) => throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

Future<ProviderContainer> _pumpAccount(
  WidgetTester tester, {
  required _FakeProfileRepo profile,
  String location = '/account',
}) async {
  final store = InMemoryTokenStore();
  await store.save(access: 'A', refresh: 'R');

  final container = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(store),
    authRepositoryProvider.overrideWithValue(_FakeAuthRepo(store)),
    profileRepositoryProvider.overrideWithValue(profile),
    wishlistRepositoryProvider.overrideWithValue(_FakeWishlistRepo()),
    catalogRepositoryProvider.overrideWithValue(_EmptyCatalogRepo()),
  ]);
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).boot();

  final router = GoRouter(
    initialLocation: location,
    refreshListenable: container.read(authChangeNotifierProvider),
    redirect: (context, state) {
      final auth = container.read(authControllerProvider);
      if (auth is AuthBooting) return null;
      if (auth is AuthSignedIn) return null;
      return '/login';
    },
    routes: [
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) =>
            const Scaffold(key: Key('login-page'), body: Text('LOGIN')),
      ),
      GoRoute(
        path: '/addresses',
        builder: (_, _) => const Scaffold(
            key: Key('addresses-page'), body: Text('ADDRESSES')),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (_, _) => const Scaffold(
            key: Key('wishlist-page'), body: Text('WISHLIST')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
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

  testWidgets('header shows monogram, name, phone and wishlist count',
      (tester) async {
    await _pumpAccount(tester, profile: _FakeProfileRepo());

    expect(find.text('AK'), findsOneWidget);
    expect(find.text('Asha K'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('edit profile patches and refreshes', (tester) async {
    final profile = _FakeProfileRepo();
    await _pumpAccount(tester, profile: profile);

    await tester.tap(find.byKey(const Key('profile-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('profile-first')), 'Asha R');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(profile.updates.single['firstName'], 'Asha R');
    expect(find.text('Asha R K'), findsOneWidget);
  });

  testWidgets('addresses row navigates; stub rows announce soon',
      (tester) async {
    await _pumpAccount(tester, profile: _FakeProfileRepo());

    await tester.tap(find.byKey(const Key('row-addresses')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('addresses-page')), findsOneWidget);
  });

  testWidgets('wishlist row opens the wishlist screen', (tester) async {
    await _pumpAccount(tester, profile: _FakeProfileRepo());

    await tester.tap(find.byKey(const Key('row-wishlist')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wishlist-page')), findsOneWidget);
  });

  testWidgets('theme chips switch the app mode', (tester) async {
    final container =
        await _pumpAccount(tester, profile: _FakeProfileRepo());

    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('notifications toggle flips locally', (tester) async {
    final container =
        await _pumpAccount(tester, profile: _FakeProfileRepo());

    await tester.tap(find.byKey(const Key('notif-switch')));
    await tester.pumpAndSettle();
    expect(container.read(notificationsEnabledProvider), isFalse);
  });

  testWidgets('sign out confirms and lands on login', (tester) async {
    final container =
        await _pumpAccount(tester, profile: _FakeProfileRepo());

    await scrollTo(tester, find.byKey(const Key('sign-out')));
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-out-confirm')));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider), isA<AuthGuest>());
    expect(find.byKey(const Key('login-page')), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final profile = _FakeProfileRepo()..fail = true;
    await _pumpAccount(tester, profile: profile);

    expect(find.text('Something went wrong'), findsOneWidget);
    profile.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Asha K'), findsOneWidget);
  });
}