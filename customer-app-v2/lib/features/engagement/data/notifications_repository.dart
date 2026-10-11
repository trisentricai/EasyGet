import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/notification_model.dart';

/// Inbox notifications. Abstract for fake tests.
abstract class NotificationsRepository {
  Future<List<AppNotification>> list();

  Future<int> unreadCount();

  Future<void> markRead(int id);

  Future<void> markAllRead();
}

class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> list() async {
    final json = await _api.get<dynamic>(ApiEndpoints.notifications);
    final rows = json is Map && json['results'] is List
        ? json['results'] as List
        : (json is List ? json : const <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  @override
  Future<int> unreadCount() async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.notificationsUnreadCount,
      decode: (j) => (j as Map<String, dynamic>),
    );
    final value = json['unread_count'] ?? json['count'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  @override
  Future<void> markRead(int id) async {
    await _api.post<dynamic>(ApiEndpoints.notificationMarkRead('$id'));
  }

  @override
  Future<void> markAllRead() async {
    await _api.post<dynamic>(ApiEndpoints.notificationsMarkAllRead);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return HttpNotificationsRepository(ref.watch(apiClientProvider));
});