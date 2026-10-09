import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_exception.dart';

/// Wraps the platform Google sign-in flow so the screen can be driven by a
/// fake in tests. Returns the raw ID token; the repository exchanges it for our
/// JWT pair via `POST /auth/google/`.
abstract class GoogleAuthSource {
  /// The Google ID token, or `null` when the user cancelled.
  /// Throws [ApiException] with an honest sentence when the flow is
  /// unavailable (no Play Services / not configured) or fails.
  Future<String?> fetchIdToken();
}

class RealGoogleAuthSource implements GoogleAuthSource {
  static bool _ready = false;

  @override
  Future<String?> fetchIdToken() async {
    try {
      if (!_ready) {
        await GoogleSignIn.instance.initialize();
        _ready = true;
      }
    } catch (_) {
      throw ApiException(
        'Google sign-in is not available here. Use email login.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw ApiException('Google sign-in failed. Please try again.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Google did not return an ID token.');
    }
    return idToken;
  }
}

final googleAuthSourceProvider =
    Provider<GoogleAuthSource>((ref) => RealGoogleAuthSource());
