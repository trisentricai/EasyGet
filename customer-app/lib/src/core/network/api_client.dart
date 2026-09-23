import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

/// Shared Dio client: attaches the JWT, refreshes it once on 401,
/// and converts every failure into an [ApiException].
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? decode,
  }) async {
    return _run(() => _dio.get<dynamic>(path, queryParameters: query),
        decode: decode);
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    T Function(dynamic json)? decode,
  }) async {
    return _run(() => _dio.post<dynamic>(path, data: body), decode: decode);
  }

  Future<T> patch<T>(
    String path, {
    Object? body,
    T Function(dynamic json)? decode,
  }) async {
    return _run(() => _dio.patch<dynamic>(path, data: body), decode: decode);
  }

  Future<void> delete(String path) async {
    try {
      final res = await _dio.delete<dynamic>(path);
      if (res.statusCode != null && res.statusCode! >= 400) {
        throw ApiException('Request failed (${res.statusCode}).',
            statusCode: res.statusCode);
      }
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

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await tokens.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        // One transparent refresh per request (skip the refresh call itself).
        if (error.response?.statusCode == 401 &&
            request.extra['retried'] != true &&
            !request.path.endsWith('/auth/refresh/') &&
            !request.path.endsWith('/auth/login/')) {
          final refresh = await tokens.readRefresh();
          if (refresh != null && refresh.isNotEmpty) {
            try {
              final res = await Dio(BaseOptions(baseUrl: AppConfig.apiBase))
                  .post<dynamic>('/auth/refresh/', data: {'refresh': refresh});
              final access = (res.data as Map)['access'] as String?;
              if (access != null) {
                await tokens.saveAccess(access);
                request.extra['retried'] = true;
                request.headers['Authorization'] = 'Bearer $access';
                final retry = await dio.fetch<dynamic>(request);
                return handler.resolve(retry);
              }
            } catch (_) {
              // Fall through to the original 401 below.
            }
          }
          await tokens.clear();
        }
        handler.next(error);
      },
    ),
  );

  return ApiClient(dio);
});
