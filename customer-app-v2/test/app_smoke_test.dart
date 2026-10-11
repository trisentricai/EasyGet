import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/features/engagement/data/analytics_repository.dart';
import 'package:easyget/main.dart';
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
        ],
        child: const EasyGetApp(),
      ),
    );
    await tester.pump();
    expect(find.text('EASYGET'), findsOneWidget);
  });
}
