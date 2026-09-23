import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Session state: null = signed out, value = signed-in user.
/// While booting, [authBootProvider] resolves any saved session.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.watch(authRepositoryProvider).me();
  }

  Future<String?> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user =
          await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = AsyncData(user);
      return null;
    } catch (e) {
      state = AsyncData(null);
      return e.toString();
    }
  }

  Future<String?> signOut() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = AsyncData(null);
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
