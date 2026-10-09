import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';

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

final _routes = <RouteBase>[
  GoRoute(path: '/', builder: (_, _) => _placeholder('/')),
  GoRoute(path: '/login', builder: (_, _) => _placeholder('/login')),
  GoRoute(path: '/register', builder: (_, _) => _placeholder('/register')),
  GoRoute(path: '/home', builder: (_, _) => _placeholder('/home')),
  GoRoute(path: '/browse', builder: (_, _) => _placeholder('/browse')),
  GoRoute(path: '/search', builder: (_, _) => _placeholder('/search')),
  GoRoute(path: '/cart', builder: (_, _) => _placeholder('/cart')),
  GoRoute(path: '/orders', builder: (_, _) => _placeholder('/orders')),
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
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
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
