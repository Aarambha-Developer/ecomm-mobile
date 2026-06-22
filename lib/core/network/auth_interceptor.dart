import 'package:dio/dio.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          await _storage.clearTokens();
          _isRefreshing = false;
          return handler.reject(err);
        }

        final response = await _dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
          data: {'refresh_token': refreshToken},
          options: Options(
            sendTimeout: ApiConstants.refreshTimeout,
          ),
        );

        final newAccessToken = response.data['data']['access'] as String?;
        final newRefreshToken = response.data['data']['refresh'] as String?;

        if (newAccessToken != null) {
          await _storage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken);
          }

          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        await _storage.clearTokens();
      }
      _isRefreshing = false;
    }
    handler.reject(err);
  }
}
