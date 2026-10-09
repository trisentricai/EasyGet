import 'dart:async';

import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/router/app_router.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/auth/data/google_auth_source.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/auth/presentation/auth_state.dart';
import 'package:easyget/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _user = AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER');

class _FakeRepo implements AuthRepository {
  _FakeRepo(this.store);

  final InMemoryTokenStore store;
  int loginCalls = 0;
  Future<AppUser> Function()? loginImpl;

  @override
  Future<AppUser> login({required String email, required String password}) {
    loginCalls++;
    return (loginImpl ?? () async => _user)();
  }

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
  Future<AppUser> me() async => _user;

  @override
  Future<void> logout() async => store.clear();

  @override
  Future<void> mergeGuestCart() async {}
}

class _FakeGoogle implements GoogleAuthSource {
  Object? error;
  String? token;

  @override
  Future<String?> fetchIdToken() async {
    if (error != null) throw error!;
    return token;
  }
}

Future<ProviderContainer> _pumpLogin(
  WidgetTester tester, {
  required _FakeRepo repo,
  _FakeGoogle? google,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(repo.store),
      googleAuthSourceProvider.overrideWithValue(google ?? _FakeGoogle()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(
          key: Key('home'),
          body: Text('HOME'),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Scaffold(
          key: Key('register'),
          body: Text('REGISTER'),
        ),
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
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('empty/invalid email validates inline without calling the repo',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    await _pumpLogin(tester, repo: repo);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('repo failure shows the human message and keeps typed input',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore())
      ..loginImpl = () async =>
          throw ApiException('Wrong email or password.');
    await _pumpLogin(tester, repo: repo);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'a@b.c');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'secret12');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.text('a@b.c'), findsOneWidget);
  });

  testWidgets('slow submit (>8s) shows the cold-start hint, CTA keeps size',
      (tester) async {
    final completer = Completer<AppUser>();
    final repo = _FakeRepo(InMemoryTokenStore())
      ..loginImpl = () => completer.future;
    await _pumpLogin(tester, repo: repo);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'a@b.c');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'secret12');

    final cta = find.byType(FilledButton);
    final sizeBefore = tester.getSize(cta);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Waking up the store…'), findsNothing);

    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Waking up the store…'), findsOneWidget);
    expect(tester.getSize(cta), sizeBefore);

    completer.completeError(ApiException('Wrong email or password.'));
    await tester.pumpAndSettle();
  });

  testWidgets('success signs the session in and lands on /home',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    final container = await _pumpLogin(tester, repo: repo);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'a@b.c');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'secret12');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(
      redirectFor('/login', booted: true, signedIn: true),
      '/home',
    );
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('google failure shows a snackbar and does not crash',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    final google = _FakeGoogle()
      ..error = ApiException(
          'Google sign-in is not available here. Use email login.');
    await _pumpLogin(tester, repo: repo, google: google);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Google sign-in is not available here. Use email login.'),
      findsOneWidget,
    );
  });

  testWidgets('password obscure toggle flips the field', (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    await _pumpLogin(tester, repo: repo);

    expect(tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
        isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
        isFalse);
  });
}
