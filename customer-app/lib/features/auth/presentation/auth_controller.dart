import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../../../models/user.dart';
import 'auth_state.dart';

/// Session state: null = signed out, value = signed-in user.
/// While booting, [authBootProvider] resolves any saved session.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final user = await ref.watch(authRepositoryProvider).me();
    if (user != null) {
      ref.read(authStateNotifierProvider.notifier).setSignedIn(true);
    }
    ref.read(authStateNotifierProvider.notifier).setBooted(true);
    return user;
  }

  Future<String?> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = AsyncData(user);
      ref.read(authStateNotifierProvider.notifier).setSignedIn(true);
      ref.read(authStateNotifierProvider.notifier).setBooted(true);
      return null;
    } catch (e) {
      state = AsyncData(null);
      return _clean(e);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            firstName: name,
            phone: phone,
            role: role,
          );
      // Auto-login after registration
      final user = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = AsyncData(user);
      ref.read(authStateNotifierProvider.notifier).setSignedIn(true);
      ref.read(authStateNotifierProvider.notifier).setBooted(true);
      return null;
    } catch (e) {
      state = AsyncData(null);
      return _clean(e);
    }
  }

  Future<String?> sendOtp(String phone) async {
    try {
      await ref.read(authRepositoryProvider).resendOtp(phone);
      return null;
    } catch (e) {
      return _clean(e);
    }
  }

  Future<String?> verifyOtp({required String phone, required String code}) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phone: phone, code: code);
      // After OTP verify, the backend returns tokens - but our API doesn't
      // For now, we'll need to login with phone+code
      // This is a placeholder - adjust based on actual API response
      return null;
    } catch (e) {
      state = AsyncData(null);
      return _clean(e);
    }
  }

  /// Strips Dart's `Exception: ` prefix; ApiException already stringifies clean.
  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Google sign-in. Null error + null session = user cancelled (stay put);
  /// callers must check the session before navigating.
  Future<String?> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = AsyncData(user);
      return null;
    } catch (e) {
      state = AsyncData(null);
      return _clean(e);
    }
  }

  Future<String?> signOut() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = AsyncData(null);
      ref.read(authStateNotifierProvider.notifier).setSignedIn(false);
      ref.read(authStateNotifierProvider.notifier).setBooted(false);
      ref.invalidateSelf();
    }
    return null;
  }

  void refresh() => ref.invalidateSelf();
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

/// True once the first session check finished (used by the router gate).
final authBootProvider = FutureProvider<bool>((ref) async {
  await ref.watch(authControllerProvider.future);
  return true;
});