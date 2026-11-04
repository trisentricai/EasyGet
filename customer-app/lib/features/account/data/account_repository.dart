import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../models/user.dart';

/// Account repository: user profile management.
class AccountRepository {
  AccountRepository(this._api);

  final ApiClient _api;

  Future<AppUser> getProfile() async {
    final data = await _api.get<Map<String, dynamic>>(
      '/users/me/',
      decode: (j) => j as Map<String, dynamic>,
    );
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone'] = phone;

    final data = await _api.patch<Map<String, dynamic>>(
      '/users/me/',
      body: body,
      decode: (j) => j as Map<String, dynamic>,
    );
    return AppUser.fromJson(data);
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(apiClientProvider));
});
