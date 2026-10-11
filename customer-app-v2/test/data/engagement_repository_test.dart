import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/auth/presentation/auth_controller.dart';
import 'package:easyget/features/engagement/data/analytics_repository.dart';
import 'package:easyget/features/engagement/data/app_update_repository.dart';
import 'package:easyget/features/engagement/data/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late List<RequestOptions> seen;
  late TokenStore tokens;

  ApiClient buildClient(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    tokens = InMemoryTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return ApiClient(dio);
  }

  group('notifications', () {
    test('list decodes notifications', () async {
      final repo = HttpNotificationsRepository(buildClient((_) async => _json(
            '{"count":1,"results":[{"id":7,"title":"Order confirmed",'
            '"body":"Your order is confirmed","type":"ORDER","is_read":false,'
            '"created_at":"2026-10-08T10:01:00Z","data":{"order_id":101}}]}',
          )));

      final items = await repo.list();

      expect(seen.single.path, '/notifications/');
      expect(items.single.id, 7);
      expect(items.single.title, 'Order confirmed');
      expect(items.single.type, 'ORDER');
      expect(items.single.isRead, isFalse);
    });

    test('unreadCount returns an int', () async {
      final repo = HttpNotificationsRepository(
        buildClient((_) async => _json('{"count":3}')),
      );

      expect(await repo.unreadCount(), 3);
      expect(seen.single.path, '/notifications/unread_count/');
    });

    test('markRead + markAllRead POST', () async {
      final repo = HttpNotificationsRepository(
        buildClient((_) async => _json('{}')),
      );

      await repo.markRead(7);
      await repo.markAllRead();

      expect(seen[0].method, 'POST');
      expect(seen[0].path, '/notifications/7/mark_read/');
      expect(seen[1].path, '/notifications/mark_all_read/');
    });
  });

  group('analytics', () {
    test('track stamps a stable session_id from the token store', () async {
      final client = buildClient((_) async => _json('{}'));
      final repo = HttpAnalyticsRepository(client, tokens);

      await repo.track(eventType: 'PRODUCT_VIEW', properties: {'slug': 'x'});
      await repo.track(eventType: 'PRODUCT_VIEW');

      expect(seen[0].path, '/analytics/events/');
      final body = (seen[0].data as Map).cast<String, dynamic>();
      expect(body['event_type'], 'PRODUCT_VIEW');
      expect(body['properties'], {'slug': 'x'});
      final sessionId = body['session_id'] as String;
      expect(sessionId, isNotEmpty);

      // Same session id reused across events.
      final body2 = (seen[1].data as Map).cast<String, dynamic>();
      expect(body2['session_id'], sessionId);
      expect(await tokens.readSessionId(), sessionId);
    });

    test('trackBatch POSTs a list of events', () async {
      final client = buildClient((_) async => _json('{}'));
      final repo = HttpAnalyticsRepository(client, tokens);

      await repo.trackBatch([
        const AnalyticsEvent(eventType: 'APP_OPEN'),
        const AnalyticsEvent(eventType: 'PAGE_VIEW', properties: {'route': '/home'}),
      ]);

      expect(seen.single.path, '/analytics/events/batch/');
      final body = seen.single.data as List;
      expect(body, hasLength(2));
      expect((body.first as Map)['event_type'], 'APP_OPEN');
      expect((body.first as Map)['session_id'], isNotEmpty);
    });
  });

  group('app update', () {
    test('checkUpdate decodes AppUpdateInfo', () async {
      final repo = HttpAppUpdateRepository(buildClient((_) async => _json(
            '{"update_available":true,"version":"1.2.0",'
            '"release_notes":"Bug fixes","download_url":"https://x/app.apk",'
            '"is_mandatory":false}',
          )));

      final info = await repo.checkUpdate(platform: 'ANDROID', version: '1.0.0');

      expect(seen.single.path, '/pwa/updates/check/');
      expect(seen.single.data, {'platform': 'ANDROID', 'current_version': '1.0.0'});
      expect(info.updateAvailable, isTrue);
      expect(info.version, '1.2.0');
      expect(info.downloadUrl, 'https://x/app.apk');
      expect(info.isMandatory, isFalse);
    });
  });

  group('tracker', () {
    test('APP_OPEN is fired on auth boot', () async {
      final recorded = <String>[];
      final container = ProviderContainer(overrides: [
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        analyticsRepositoryProvider.overrideWithValue(
          _RecordingAnalytics((e) => recorded.add(e)),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).boot();

      expect(recorded, contains('APP_OPEN'));
    });
  });
}

class _RecordingAnalytics implements AnalyticsRepository {
  _RecordingAnalytics(this._record);

  final void Function(String eventType) _record;

  @override
  Future<void> track({
    required String eventType,
    Map<String, dynamic> properties = const {},
  }) async =>
      _record(eventType);

  @override
  Future<void> trackBatch(List<AnalyticsEvent> events) async {
    for (final e in events) {
      _record(e.eventType);
    }
  }
}