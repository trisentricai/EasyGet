import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Broadcast "the session is gone" (refresh failed / refresh token rejected).
///
/// The network layer owns detection; the auth controller subscribes and drops
/// to guest. Keeps `core/network` free of any dependency on the auth feature.
class SessionLostNotifier extends ChangeNotifier {
  void fire() => notifyListeners();
}

final sessionLostProvider = Provider<SessionLostNotifier>((ref) {
  final notifier = SessionLostNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
