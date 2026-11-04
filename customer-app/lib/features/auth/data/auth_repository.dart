import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../../../models/user.dart';

/// Auth repository: wraps all auth-related API calls.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<void> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String phone = '',
    String role = 'CUSTOMER',
  }) async {
    await _api.post<dynamic>('/auth/register/', body: {
      'email': email,
      'password': password,
      if (firstName.isNotEmpty) 'first_name': firstName,
      if (lastName.isNotEmpty) 'last_name': lastName,
      if (phone.isNotEmpty) 'phone': phone,
      'role': role,
    });
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    await _api.post<dynamic>('/auth/otp/verify/', body: {
      'phone': phone,
      'code': code,
    });
  }

  Future<void> resendOtp(String phone) async {
    await _api.post<dynamic>('/auth/otp/send/', body: {'phone': phone});
  }

  Future<AppUser> login({required String email, required String password}) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login/',
      body: {'email': email, 'password': password},
      decode: (j) => j as Map<String, dynamic>,
    );
    await _tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefresh();
    try {
      if (refresh != null) {
        await _api.post<dynamic>('/auth/logout/', body: {'refresh': refresh});
      }
    } finally {
      await _tokens.clear();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  /// Exchange a Google ID token for our access+refresh pair.
  /// Same response contract as password login; same token storage.
  /// No Firebase: the ID token goes straight to POST /auth/google/.
  Future<AppUser> loginWithGoogleToken(String idToken) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/google/',
      body: {'id_token': idToken},
      decode: (j) => j as Map<String, dynamic>,
    );
    await _tokens.save(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  static bool _googleReady = false;

  /// Google sign-in. Returns null when the user cancels the flow.
  Future<AppUser?> signInWithGoogle() async {
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize();
        _googleReady = true;
      }
    } catch (_) {
      throw Exception('Google sign-in is not available here. Use email login.');
    }
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw Exception('Google did not return an ID token.');
    }
    return loginWithGoogleToken(googleIdToken);
  }

  Future<AppUser?> me() async {
    final access = await _tokens.readAccess();
    if (access == null) return null;
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/users/me/',
        decode: (j) => j as Map<String, dynamic>,
      );
      return AppUser.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser> updateProfile(Map<String, Object?> patch) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/users/me/',
      body: patch,
      decode: (j) => j as Map<String, dynamic>,
    );
    return AppUser.fromJson(data);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider));
});
