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

  /// Guest session cart key (server session_key), folded into the user cart on
  /// sign-in via `POST /cart/merge/` (DESIGN §14).
  Future<String?> readGuestSessionKey();
  Future<void> saveGuestSessionKey(String key);
  Future<void> clearGuestSessionKey();

  /// Stable device-generated analytics session id.
  Future<String?> readSessionId();
  Future<void> saveSessionId(String id);
}

class InMemoryTokenStore implements TokenStore {
  static const _accessKey = 'eg_access';
  static const _refreshKey = 'eg_refresh';
  static const _guestKey = 'eg_guest';
  static const _sessionKey = 'eg_session';

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
  Future<String?> readGuestSessionKey() async => _map[_guestKey];

  @override
  Future<void> saveGuestSessionKey(String key) async => _map[_guestKey] = key;

  @override
  Future<void> clearGuestSessionKey() async => _map.remove(_guestKey);

  @override
  Future<String?> readSessionId() async => _map[_sessionKey];

  @override
  Future<void> saveSessionId(String id) async => _map[_sessionKey] = id;
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'eg_access';
  static const _refreshKey = 'eg_refresh';
  static const _guestKey = 'eg_guest';
  static const _sessionKey = 'eg_session';

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
  Future<String?> readGuestSessionKey() => _storage.read(key: _guestKey);

  @override
  Future<void> saveGuestSessionKey(String key) =>
      _storage.write(key: _guestKey, value: key);

  @override
  Future<void> clearGuestSessionKey() => _storage.delete(key: _guestKey);

  @override
  Future<String?> readSessionId() => _storage.read(key: _sessionKey);

  @override
  Future<void> saveSessionId(String id) =>
      _storage.write(key: _sessionKey, value: id);
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
