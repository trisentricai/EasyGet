import 'package:flutter_riverpod/legacy.dart';

/// Simple auth state holder for the router to use without provider type inference issues.
class AuthState {
  AuthState({this.booted = false, this.signedIn = false});

  final bool booted;
  final bool signedIn;

  AuthState copyWith({bool? booted, bool? signedIn}) => AuthState(
        booted: booted ?? this.booted,
        signedIn: signedIn ?? this.signedIn,
      );
}

/// A simple notifier that holds auth state for the router.
/// The auth controller updates this when auth state changes.
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState());

  void setBooted(bool booted) => state = state.copyWith(booted: booted);
  void setSignedIn(bool signedIn) => state = state.copyWith(signedIn: signedIn);
}

/// Provider for the auth state notifier.
final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});