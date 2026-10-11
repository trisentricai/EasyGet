import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/status_pill.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/orders_providers.dart';

/// Local alert sink (wraps flutter_local_notifications; faked in tests).
abstract class LocalNotifier {
  /// True when alerts may show (channel ready + runtime grant).
  Future<bool> ensurePermission();

  Future<void> orderUpdate({
    required int orderId,
    required String orderNumber,
    required String status,
  });
}

class PluginLocalNotifier implements LocalNotifier {
  PluginLocalNotifier(this._plugin, {required this.onTapOrder});

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(int orderId) onTapOrder;

  static const _channel = AndroidNotificationChannel(
    'order_updates',
    'Order updates',
    description: 'Status changes on your active orders.',
    importance: Importance.high,
  );

  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) onTapOrder(id);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _ready = true;
  }

  @override
  Future<bool> ensurePermission() async {
    try {
      await _init();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> orderUpdate({
    required int orderId,
    required String orderNumber,
    required String status,
  }) async {
    try {
      await _plugin.show(
        id: orderId,
        title: 'Order $orderNumber',
        body: humanizeStatus(status),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: '$orderId',
      );
    } catch (_) {
      // Alerts are best-effort; the inbox + polling UI remain the source.
    }
  }
}

final localNotifierProvider = Provider<LocalNotifier>((ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  return PluginLocalNotifier(
    plugin,
    onTapOrder: (orderId) {
      try {
        ref.read(routerForNotificationsProvider).go('/order/$orderId');
      } catch (_) {}
    },
  );
});

/// GoRouter accessor without importing the router file (avoids a cycle:
/// app_router already imports engagement for telemetry).
final routerForNotificationsProvider = Provider<GoRouterShim>(
  (_) => throw UnimplementedError('wired in main.dart'),
);

/// Minimal navigation surface the notifier needs.
abstract class GoRouterShim {
  void go(String location);
}

/// Watches active orders every 60s while the app is open and raises a local
/// alert on new orders + status transitions. First poll only baselines
/// (no burst for pre-existing orders); permission denial is silent.
class OrderStatusWatcher extends Notifier<void> {
  static const interval = Duration(seconds: 60);

  Timer? _timer;
  Map<int, String> _last = {};
  bool _baselined = false;
  bool _started = false;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());
  }

  void start() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(interval, (_) => _poll());
    _poll();
  }

  /// Test seam: cancels the periodic timer (production code never calls
  /// this — the timer lives as long as the app scope).
  @visibleForTesting
  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  Future<void> _poll() async {
    try {
      if (!await ref.read(localNotifierProvider).ensurePermission()) return;
      final orders = await ref.read(ordersRepositoryProvider).list();
      final current = {
        for (final o in orders)
          if (!isPastOrder(o.status)) o.id: o.status,
      };
      final numbers = {
        for (final o in orders)
          if (!isPastOrder(o.status)) o.id: o.orderNumber,
      };
      if (!_baselined) {
        _last = current;
        _baselined = true;
        return;
      }
      final notifier = ref.read(localNotifierProvider);
      for (final entry in current.entries) {
        final previous = _last[entry.key];
        if (previous == null || previous != entry.value) {
          await notifier.orderUpdate(
            orderId: entry.key,
            orderNumber: numbers[entry.key] ?? '#${entry.key}',
            status: entry.value,
          );
        }
      }
      _last = current;
    } catch (_) {
      // Polling never breaks the app (logged-out sessions land here too).
    }
  }
}

final orderWatcherProvider =
    NotifierProvider<OrderStatusWatcher, void>(
  OrderStatusWatcher.new,
);
