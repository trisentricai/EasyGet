import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/router/app_router.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/auth/presentation/auth_state.dart';
import 'package:easyget/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _user = AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER');

class _FakeRepo implements AuthRepository {
  _FakeRepo(this.store);

  final InMemoryTokenStore store;
  int registerCalls = 0;
  int loginCalls = 0;
  Object? registerError;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    loginCalls++;
    return _user;
  }

  @override
  Future<AppUser> loginWithGoogle(String idToken) async => _user;

  @override
  Future<AppUser> me() async => _user;

  @override
  Future<void> logout() async => store.clear();

  @override
  Future<void> mergeGuestCart() async {}
}

Future<ProviderContainer> _pumpRegister(
  WidgetTester tester, {
  required _FakeRepo repo,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(repo.store),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(
          key: Key('home'),
          body: Text('HOME'),
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

Future<void> _fill(
  WidgetTester tester, {
  String name = 'Rahul',
  String email = 'a@b.c',
  String password = 'secret1234',
  String phone = '',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), email);
  await tester.enterText(find.byType(TextFormField).at(2), password);
  if (phone.isNotEmpty) {
    await tester.enterText(find.byType(TextFormField).at(3), phone);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('validates name, email and password without calling the repo',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    await _pumpRegister(tester, repo: repo);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Minimum 8 characters'), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  testWidgets('DRF field error lands on the email field only', (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore())
      ..registerError = ApiException(
        'email: user with this email already exists.',
        payload: {
          'email': ['user with this email already exists.'],
        },
      );
    await _pumpRegister(tester, repo: repo);
    await _fill(tester, email: 'taken@b.c');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('user with this email already exists.'),
      findsOneWidget,
    );
    expect(find.text('Enter your name'), findsNothing);
  });

  testWidgets('success auto-logs in and lands on /home', (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    final container = await _pumpRegister(tester, repo: repo);
    await _fill(tester, phone: '');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(repo.registerCalls, 1);
    expect(repo.loginCalls, 1);
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(
      redirectFor('/register', booted: true, signedIn: true),
      '/home',
    );
    expect(find.byKey(const Key('home')), findsOneWidget);
  });

  testWidgets('network failure shows a snackbar and keeps input',
      (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore())
      ..registerError =
          ApiException('Cannot reach EasyGet right now. Check your connection.');
    await _pumpRegister(tester, repo: repo);
    await _fill(tester, name: 'Rahul', email: 'a@b.c');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cannot reach EasyGet right now. Check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('a@b.c'), findsOneWidget);
  });

  testWidgets('role segmented defaults to Customer', (tester) async {
    final repo = _FakeRepo(InMemoryTokenStore());
    await _pumpRegister(tester, repo: repo);

    final segmented = tester.widget<SegmentedButton<String>>(
      find.byType(SegmentedButton<String>),
    );
    expect(segmented.selected, {'CUSTOMER'});
  });
}
