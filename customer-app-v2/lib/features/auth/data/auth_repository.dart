import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_store.dart';
import 'app_user.dart';

/// All auth-related API calls. Abstract so screens/controllers can be driven by
/// fakes in tests.
abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String phone,
    String role,
  });

  Future<AppUser> me();

  Future<void> logout();

  /// Exchange a Google ID token for our access+refresh pair.
  Future<AppUser> loginWithGoogle(String idToken);

  /// Best-effort: folds a guest cart into the signed-in cart. Never throws.
  Future<void> mergeGuestCart();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );
    await _tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    await mergeGuestCart();
    return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {
    // Backend `RegisterSerializer` fields: first_name/last_name/phone/role.
    // The single UI "name" maps to first_name.
    await _api.post<dynamic>(
      ApiEndpoints.register,
      body: {
        'email': email,
        'password': password,
        'first_name': name,
        if (phone.isNotEmpty) 'phone': phone,
        'role': role,
      },
    );
  }

  @override
  Future<AppUser> me() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.me,
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );
    return AppUser.fromJson(data);
  }

  @override
  Future<void> logout() async {
    // The frozen contract (CONTEXT §2) exposes no logout endpoint; clearing
    // local tokens is the whole job here. Server-side blacklist is a backend
    // ticket if/when required.
    await _tokens.clear();
  }

  @override
  Future<AppUser> loginWithGoogle(String idToken) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.googleAuth,
      body: {'id_token': idToken},
      decode: (json) => (json as Map).cast<String, dynamic>(),
    );
    await _tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    await mergeGuestCart();
    return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  @override
  Future<void> mergeGuestCart() async {
    final guest = await _tokens.readGuestSessionKey();
    if (guest == null || guest.isEmpty) return;
    try {
      await _api.post<dynamic>(
        ApiEndpoints.cartMerge,
        body: {'session_key': guest},
      );
      await _tokens.clearGuestSessionKey();
    } on ApiException {
      // Server cart is truth (DESIGN §14); a failed merge never blocks sign-in.
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  );
});
