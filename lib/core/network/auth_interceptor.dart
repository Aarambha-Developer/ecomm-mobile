import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;
  Completer<void>? _refreshCompleter;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains(ApiConstants.refreshToken)) {
      handler.next(options);
      return;
    }
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final setCookies = response.headers['set-cookie'];
    if (setCookies != null) {
      for (final cookie in setCookies) {
        if (cookie.contains('access_token=')) {
          final token = cookie.split('access_token=')[1].split(';')[0];
          await _storage.saveAccessToken(token);
        }
        if (cookie.contains('refresh_token=')) {
          final token = cookie.split('refresh_token=')[1].split(';')[0];
          await _storage.saveRefreshToken(token);
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.requestOptions.path.contains(ApiConstants.refreshToken)) {
      await _storage.clearTokens();
      handler.reject(err);
      return;
    }
    if (err.response?.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {}
      }
      await _storage.clearTokens();
      handler.reject(err);
    } else {
      handler.reject(err);
    }
  }

  Future<String?> _tryRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future.then((_) => _storage.getAccessToken());
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;
    String? newAccessToken;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        await _storage.clearTokens();
        completer.complete();
        _refreshCompleter = null;
        return null;
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
        options: Options(
          sendTimeout: ApiConstants.refreshTimeout,
        ),
      );

      final responseData = response.data;
      final data = responseData is Map
          ? Map<String, dynamic>.from(responseData)['data']
          : null;
      final tokenData = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      newAccessToken = tokenData['access'] as String?;
      final newRefreshToken = tokenData['refresh'] as String?;

      if (newAccessToken != null) {
        await _storage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _storage.saveRefreshToken(newRefreshToken);
        }
      }

      if (newAccessToken == null) {
        await _storage.clearTokens();
      }

      completer.complete();
      _refreshCompleter = null;
      return newAccessToken;
    } catch (_) {
      await _storage.clearTokens();
      completer.complete();
      _refreshCompleter = null;
      return null;
    }
  }
}
