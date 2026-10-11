import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/boot_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/browse/presentation/browse_screen.dart';
import '../../features/engagement/data/analytics_repository.dart';
import '../../features/home/presentation/home_screen.dart';
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
        builder: (_, _) =>
            const EasyGetTabScaffold(route: 'search', title: 'Search'),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/cart',
        builder: (_, _) =>
            const EasyGetTabScaffold(route: 'cart', title: 'Your cart'),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        path: '/orders',
        builder: (_, _) =>
            const EasyGetTabScaffold(route: 'orders', title: 'Your orders'),
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
  GoRoute(path: '/checkout', builder: (_, _) => _placeholder('/checkout')),
  GoRoute(path: '/account', builder: (_, _) => _placeholder('/account')),
  GoRoute(
    path: '/product/:slug',
    builder: (_, _) => _placeholder('/product/:slug'),
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
