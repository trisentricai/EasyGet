import 'package:easyget/core/storage/token_store.dart';
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
}
