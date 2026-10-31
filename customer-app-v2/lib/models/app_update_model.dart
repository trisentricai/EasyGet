/// Result of `POST /pwa/updates/check/` (force-upgrade gate).
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateAvailable,
    this.version,
    this.releaseNotes,
    this.downloadUrl,
    this.isMandatory = false,
  });

  final bool updateAvailable;
  final String? version;
  final String? releaseNotes;
  final String? downloadUrl;
  final bool isMandatory;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        updateAvailable: json['update_available'] == true,
        version: json['version'] as String?,
        releaseNotes: json['release_notes'] as String?,
        downloadUrl: json['download_url'] as String?,
        isMandatory: json['is_mandatory'] == true,
      );
}