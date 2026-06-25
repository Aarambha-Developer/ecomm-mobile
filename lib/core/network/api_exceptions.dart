import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.statusCode});
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Session expired. Please login again.'])
      : super(statusCode: 401);
}

class ServerException extends AppException {
  ServerException(super.message, {super.statusCode});
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found'])
      : super(statusCode: 404);
}

class ValidationException extends AppException {
  final Map<String, dynamic> errors;

  ValidationException(super.message, this.errors, {super.statusCode});

  @override
  String toString() {
    if (errors.isEmpty) return message;
    final buffer = StringBuffer(message);
    buffer.write('\n');
    errors.forEach((key, value) {
      buffer.write('$key: $value\n');
    });
    return buffer.toString().trim();
  }
}

class ProfileUpdateException extends AppException {
  final Map<String, dynamic> errors;

  ProfileUpdateException(super.message, {this.errors = const {}, super.statusCode});

  String? get fieldErrorsSummary {
    if (errors.isEmpty) return null;
    return errors.entries
        .map((e) => '${e.key}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}')
        .join('\n');
  }
}

class RateLimitException extends AppException {
  RateLimitException([super.message = 'Too many requests. Please try again later.'])
      : super(statusCode: 429);
}

AppException handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException('Connection timed out. Please try again.');

    case DioExceptionType.connectionError:
      return NetworkException(
        'No internet connection. Please check your network.',
      );

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? 0;
      final data = error.response?.data;

      String message = 'Something went wrong';
      Map<String, dynamic>? errors;

      if (data is Map) {
        message = data['message'] as String? ?? message;
        if (data['errors'] is Map) {
          errors = Map<String, dynamic>.from(data['errors'] as Map);
        }
      }

      switch (statusCode) {
        case 400:
          return ValidationException(message, errors ?? {}, statusCode: statusCode);
        case 401:
          return UnauthorizedException(message);
        case 403:
          return AppException('Access denied', statusCode: statusCode);
        case 404:
          return NotFoundException(message);
        case 422:
          return ValidationException(message, errors ?? {}, statusCode: statusCode);
        case 429:
          return RateLimitException(message);
        case 500:
        case 502:
        case 503:
          return ServerException('Server error. Please try again later.', statusCode: statusCode);
        default:
          return AppException(message, statusCode: statusCode);
      }

    case DioExceptionType.cancel:
      return AppException('Request cancelled');

    case DioExceptionType.badCertificate:
      return NetworkException('Security error. Please try again.');

    case DioExceptionType.unknown:
      return NetworkException('An unexpected error occurred');
  }
}
