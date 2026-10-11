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

  /// Google Places API key for address autocomplete (address form sheets).
  /// Empty by default — the sheets fall back to fully manual entry.
  /// Enable with: flutter run --dart-define=PLACES_API_KEY=AIza...
  /// (Needs the Places API enabled on the key, Android+iOS unrestricted or
  /// restricted to this app.)
  static const placesApiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue: '',
  );

  /// Google sign-in on Android/iOS needs the OAuth client that the backend
  /// accepts (`serverClientId`). Same value as customer-web's
  /// `VITE_GOOGLE_CLIENT_ID`. Public by design - embedded in the app binary.
  /// Override at build time: --dart-define=GOOGLE_CLIENT_ID=...
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '71530535214-rl0b86rgd7rdckh3rno418tfofkeo25c.apps.googleusercontent.com',
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
