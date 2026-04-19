/// Base class for all API exceptions
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

/// Exception thrown when network connectivity fails
class NetworkException extends ApiException {
  NetworkException(super.message, {super.originalError});
}

/// Exception thrown when the request times out
class ApiTimeoutException extends ApiException {
  ApiTimeoutException(super.message, {super.originalError});
}

/// Exception thrown when the server returns 401 Unauthorized
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, {super.statusCode});
}

/// Exception thrown when the server returns 403 Forbidden
class ForbiddenException extends ApiException {
  ForbiddenException(super.message, {super.statusCode});
}

/// Exception thrown when the server returns 404 Not Found
class NotFoundException extends ApiException {
  NotFoundException(super.message, {super.statusCode});
}

/// Exception thrown when the server returns 400 Bad Request or validation errors
class ValidationException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  ValidationException(super.message, {super.statusCode, this.validationErrors});
}

/// Exception thrown when the server returns 5xx Server Error
class ServerException extends ApiException {
  ServerException(super.message, {super.statusCode, super.originalError});
}

/// Exception thrown when unable to parse server response
class ParseException extends ApiException {
  ParseException(super.message, {super.originalError});
}

/// Exception thrown for unknown/unexpected errors
class UnknownException extends ApiException {
  UnknownException(super.message, {super.originalError});
}
