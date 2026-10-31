import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/data/app_user.dart';

/// Profile (`GET|PATCH /users/me/`). Abstract for fake tests.
abstract class ProfileRepository {
  Future<AppUser> fetch();

  Future<AppUser> update({
    String? firstName,
    String? lastName,
    String? phone,
  });
}

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<AppUser> fetch() async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.me,
      decode: (j) => (j as Map<String, dynamic>),
    );
    return AppUser.fromJson(json);
  }

  @override
  Future<AppUser> update({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final json = await _api.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      body: {
        'first_name': ?firstName,
        'last_name': ?lastName,
        'phone': ?phone,
      },
      decode: (j) => (j as Map<String, dynamic>),
    );
    return AppUser.fromJson(json);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return HttpProfileRepository(ref.watch(apiClientProvider));
});