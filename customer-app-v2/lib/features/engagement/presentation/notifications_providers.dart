import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_model.dart';
import '../data/notifications_repository.dart';

/// Notifications inbox state.
final notificationsListProvider =
    FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationsRepositoryProvider).list(),
);

final unreadCountProvider = FutureProvider<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).unreadCount(),
);
