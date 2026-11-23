/// Central app configuration.
///
/// Points at the deployed Render API by default so the app works online on
/// any device. For local development override with:
/// - Android emulator: flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1
/// - iOS simulator / desktop: flutter run --dart-define=API_BASE=http://127.0.0.1:8000/api/v1
class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://easyget-api.onrender.com/api/v1',
  );

  static const storeSlug = String.fromEnvironment(
    'STORE_SLUG',
    defaultValue: 'easyget',
  );

  /// Google sign-in on Android needs the *web* OAuth client from the same
  /// Google Cloud project as the Android client (the `client_type: 3` entry in
  /// `google-services.json`). Passing the customer-web client ID here makes
  /// Google Play Services reject the exchange with [28444] because the Android
  /// and web clients live in different projects. Public by design - embedded
  /// in the app binary, and must be listed in the backend's
  /// `GOOGLE_OAUTH_CLIENT_IDS` for the token exchange to succeed.
  /// Override at build time: --dart-define=GOOGLE_CLIENT_ID=...
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '86489065513-jkvv0k49c2erpu76m41krur4t7ffbk8e.apps.googleusercontent.com',
  );

  /// Absolute URL for backend-served media paths (/media/...).
  /// Returns null when there is nothing to show.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    final base = apiBase.replaceFirst(RegExp('/api/v1/?\$'), '');
    return '$base${path.startsWith('/') ? '' : '/media/'}$path';
  }
}
