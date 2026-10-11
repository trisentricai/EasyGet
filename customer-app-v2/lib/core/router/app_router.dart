import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/boot_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/browse/presentation/browse_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/engagement/data/analytics_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/product/presentation/product_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../widgets/app_shell.dart';

const Set<String> _publicRoutes = {'/login', '/register'};

const Set<String> _privateRoutes = {
  '/home',
  '/browse',
  '/search',
  '/cart',
  '/orders',
  '/checkout',
  '/account',
  '/addresses',
  '/wishlist',
};

bool _isPrivate(String location) =>
    _privateRoutes.contains(location) || location.startsWith('/product/');

/// Pure redirect decision (DESIGN §14). Exported so the whole matrix is
/// unit-tested without a live router.
///
/// - Before boot resolves: hold (`null`) — S1 splash owns the screen, and
///   nothing is stranded mid-boot.
/// - Signed in: `/`, `/login`, `/register` bounce to `/home`; private routes
///   are allowed.
/// - Guest: `/` and private routes bounce to `/login`; public routes allowed.
String? redirectFor(
  String location, {
  required bool booted,
  required bool signedIn,
}) {
  if (!booted) return null;

  if (signedIn) {
    if (location == '/' ||
        location == '/login' ||
        location == '/register') {
      return '/home';
    }
    return null;
  }

  // Guest.
  if (location == '/') return '/login';
  if (_publicRoutes.contains(location)) return null;
  if (_isPrivate(location)) return '/login';
  return null;
}

Widget _placeholder(String route) => Scaffold(
      key: Key('placeholder-$route'),
      body: Center(child: Text('EASYGET · $route')),
    );

/// The 5 tab branches (DESIGN §11.5) hosted by [StatefulShellRoute] so tab
/// state survives switching. Finished screens render directly; the rest are
/// keyed placeholders until their plan replaces them screen-by-screen.
final _shellBranches = <StatefulShellBranch>[
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/browse',
        builder: (_, _) => const BrowseScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/search',
        builder: (_, _) => const SearchScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/cart',
        builder: (_, _) => const CartScreen(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/orders',
        builder: (_, _) => const OrdersScreen(),
      ),
    ],
  ),
];

final _routes = <RouteBase>[
  GoRoute(path: '/', builder: (_, _) => const BootScreen()),
  GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
  GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
  StatefulShellRoute.indexedStack(
    builder: (_, _, navigationShell) =>
        EasyGetShell(navigationShell: navigationShell),
    branches: _shellBranches,
  ),
  GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
  // Top-level (outside the shell) Browse: the Home "See all" pushes here so
  // system back returns to Home. The tab target stays untouched.
  GoRoute(
    path: '/browse/all',
    builder: (context, state) {
      final category = state.uri.queryParameters['category'];
      return BrowseScreen(key: ValueKey('browse-all-$category'));
    },
  ),
  GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
  GoRoute(path: '/addresses', builder: (_, _) => const AddressesScreen()),
  GoRoute(path: '/wishlist', builder: (_, _) => const WishlistScreen()),
  GoRoute(
    path: '/order/:id',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '');
      if (id == null) return _placeholder('/order/unknown');
      return OrderDetailScreen(key: ValueKey(id), orderId: id);
    },
  ),
  GoRoute(
    path: '/product/:slug',
    builder: (context, state) {
      // Keyed per slug so variant/gallery/review state never leaks across
      // products (e.g. related-rail jumps).
      final slug = state.pathParameters['slug']!;
      return ProductScreen(key: ValueKey(slug), slug: slug);
    },
  ),
];

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(authChangeNotifierProvider);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    observers: [
      _PageViewObserver(
        (route) => ref.read(analyticsTrackerProvider).pageView(route),
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      // A cold/unreachable backend keeps the splash so the retry banner stays
      // reachable; a genuine signed-out state still routes to /login.
      if (auth is AuthGuest &&
          auth.coldStartHint &&
          state.matchedLocation == '/') {
        return null;
      }
      return redirectFor(
        state.matchedLocation,
        booted: auth is! AuthBooting,
        signedIn: auth is AuthSignedIn,
      );
    },
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Fires `PAGE_VIEW` (via the no-throw [AnalyticsTracker]) whenever go_router
/// pushes a new location — telemetry never blocks or breaks navigation.
class _PageViewObserver extends NavigatorObserver {
  _PageViewObserver(this._onPageView);

  final void Function(String route) _onPageView;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) _onPageView(name);
    super.didPush(route, previousRoute);
  }
}
