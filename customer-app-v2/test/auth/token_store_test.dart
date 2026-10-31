import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/auth/data/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InMemoryTokenStore roundtrips access + refresh', () async {
    final store = InMemoryTokenStore();

    expect(await store.readAccess(), isNull);
    expect(await store.readRefresh(), isNull);

    await store.save(access: 'a1', refresh: 'r1');
    expect(await store.readAccess(), 'a1');
    expect(await store.readRefresh(), 'r1');

    await store.saveAccess('a2');
    expect(await store.readAccess(), 'a2');
    expect(await store.readRefresh(), 'r1');
  });

  test('InMemoryTokenStore.clear wipes both tokens', () async {
    final store = InMemoryTokenStore();
    await store.save(access: 'a', refresh: 'r');

    await store.clear();

    expect(await store.readAccess(), isNull);
    expect(await store.readRefresh(), isNull);
  });

  test('InMemoryTokenStore is a TokenStore', () {
    expect(InMemoryTokenStore(), isA<TokenStore>());
  });

  test('user profile roundtrips and clear wipes it too', () async {
    final store = InMemoryTokenStore();
    expect(await store.readUser(), isNull);

    final user = AppUser(
        id: 7,
        email: 'a@b.c',
        role: 'CUSTOMER',
        firstName: 'Asha',
        phone: '9876543210');
    await store.saveUser(user);

    final back = (await store.readUser())!;
    expect(back.id, 7);
    expect(back.displayName, 'Asha');
    expect(back.phone, '9876543210');

    await store.clearUser();
    expect(await store.readUser(), isNull);
  });
}
