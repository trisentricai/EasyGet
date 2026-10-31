import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import 'order_watcher.dart';
import 'push_repository.dart';

/// A push message, normalized from FCM (foreground, tap, cold-start).
class PushMessage {
  const PushMessage({this.title, this.body, this.orderId});

  final String? title;
  final String? body;
  final int? orderId;

  factory PushMessage.fromRemote(RemoteMessage message) {
    final data = message.data;
    return PushMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      orderId: int.tryParse('${data['order_id'] ?? ''}'),
    );
  }
}

/// Firebase seam (faked in tests — the real SDK never runs under flutter_test).
abstract class PushBackend {
  /// Firebase.init guarded: false means pushes stay off (no Play services).
  Future<bool> ensureReady();
  Future<bool> requestPermission();
  Future<String?> fetchToken();

  /// Registers the killed-app handler (touches platform channels: only the
  /// real backend implements it).
  Future<void> watchBackground();

  Stream<PushMessage> get foreground;
  Stream<PushMessage> get opened;
  Future<PushMessage?> initial();
}

class FirebasePushBackend implements PushBackend {
  FirebaseMessaging get _bus => FirebaseMessaging.instance;

  @override
  Future<bool> ensureReady() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _bus.requestPermission(alert: true, badge: true);
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> fetchToken() => _bus.getToken();

  @override
  Future<void> watchBackground() async {
    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
  }

  @override
  Stream<PushMessage> get foreground =>
      FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  @override
  Stream<PushMessage> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  @override
  Future<PushMessage?> initial() async {
    final message = await _bus.getInitialMessage();
    return message == null ? null : PushMessage.fromRemote(message);
  }
}

/// Killed-app handler: shows the alert through a bare plugin instance (no
/// Riverpod in the background isolate).
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final parsed = PushMessage.fromRemote(message);
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: parsed.title ?? 'EasyGet',
      body: parsed.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          orderUpdatesChannelId,
          orderUpdatesChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: '${parsed.orderId ?? ''}',
    );
  } catch (_) {
    // Best-effort by design.
  }
}

/// FCM wiring: Firebase init (guarded — devices without Play services simply
/// get no pushes), permission, token registration while signed in, foreground
/// display, and tap/cold-start deep-linking to the order.
class PushService {
  PushService({
    required this.backend,
    required this.devices,
    required this.alerts,
    required this.onTapOrder,
    required this.isSignedIn,
  });

  final PushBackend backend;
  final DeviceRepository devices;
  final LocalNotifier alerts;
  final void Function(int orderId) onTapOrder;
  final bool Function() isSignedIn;

  bool _listening = false;
  bool _registeredThisLaunch = false;

  Future<void> syncIfSignedIn() async {
    if (!isSignedIn() || _registeredThisLaunch) return;
    if (!await backend.ensureReady()) return;
    await backend.watchBackground();
    if (!await backend.requestPermission()) return;
    final token = await backend.fetchToken();
    if (token == null || token.isEmpty) return;
    try {
      await devices.registerToken(token);
      _registeredThisLaunch = true;
    } catch (_) {
      // Retry next launch; pushes simply stay off until then.
    }
    _listen();
    final cold = await backend.initial();
    final coldId = cold?.orderId;
    if (coldId != null) onTapOrder(coldId);
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    backend.foreground.listen((message) {
      alerts.showAlert(
        title: message.title ?? 'EasyGet',
        body: message.body ?? '',
        payload: '${message.orderId ?? ''}',
      );
    });
    backend.opened.listen((message) {
      final id = message.orderId;
      if (id != null) onTapOrder(id);
    });
  }
}

final pushBackendProvider = Provider<PushBackend>((_) {
  return FirebasePushBackend();
});

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(
    backend: ref.watch(pushBackendProvider),
    devices: ref.watch(deviceRepositoryProvider),
    alerts: ref.watch(localNotifierProvider),
    onTapOrder: (orderId) {
      try {
        ref.read(routerForNotificationsProvider).go('/order/$orderId');
      } catch (_) {}
    },
    isSignedIn: () => ref.read(authControllerProvider) is AuthSignedIn,
  );
});
