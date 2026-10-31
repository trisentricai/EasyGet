import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal token backend: the slice of FlutterSecureStorage that TokenStore
/// needs, so web can swap in a memory implementation.
abstract class TokenBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _SecureBackend implements TokenBackend {
  const _SecureBackend(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Web fallback: flutter_secure_storage has no web implementation and a raw
/// write there throws (which used to fail Chrome sign-in at the token-save
/// step). Memory keeps web sessions working until the tab closes.
class _MemoryBackend implements TokenBackend {
  final _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

/// JWT persistence: Keychain on iOS, Keystore on Android, session memory
/// on web.
class TokenStore {
  TokenStore(this._backend);

  final TokenBackend _backend;

  static const _accessKey = 'eg_access';
  static const _refreshKey = 'eg_refresh';

  Future<String?> readAccess() => _backend.read(_accessKey);
  Future<String?> readRefresh() => _backend.read(_refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    await _backend.write(_accessKey, access);
    await _backend.write(_refreshKey, refresh);
  }

  Future<void> saveAccess(String access) =>
      _backend.write(_accessKey, access);

  Future<void> clear() async {
    await _backend.delete(_accessKey);
    await _backend.delete(_refreshKey);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  if (kIsWeb) return TokenStore(_MemoryBackend());
  return TokenStore(const _SecureBackend(FlutterSecureStorage()));
});
