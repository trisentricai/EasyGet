/// Central app configuration.
///
/// The API host differs per run target:
/// - Android emulator: 10.0.2.2 maps to the host loopback
/// - iOS simulator / desktop / web: host loopback directly
/// Override with: flutter run --dart-define=API_BASE=http://192.168.1.5:8000/api/v1
class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
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
    defaultValue: 'rahuls-store',
  );
}
