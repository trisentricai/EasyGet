import '../data/app_user.dart';

/// Sealed session state the router and screens branch on.
sealed class AuthState {
  const AuthState();
}

/// First session check still running. [coldStartHint] flips once the check has
/// outlasted the cold-start threshold so the splash can show progress copy.
class AuthBooting extends AuthState {
  const AuthBooting({this.coldStartHint = false});

  final bool coldStartHint;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AppUser user;
}

/// No usable session: either never signed in, signed out, or the session was
/// lost. [error] carries a human sentence for the UI; [coldStartHint] marks a
/// boot that failed specifically because the API was cold/unreachable.
class AuthGuest extends AuthState {
  const AuthGuest({this.error, this.coldStartHint = false});

  final String? error;
  final bool coldStartHint;
}
