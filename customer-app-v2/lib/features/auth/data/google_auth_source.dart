import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
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
    final webClientId = AppConfig.googleClientId;
    if (webClientId.isEmpty) {
      // Backend refuses tokens for unknown audiences; a build without the
      // web/Android OAuth client ID can never mint a verifiable token.
      throw ApiException(
        'Google sign-in is not configured in this build yet. '
        'Use email login instead.',
      );
    }

    try {
      if (!_ready) {
        await GoogleSignIn.instance.initialize(serverClientId: webClientId);
        _ready = true;
      }
    } catch (e) {
      _ready = false;
      // No Google Play Services (AOSP emulators) or proxy'd environments land
      // here; keep the button honest instead of hanging.
      debugPrint('[google] init failed: $e');
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
      // Keep the raw framework code visible so on-device failures (e.g. an
      // absent Android OAuth client for this signing cert) are diagnosable.
      debugPrint('[google] sign-in failed: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw ApiException(
          'Google sign-in is not configured for this app build. '
          'Use email login instead.',
        );
      }
      throw ApiException('Google sign-in failed. Please try again.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Google did not return an ID token.');
    }
    // The audience is public (a JWT claim) and tells us which OAuth client the
    // token was minted for — essential when diagnosing 401s from /auth/google/.
    final parts = idToken.split('.');
    if (parts.length >= 2) {
      try {
        final payload =
            jsonDecode(
                  utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
                )
                as Map<String, dynamic>;
        debugPrint('[google] id token aud: ${payload['aud']}');
      } catch (_) {
        // Ignore malformed tokens here; the backend still verifies properly.
      }
    }
    return idToken;
  }
}

final googleAuthSourceProvider = Provider<GoogleAuthSource>(
  (ref) => RealGoogleAuthSource(),
);
