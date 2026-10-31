import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_store.dart';

/// One analytics event. [sessionId] is stamped by the repository.
class AnalyticsEvent {
  const AnalyticsEvent({required this.eventType, this.properties = const {}});

  final String eventType;
  final Map<String, dynamic> properties;

  Map<String, dynamic> toJson(String sessionId) => {
        'event_type': eventType,
        'session_id': sessionId,
        'properties': properties,
      };
}

/// Telemetry sink. Abstract for fake tests.
abstract class AnalyticsRepository {
  Future<void> track({
    required String eventType,
    Map<String, dynamic> properties = const {},
  });

  Future<void> trackBatch(List<AnalyticsEvent> events);
}

class HttpAnalyticsRepository implements AnalyticsRepository {
  HttpAnalyticsRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  @override
  Future<void> track({
    required String eventType,
    Map<String, dynamic> properties = const {},
  }) async {
    final sessionId = await _sessionId();
    await _api.post<dynamic>(
      ApiEndpoints.analyticsEvents,
      body: {'event_type': eventType, 'session_id': sessionId, 'properties': properties},
    );
  }

  @override
  Future<void> trackBatch(List<AnalyticsEvent> events) async {
    final sessionId = await _sessionId();
    await _api.post<dynamic>(
      ApiEndpoints.analyticsBatch,
      body: events.map((e) => e.toJson(sessionId)).toList(),
    );
  }

  /// Stable device-generated id, persisted so a session survives restarts
  /// (DESIGN §14). Falls back to an in-memory id if storage is unavailable.
  Future<String> _sessionId() async {
    final existing = await _tokens.readSessionId();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateId();
    await _tokens.saveSessionId(id);
    return id;
  }

  String _generateId() {
    final rand = Random();
    final a = rand.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final b = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '$a$b';
  }
}

/// Convenience wrapper the app calls; telemetry never throws and never blocks a
/// user flow (mirrors `ApiClient.warmUp`).
class AnalyticsTracker {
  AnalyticsTracker(this._repo);

  final AnalyticsRepository _repo;

  Future<void> appOpen() => event('APP_OPEN');

  Future<void> pageView(String route) =>
      event('PAGE_VIEW', {'route': route});

  Future<void> event(String eventType, [Map<String, dynamic> properties = const {}]) async {
    try {
      await _repo.track(eventType: eventType, properties: properties);
    } catch (e) {
      if (kDebugMode) debugPrint('[analytics] $eventType failed: $e');
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return HttpAnalyticsRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  );
});

final analyticsTrackerProvider = Provider<AnalyticsTracker>((ref) {
  return AnalyticsTracker(ref.watch(analyticsRepositoryProvider));
});