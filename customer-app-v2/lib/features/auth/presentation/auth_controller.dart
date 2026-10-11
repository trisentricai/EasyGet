import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_lost.dart';
import '../../../core/storage/token_store.dart';
import '../../engagement/data/analytics_repository.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Bridge so go_router's `refreshListenable` re-evaluates `redirect` whenever the
/// session changes (Task 5).
class AuthChangeNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Owns the session lifecycle: boot / signIn / register / signOut.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen(sessionLostProvider, (_, _) {
      _emit(const AuthGuest(error: ApiException.sessionExpiredMessage));
    });
    return const AuthBooting();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);
  AnalyticsTracker get _analytics => ref.read(analyticsTrackerProvider);

  void _emit(AuthState next) {
    state = next;
    ref.read(authChangeNotifierProvider).bump();
  }

  /// Resolves any stored session. Never leaves the app stuck in [AuthBooting]:
  /// no tokens or any failure drops straight to guest (DESIGN §12 S1.2).
  Future<void> boot() async {
    _emit(const AuthBooting());
    // Fire-and-forget telemetry; never blocks or fails the boot (DESIGN §14).
    unawaited(_analytics.appOpen());
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      _emit(const AuthGuest());
      return;
    }
    try {
      final user = await _repo.me();
      _emit(AuthSignedIn(user));
    } on ApiException catch (e) {
      _emit(AuthGuest(
        error: e.message,
        coldStartHint: e.message == ApiException.coldStartMessage,
      ));
    } catch (e) {
      _emit(AuthGuest(error: _clean(e)));
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _repo.login(email: email, password: password);
      _emit(AuthSignedIn(user));
      return null;
    } on ApiException catch (e) {
      _emit(AuthGuest(error: e.message));
      return e.message;
    } catch (e) {
      final message = _clean(e);
      _emit(AuthGuest(error: message));
      return message;
    }
  }

  Future<String?> signInWithGoogle(String idToken) async {
    try {
      final user = await _repo.loginWithGoogle(idToken);
      _emit(AuthSignedIn(user));
      return null;
    } on ApiException catch (e) {
      _emit(AuthGuest(error: e.message));
      return e.message;
    } catch (e) {
      final message = _clean(e);
      _emit(AuthGuest(error: message));
      return message;
    }
  }

  /// Returns the [ApiException] on failure so screens can map DRF field
  /// errors; `null` means the account was created and auto-signed-in.
  Future<ApiException?> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String role = 'CUSTOMER',
  }) async {
    try {
      await _repo.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      final user = await _repo.login(email: email, password: password);
      _emit(AuthSignedIn(user));
      return null;
    } on ApiException catch (e) {
      _emit(AuthGuest(error: e.message));
      return e;
    } catch (e) {
      final message = _clean(e);
      _emit(AuthGuest(error: message));
      return ApiException(message);
    }
  }

  Future<void> signOut() async {
    await _repo.logout();
    _emit(const AuthGuest());
  }

  /// Strips Dart's `Exception: ` prefix; ApiException already stringifies clean.
  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
