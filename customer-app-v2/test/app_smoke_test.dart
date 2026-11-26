import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/engagement/data/analytics_repository.dart';
import 'package:easyget/features/engagement/data/app_update_repository.dart';
import 'package:easyget/features/engagement/data/order_watcher.dart';
import 'package:easyget/main.dart';
import 'package:easyget/models/app_update_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _NoopApiClient extends ApiClient {
  _NoopApiClient() : super(Dio());

  @override
  Future<void> warmUp() async {}
}

class _NoopAnalytics implements AnalyticsRepository {
  @override
  Future<void> track({
    required String eventType,
    Map<String, dynamic> properties = const {},
  }) async {}

  @override
  Future<void> trackBatch(List<AnalyticsEvent> events) async {}
}

class _NoopWatcher extends OrderStatusWatcher {
  @override
  void start() {}
}

class _NoopUpdateRepo implements AppUpdateRepository {
  @override
  Future<AppUpdateInfo> checkUpdate({
    required String platform,
    required String version,
  }) async {
    return AppUpdateInfo(updateAvailable: false, isMandatory: false);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first frame shows the EASYGET brand text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No stored tokens -> boot resolves guest without any network call.
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          // Warm-up is a real network ping; no-op it so no timers linger.
          apiClientProvider.overrideWithValue(_NoopApiClient()),
          // Telemetry fires on boot; no-op so no dio timers linger.
          analyticsRepositoryProvider.overrideWithValue(_NoopAnalytics()),
          // The 60s polling timer would outlive the widget test.
          orderWatcherProvider.overrideWith(() => _NoopWatcher()),
          // Avoid a real update-check HTTP call (Dio timers) on boot.
          appUpdateRepositoryProvider.overrideWithValue(_NoopUpdateRepo()),
        ],
        child: const EasyGetApp(),
      ),
    );
    await tester.pump();
    expect(find.text('EASYGET'), findsOneWidget);
    // Drain boot follow-ups so no platform timers outlive the test.
    await tester.pumpAndSettle();
  });
}
