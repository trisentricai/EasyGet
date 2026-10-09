import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// JWT + guest-cart persistence.
///
/// Phase 1 ships two implementations: [InMemoryTokenStore] (tests, and any
/// platform without secure storage) and [SecureTokenStore] (Keychain /
/// Keystore via flutter_secure_storage) used at the composition root.
abstract class TokenStore {
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> save({required String access, required String refresh});
  Future<void> saveAccess(String access);
  Future<void> clear();

  Future<String?> readGuestToken();
  Future<void> saveGuestToken(String token);
  Future<void> clearGuestToken();
}

class InMemoryTokenStore implements TokenStore {
  static const _accessKey = 'eg_access';
  static const _refreshKey = 'eg_refresh';
  static const _guestKey = 'eg_guest';

  final _map = <String, String>{};

  @override
  Future<String?> readAccess() async => _map[_accessKey];

  @override
  Future<String?> readRefresh() async => _map[_refreshKey];

  @override
  Future<void> save({required String access, required String refresh}) async {
    _map[_accessKey] = access;
    _map[_refreshKey] = refresh;
  }

  @override
  Future<void> saveAccess(String access) async => _map[_accessKey] = access;

  @override
  Future<void> clear() async {
    _map.remove(_accessKey);
    _map.remove(_refreshKey);
  }

  @override
  Future<String?> readGuestToken() async => _map[_guestKey];

  @override
  Future<void> saveGuestToken(String token) async => _map[_guestKey] = token;

  @override
  Future<void> clearGuestToken() async => _map.remove(_guestKey);
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'eg_access';
  static const _refreshKey = 'eg_refresh';
  static const _guestKey = 'eg_guest';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccess() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  @override
  Future<String?> readGuestToken() => _storage.read(key: _guestKey);

  @override
  Future<void> saveGuestToken(String token) =>
      _storage.write(key: _guestKey, value: token);

  @override
  Future<void> clearGuestToken() => _storage.delete(key: _guestKey);
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
