import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/app_update_model.dart';

/// App-version gate (`POST /pwa/updates/check/`). Abstract for fake tests.
abstract class AppUpdateRepository {
  Future<AppUpdateInfo> checkUpdate({
    required String platform,
    required String version,
  });
}

class HttpAppUpdateRepository implements AppUpdateRepository {
  HttpAppUpdateRepository(this._api);

  final ApiClient _api;

  @override
  Future<AppUpdateInfo> checkUpdate({
    required String platform,
    required String version,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.pwaUpdatesCheck,
      body: {'platform': platform, 'current_version': version},
      decode: (j) => (j as Map<String, dynamic>),
    );
    return AppUpdateInfo.fromJson(json);
  }
}

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return HttpAppUpdateRepository(ref.watch(apiClientProvider));
});