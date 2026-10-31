import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'api_endpoints.dart';

/// Attaches the bearer token and transparently recovers from a single 401.
///
/// Guarantees (DESIGN §14):
/// - `/auth/login/`, `/auth/refresh/`, `/auth/register/` never carry a bearer
///   and never trigger a refresh.
/// - Concurrent 401s share ONE refresh call (single-flight via `_refreshing`).
/// - A request is retried at most once; a second 401 ends the session.
/// - When the refresh token is dead the session is cleared and [onSessionLost]
///   fires exactly once.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokens,
    this.onSessionLost,
  });

  final Dio dio;
  final TokenStore tokens;
  final Future<void> Function()? onSessionLost;

  Future<String?>? _refreshing;
  bool _killed = false;

  bool _isAuthPath(String path) =>
      path.endsWith(ApiEndpoints.login) ||
      path.endsWith(ApiEndpoints.refresh) ||
      path.endsWith(ApiEndpoints.register);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthPath(options.path)) {
      handler.next(options);
      return;
    }
    final access = await tokens.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final status = err.response?.statusCode;

    if (status != 401 || _isAuthPath(request.path)) {
      handler.next(err);
      return;
    }

    if (request.extra['retried'] == true) {
      await _killOnce();
      handler.next(err);
      return;
    }

    final access = await _refreshOnce();
    if (access == null) {
      handler.next(err);
      return;
    }

    request.extra['retried'] = true;
    request.headers['Authorization'] = 'Bearer $access';
    try {
      final retry = await dio.fetch<dynamic>(request);
      handler.resolve(retry);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _killOnce();
      handler.next(e);
    }
  }

  Future<String?> _refreshOnce() {
    final pending = _refreshing;
    if (pending != null) return pending;
    _killed = false;
    return _refreshing = _refreshAndMaybeKill();
  }

  Future<String?> _refreshAndMaybeKill() async {
    final access = await _doRefresh();
    if (access == null) await _killOnce();
    _refreshing = null;
    return access;
  }

  Future<String?> _doRefresh() async {
    final refresh = await tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh': refresh},
      );
      final data = res.data;
      if (data is Map) {
        final access = data['access'];
        final rotated = data['refresh'];
        if (access is String && access.isNotEmpty) {
          if (rotated is String && rotated.isNotEmpty) {
            await tokens.save(access: access, refresh: rotated);
          } else {
            await tokens.saveAccess(access);
          }
          return access;
        }
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<void> _killOnce() async {
    if (_killed) return;
    _killed = true;
    await tokens.clear();
    await onSessionLost?.call();
  }
}
