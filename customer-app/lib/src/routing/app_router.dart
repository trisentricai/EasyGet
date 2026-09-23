import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/presentation/account_screen.dart';
import '../features/account/presentation/addresses_screen.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/catalog/presentation/browse_screen.dart';
import '../features/catalog/presentation/product_screen.dart';
import '../features/catalog/presentation/search_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import 'scaffold_shell.dart';

/// Fade + subtle rise, shared by every pushed page for a consistent feel.
CustomTransitionPage<void> _page(Widget child, {Object? key}) {
  return CustomTransitionPage(
    key: key is ValueKey ? key : null,
    child: child,
    transitionsBuilder: (context, animation, secondary, page) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: page),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final booted = ref.watch(authBootProvider).value ?? false;
  final signedIn = auth.value != null;

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      const public = ['/login', '/register', '/verify'];
      if (!booted) return null;
      if (!signedIn && !public.any(loc.startsWith)) return '/login';
      if (signedIn && public.any(loc.startsWith)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => _page(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) => _page(const RegisterScreen()),
      ),
      GoRoute(
        path: '/verify',
        pageBuilder: (c, s) {
          final email = (s.extra as String?) ?? '';
          return _page(OtpScreen(email: email));
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (c, s, shell) => _page(ScaffoldShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (c, s) => _page(const HomeScreen(), key: const ValueKey('h')),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/browse',
              pageBuilder: (c, s) {
                final cat = s.uri.queryParameters['category'];
                return _page(BrowseScreen(initialCategory: cat),
                    key: ValueKey('b-${cat ?? ''}'));
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (c, s) {
                final q = s.uri.queryParameters['q'];
                return _page(SearchScreen(initialQuery: q),
                    key: ValueKey('s-${q ?? ''}'));
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cart',
              pageBuilder: (c, s) => _page(const CartScreen(), key: const ValueKey('c')),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              pageBuilder: (c, s) => _page(const OrdersScreen(), key: const ValueKey('o')),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        pageBuilder: (c, s) => _page(
          ProductScreen(slug: s.pathParameters['slug'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (c, s) => _page(const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (c, s) => _page(
          OrderDetailScreen(id: s.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (c, s) => _page(const AccountScreen()),
      ),
      GoRoute(
        path: '/addresses',
        pageBuilder: (c, s) => _page(const AddressesScreen()),
      ),
    ],
  );
});
