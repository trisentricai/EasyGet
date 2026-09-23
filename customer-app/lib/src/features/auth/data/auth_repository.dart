import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.verified = false,
  });

  final int id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final String phone;
  final bool verified;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: (json['email'] ?? '') as String,
        role: (json['role'] ?? 'CUSTOMER') as String,
        firstName: (json['first_name'] ?? '') as String,
        lastName: (json['last_name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        verified: (json['is_email_verified'] ?? false) as bool,
      );
}

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
  }) async {
    await _api.post<dynamic>('/auth/register/', body: {
      'email': email,
      'password': password,
      if (firstName.isNotEmpty) 'first_name': firstName,
      if (lastName.isNotEmpty) 'last_name': lastName,
      if (phone.isNotEmpty) 'phone': phone,
    });
  }

  Future<void> verifyOtp({required String email, required String code}) async {
    await _api.post<dynamic>('/auth/verify-otp/', body: {
      'email': email,
      'code': code,
    });
  }

  Future<void> resendOtp(String email) async {
    await _api.post<dynamic>('/auth/resend-otp/', body: {'email': email});
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
    }
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
