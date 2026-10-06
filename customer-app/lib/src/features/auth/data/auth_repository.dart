import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';

/// Firebase SDK errors mapped to display text (mirrors web firebaseErrorText).
String _friendlyFirebaseError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'Email already registered. Sign in instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
    }
  }
  return 'Sign-in failed. Please try again.';
}

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
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  /// Exchange a Firebase ID token for our access+refresh pair.
  /// Same response contract as password login; same token storage.
  Future<AppUser> loginWithFirebase(String idToken) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/firebase/',
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
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
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
    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e));
    }
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Could not complete Firebase sign-in.');
    }
    return loginWithFirebase(idToken);
  }

  Future<AppUser> firebaseEmailSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Could not complete Firebase sign-in.');
      }
      return loginWithFirebase(idToken);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e));
    }
  }

  Future<AppUser> firebaseEmailSignUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final idToken = await cred.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Could not complete Firebase sign-in.');
      }
      return loginWithFirebase(idToken);
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e));
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
