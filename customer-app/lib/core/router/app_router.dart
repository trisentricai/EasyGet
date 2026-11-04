import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_verify_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/catalog/browse/browse_screen.dart';
import '../../features/catalog/search/search_screen.dart';
import '../../features/catalog/pdp/pdp_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/track_order_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/addresses_screen.dart';
import '../../features/exceptions/offline_screen.dart';
import '../../features/exceptions/server_error_screen.dart';
import '../../features/exceptions/not_found_screen.dart';
import '../../shared_widgets/scaffold_shell.dart';

/// Pokes the router whenever auth state changes, WITHOUT rebuilding the
/// router itself. Recreating GoRouter on every auth change used to wipe the
/// whole navigation stack mid-flight: the login page remounted (typed input
/// vanished) and the pending sign-in result was dropped silently.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateNotifierProvider, (_, next) {
      _booted = next.booted;
      _signedIn = next.signedIn;
      notifyListeners();
    });
  }

  bool _booted = false;
  bool _signedIn = false;

  bool get booted => _booted;
  bool get signedIn => _signedIn;
}


final appRouterProvider = Provider<GoRouter>((ref) {
    final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final booted = refresh.booted;
      final signedIn = refresh.signedIn;
      final loc = state.matchedLocation;
      const public = ['/login', '/register', '/otp_verify'];
      if (!booted) return null;
      if (signedIn) {
        if (loc == '/' || public.any(loc.startsWith)) return '/home';
        return null;
      }
      if (public.any(loc.startsWith)) return null;
      return '/login';
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) => const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: '/otp_verify',
        pageBuilder: (c, s) {
          final phone = (s.extra as String?) ?? '';
          return NoTransitionPage(child: OtpVerifyScreen(phone: phone));
        },
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (c, s, shell) => NoTransitionPage(
          child: ScaffoldShell(shell: shell),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (c, s) => const NoTransitionPage(
                child: HomeScreen(),
                key: ValueKey('home'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/browse',
              pageBuilder: (c, s) {
                final cat = s.uri.queryParameters['category'];
                return NoTransitionPage(
                  child: BrowseScreen(initialCategory: cat),
                  key: ValueKey('browse-\${cat ?? ''}'),
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (c, s) {
                final q = s.uri.queryParameters['q'];
                return NoTransitionPage(
                  child: SearchScreen(initialQuery: q),
                  key: ValueKey('search-\${q ?? ''}'),
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/cart',
              pageBuilder: (c, s) => const NoTransitionPage(
                child: CartScreen(),
                key: ValueKey('cart'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              pageBuilder: (c, s) => const NoTransitionPage(
                child: OrdersScreen(),
                key: ValueKey('orders'),
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        pageBuilder: (c, s) => NoTransitionPage(
          child: PdpScreen(slug: s.pathParameters['slug'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (c, s) => const NoTransitionPage(child: CheckoutScreen()),
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (c, s) => NoTransitionPage(
          child: TrackOrderScreen(id: s.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (c, s) => const NoTransitionPage(child: AccountScreen()),
      ),
      GoRoute(
        path: '/addresses',
        pageBuilder: (c, s) => const NoTransitionPage(child: AddressesScreen()),
      ),
      GoRoute(
        path: '/offline',
        pageBuilder: (c, s) => const NoTransitionPage(child: OfflineScreen()),
      ),
      GoRoute(
        path: '/server_error',
        pageBuilder: (c, s) => const NoTransitionPage(child: ServerErrorScreen()),
      ),
      GoRoute(
        path: '/not_found',
        pageBuilder: (c, s) => const NoTransitionPage(child: NotFoundScreen()),
      ),
    ],
  );
});