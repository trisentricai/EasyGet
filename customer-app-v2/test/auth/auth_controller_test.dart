import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:easyget/features/auth/data/auth_repository.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _user = AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER');
final _freshUser =
    AppUser(id: 1, email: 'a@b.c', role: 'CUSTOMER', firstName: 'Asha');

class _FakeRepo implements AuthRepository {
  _FakeRepo(this.store);

  final InMemoryTokenStore store;
  AppUser? loginResult;
  Object? loginError;
  AppUser? meResult;
  Object? meError;
  Future<AppUser> Function()? meHook;
  int meCalls = 0;
  bool loggedOut = false;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {}

  @override
  Future<AppUser> me() async {
    meCalls++;
    if (meHook != null) return meHook!();
    if (meError != null) throw meError!;
    return meResult!;
  }

  @override
  Future<AppUser> loginWithGoogle(String idToken) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    await store.clear();
  }

  @override
  Future<void> mergeGuestCart() async {}
}

ProviderContainer _container(InMemoryTokenStore store, _FakeRepo repo) =>
    ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );

void main() {
  test('boot with a stored session resolves signedIn', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final repo = _FakeRepo(store)..meResult = _user;
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).boot();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });

  test('boot with no tokens lands on guest without any network call', () async {
    final store = InMemoryTokenStore();
    final repo = _FakeRepo(store);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).boot();

    expect(container.read(authControllerProvider), isA<AuthGuest>());
    expect(repo.meCalls, 0);
  });

  test('boot timeout lands on guest + coldStartHint, never stuck booting',
      () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final repo = _FakeRepo(store)
      ..meError = ApiException(ApiException.coldStartMessage);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).boot();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthGuest>());
    expect((state as AuthGuest).coldStartHint, isTrue);
    expect(state, isNot(isA<AuthBooting>()));
  });

  test('signIn success stores the session and returns no error', () async {
    final store = InMemoryTokenStore();
    final repo = _FakeRepo(store)..loginResult = _user;
    final container = _container(store, repo);
    addTearDown(container.dispose);

    final error = await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.c', password: 'secret');

    expect(error, isNull);
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });

  test('signIn failure keeps the message on a guest state', () async {
    final store = InMemoryTokenStore();
    final repo = _FakeRepo(store)
      ..loginError = ApiException('Wrong email or password.');
    final container = _container(store, repo);
    addTearDown(container.dispose);

    final error = await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.c', password: 'nope');

    expect(error, 'Wrong email or password.');
    final state = container.read(authControllerProvider);
    expect(state, isA<AuthGuest>());
    expect((state as AuthGuest).error, 'Wrong email or password.');
  });

  test('signOut clears tokens and lands on guest', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    final repo = _FakeRepo(store);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signOut();

    expect(container.read(authControllerProvider), isA<AuthGuest>());
    expect(repo.loggedOut, isTrue);
    expect(await store.readAccess(), isNull);
  });

  test('boot with a cached profile signs in without waiting on me()',
      () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    await store.saveUser(_user);
    var releaseMe = false;
    final repo = _FakeRepo(store)
      ..meHook = () async {
        while (!releaseMe) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return _freshUser;
      };
    final container = _container(store, repo);
    addTearDown(container.dispose);

    // boot() returns with the network still hanging: zero blocking.
    await container.read(authControllerProvider.notifier).boot();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).user.firstName, isEmpty);

    // Background refresh lands when the server answers, and re-caches.
    releaseMe = true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final refreshed = container.read(authControllerProvider);
    expect(refreshed, isA<AuthSignedIn>());
    expect((refreshed as AuthSignedIn).user.firstName, 'Asha');
    expect((await store.readUser())?.firstName, 'Asha');
  });

  test('background 401 drops a fast-booted session to guest', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    await store.saveUser(_user);
    final repo = _FakeRepo(store)
      ..meError = ApiException('Unauthorized.', statusCode: 401);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).boot();
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(authControllerProvider), isA<AuthGuest>());
    expect(repo.loggedOut, isTrue);
  });

  test('background cold-start failure keeps the cached session', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    await store.saveUser(_user);
    final repo = _FakeRepo(store)
      ..meError = ApiException(ApiException.coldStartMessage);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).boot();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(repo.loggedOut, isFalse);
  });

  test('signIn caches the profile for the next fast boot', () async {
    final store = InMemoryTokenStore();
    final repo = _FakeRepo(store)..loginResult = _user;
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.c', password: 'secret');

    expect((await store.readUser())?.email, 'a@b.c');
  });

  test('signOut clears the cached profile', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'A', refresh: 'R');
    await store.saveUser(_user);
    final repo = _FakeRepo(store);
    final container = _container(store, repo);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).signOut();

    expect(await store.readUser(), isNull);
  });
}
