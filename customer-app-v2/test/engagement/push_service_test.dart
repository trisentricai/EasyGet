import 'dart:async';

import 'package:easyget/features/engagement/data/order_watcher.dart';
import 'package:easyget/features/engagement/data/push_repository.dart';
import 'package:easyget/features/engagement/data/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackend implements PushBackend {
  bool ready = true;
  bool permission = true;
  String? token = 'fcm-token-1';
  final foregroundController = StreamController<PushMessage>.broadcast();
  final openedController = StreamController<PushMessage>.broadcast();
  PushMessage? cold;

  @override
  Future<bool> ensureReady() async => ready;
  @override
  Future<void> watchBackground() async {}
  @override
  Future<bool> requestPermission() async => permission;
  @override
  Future<String?> fetchToken() async => token;
  @override
  Stream<PushMessage> get foreground => foregroundController.stream;
  @override
  Stream<PushMessage> get opened => openedController.stream;
  @override
  Future<PushMessage?> initial() async => cold;
}

class _FakeDevices implements DeviceRepository {
  final List<String> registered = [];

  @override
  Future<void> registerToken(String token) async {
    registered.add(token);
  }
}

class _FakeAlerts implements LocalNotifier {
  final List<Map<String, String?>> shown = [];

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<void> orderUpdate(
      {required int orderId,
      required String orderNumber,
      required String status}) async {}

  @override
  Future<void> showAlert(
      {required String title,
      required String body,
      String? payload}) async {
    shown.add({'title': title, 'body': body, 'payload': payload});
  }
}

PushService _service({
  required _FakeBackend backend,
  required _FakeDevices devices,
  required _FakeAlerts alerts,
  required bool signedIn,
  List<int> tapped = const [],
}) =>
    PushService(
      backend: backend,
      devices: devices,
      alerts: alerts,
      onTapOrder: tapped.add,
      isSignedIn: () => signedIn,
    );

void main() {
  test('guest sync does nothing', () async {
    final backend = _FakeBackend();
    final devices = _FakeDevices();
    final service = _service(
      backend: backend,
      devices: devices,
      alerts: _FakeAlerts(),
      signedIn: false,
    );

    await service.syncIfSignedIn();

    expect(devices.registered, isEmpty);
  });

  test('signed-in sync registers the token once', () async {
    final backend = _FakeBackend();
    final devices = _FakeDevices();
    final service = _service(
      backend: backend,
      devices: devices,
      alerts: _FakeAlerts(),
      signedIn: true,
    );

    await service.syncIfSignedIn();
    await service.syncIfSignedIn();

    expect(devices.registered, ['fcm-token-1']);
  });

  test('denied permission registers nothing', () async {
    final backend = _FakeBackend()..permission = false;
    final devices = _FakeDevices();
    final service = _service(
      backend: backend,
      devices: devices,
      alerts: _FakeAlerts(),
      signedIn: true,
    );

    await service.syncIfSignedIn();

    expect(devices.registered, isEmpty);
  });

  test('foreground messages display as alerts', () async {
    final backend = _FakeBackend();
    final alerts = _FakeAlerts();
    final service = _service(
      backend: backend,
      devices: _FakeDevices(),
      alerts: alerts,
      signedIn: true,
    );

    await service.syncIfSignedIn();
    backend.foregroundController
        .add(const PushMessage(title: 'Sale', body: 'Today only'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(alerts.shown.single['title'], 'Sale');
  });

  test('opened + cold-start messages deep-link to the order', () async {
    final backend = _FakeBackend();
    final tapped = <int>[];
    final service = _service(
      backend: backend,
      devices: _FakeDevices(),
      alerts: _FakeAlerts(),
      signedIn: true,
      tapped: tapped,
    );

    await service.syncIfSignedIn();
    backend.openedController.add(const PushMessage(orderId: 42));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tapped, [42]);
  });
}
