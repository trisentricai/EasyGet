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

  /// Absolute URL for backend-served media paths (/media/...).
  /// Returns null when there is nothing to show.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    final base = apiBase.replaceFirst(RegExp('/api/v1/?\$'), '');
    return '$base${path.startsWith('/') ? '' : '/media/'}$path';
  }

  static const storeSlug = String.fromEnvironment(
    'STORE_SLUG',
    defaultValue: 'easyget',
  );
}
