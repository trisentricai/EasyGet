import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';

class AccountRepository {
  AccountRepository(this._auth);

  final AuthRepository _auth;

  Future<AppUser> profile() async {
    final user = await _auth.me();
    if (user == null) throw Exception('Session expired. Please sign in again.');
    return user;
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(authRepositoryProvider));
});
