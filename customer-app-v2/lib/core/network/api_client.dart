import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'session_lost.dart';

/// Shared Dio client: timeouts tuned for Render free-tier cold starts
/// (connect 90s / receive 60s, DESIGN §14), and every failure converted to
/// [ApiException]. Bearer-attach + single-flight 401 refresh are layered on
/// in Task 4's `AuthInterceptor`.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// Builds the base Dio with contract timeouts. Tests use their own Dio.
  static Dio createDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBase,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (o) => debugPrint('[api] $o'),
        ),
      );
    }

    return dio;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? decode,
  }) =>
      _run(() => _dio.get<dynamic>(path, queryParameters: query),
          decode: decode);

  Future<T> post<T>(
    String path, {
    Object? body,
    T Function(dynamic json)? decode,
  }) =>
      _run(() => _dio.post<dynamic>(path, data: body), decode: decode);

  Future<T> patch<T>(
    String path, {
    Object? body,
    T Function(dynamic json)? decode,
  }) =>
      _run(() => _dio.patch<dynamic>(path, data: body), decode: decode);

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<T> _run<T>(
    Future<Response<dynamic>> Function() call, {
    T Function(dynamic json)? decode,
  }) async {
    try {
      final res = await call();
      final data = res.data;
      if (decode != null) return decode(data);
      return data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Composition root for the shared HTTP client: contract timeouts + bearer /
/// single-flight-refresh interceptor. Session loss is broadcast on
/// [sessionLostProvider] so the auth layer can drop to guest without this file
/// depending on the auth feature.
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  final dio = ApiClient.createDio();
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokens: tokens,
      onSessionLost: () async => ref.read(sessionLostProvider).fire(),
    ),
  );
  return ApiClient(dio);
});
