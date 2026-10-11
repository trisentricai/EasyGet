import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

String devicePlatform() {
  if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
  if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
  return 'WEB';
}

/// Device-token registration (`POST /realtime/devices/`) so the backend can
/// target this phone with FCM pushes.
abstract class DeviceRepository {
  Future<void> registerToken(String token);
}

class HttpDeviceRepository implements DeviceRepository {
  HttpDeviceRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> registerToken(String token) async {
    await _api.post<dynamic>(
      ApiEndpoints.realtimeDevices,
      body: {
        'platform': devicePlatform(),
        'device_token': token,
        'user_agent': 'easyget-customer-app',
      },
    );
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return HttpDeviceRepository(ref.watch(apiClientProvider));
});