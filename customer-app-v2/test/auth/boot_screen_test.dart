import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/router/app_router.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/auth/presentation/auth_state.dart';
import 'package:easyget/features/auth/presentation/boot_screen.dart';
import 'package:easyget/features/engagement/data/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _user = AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER');

class _FakeRepo implements AuthRepository {
  _FakeRepo(this.store);

  final InMemoryTokenStore store;
  int meCalls = 0;
  Future<AppUser> Function()? meImpl;

  @override
  Future<AppUser> me() {
    meCalls++;
    return (meImpl ?? () async => _user)();
  }

  @override
  Future<AppUser> login({required String email, required String password}) async =>
      _user;

  @override
  Future<AppUser> loginWithGoogle(String idToken) async => _user;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {}

  @override
  Future<void> logout() async => store.clear();

  @override
  Future<void> mergeGuestCart() async {}
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

Future<ProviderContainer> _pumpBoot(
  WidgetTester tester, {
  required _FakeRepo repo,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(repo.store),
      // Warm-up pings the real backend; no-op it so no dio timers linger.
      apiClientProvider.overrideWithValue(_NoopApiClient()),
      // Boot fires APP_OPEN telemetry; no-op so no dio timers linger.
      analyticsRepositoryProvider.overrideWithValue(_NoopAnalytics()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: container.read(authChangeNotifierProvider),
    redirect: (context, state) {
      final auth = container.read(authControllerProvider);
      if (auth is AuthGuest && auth.coldStartHint && state.matchedLocation == '/') {
        return null; // keep the splash so the retry banner is reachable
      }
      return redirectFor(
        state.matchedLocation,
        booted: auth is! AuthBooting,
        signedIn: auth is AuthSignedIn,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const BootScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(key: Key('login'), body: Text('LOGIN')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(key: Key('home'), body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows splash, no hint before 3s, hint after', (tester) async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final completer = Completer<AppUser>();
    final repo = _FakeRepo(store)..meImpl = () => completer.future;

    await _pumpBoot(tester, repo: repo);

    expect(find.text('EASYGET'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Waking up the store…'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Waking up the store…'), findsOneWidget);

    completer.completeError(ApiException(ApiException.coldStartMessage));
    await tester.pumpAndSettle();
  });

  testWidgets('resolves a session and lands on /home', (tester) async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final repo = _FakeRepo(store);
    final container = await _pumpBoot(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('no tokens resolves guest straight to /login', (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    final container = await _pumpBoot(tester, repo: repo);
    await tester.pumpAndSettle();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthGuest>());
    expect(state, isNot(isA<AuthBooting>()));
    expect(repo.meCalls, 0);
    expect(redirectFor('/', booted: true, signedIn: false), '/login');
    expect(find.byKey(const Key('login')), findsOneWidget);
  });

  testWidgets('cold-start failure keeps a retry banner that re-runs boot',
      (tester) async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final repo = _FakeRepo(store)
      ..meImpl = () async => throw ApiException(ApiException.coldStartMessage);

    await _pumpBoot(tester, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(repo.meCalls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repo.meCalls, 2);
  });
}
