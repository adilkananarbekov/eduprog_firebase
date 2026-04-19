import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_constants.dart';
import 'api_exception.dart';

/// HTTP client wrapper for making API requests with error handling
class ApiClient {
  final http.Client _client;
  String? _authToken;
  Future<void> Function()? _onUnauthorized;
  Future<bool> Function()? _onRefreshRequested;
  Future<bool>? _refreshInFlight;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set authentication token for subsequent requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get current authentication token
  String? get authToken => _authToken;

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Register a global unauthorized callback (e.g. token expired)
  void setUnauthorizedHandler(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  /// Register a token refresh callback that updates the stored auth token.
  void setRefreshHandler(Future<bool> Function()? handler) {
    _onRefreshRequested = handler;
  }

  /// Build headers for requests
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
    };

    if (includeAuth && _authToken != null) {
      headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$_authToken';
    }

    return headers;
  }

  String _buildUrlForBase(
    String baseUrl,
    String endpoint, {
    Map<String, String>? queryParams,
  }) {
    var url = '$baseUrl${ApiConstants.apiPrefix}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: queryParams).toString();
    }
    return url;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('password') ||
        normalized.contains('token') ||
        normalized.contains('authorization') ||
        normalized.contains('secret');
  }

  dynamic _sanitizeForLog(dynamic value, {String? key}) {
    if (key != null && _isSensitiveKey(key)) {
      return '***REDACTED***';
    }

    if (value is Map) {
      return value.map(
        (entryKey, entryValue) => MapEntry(
          entryKey.toString(),
          _sanitizeForLog(entryValue, key: entryKey.toString()),
        ),
      );
    }

    if (value is List) {
      return value.map((item) => _sanitizeForLog(item)).toList();
    }

    return value;
  }

  String _truncate(String value, {int maxLength = 500}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }

  String _describeBody(Object? body) {
    if (body == null) {
      return 'null';
    }

    return _truncate(json.encode(_sanitizeForLog(body)));
  }

  String _previewResponseBody(String body) {
    if (body.isEmpty) {
      return '(empty)';
    }

    try {
      final decoded = json.decode(body);
      return _truncate(json.encode(_sanitizeForLog(decoded)));
    } catch (_) {
      return _truncate(body);
    }
  }

  Map<String, dynamic>? _tryDecodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = json.decode(decoded);
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }

  bool _isJwtExpired(String token) {
    final payload = _tryDecodeJwtPayload(token);
    final exp = payload?['exp'];
    if (exp is! num) {
      return false;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    return !DateTime.now().toUtc().isBefore(
      expiresAt.subtract(const Duration(seconds: 30)),
    );
  }

  void _notifyUnauthorized() {
    final onUnauthorized = _onUnauthorized;
    if (onUnauthorized != null) {
      async.unawaited(onUnauthorized());
    }
  }

  String _extractErrorMessage(String responseBody, {int? statusCode}) {
    var errorMessage = statusCode == null
        ? 'Request failed'
        : 'Request failed with status $statusCode';

    try {
      final errorBody = json.decode(responseBody);
      if (errorBody is Map<String, dynamic>) {
        errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            errorBody['detail'] ??
            errorMessage;
      }
    } catch (_) {
      errorMessage = responseBody.isNotEmpty ? responseBody : errorMessage;
    }

    return errorMessage;
  }

  Future<bool> _attemptTokenRefresh() async {
    final onRefreshRequested = _onRefreshRequested;
    if (onRefreshRequested == null) {
      return false;
    }

    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = () async {
      try {
        _log('[API] Attempting token refresh');
        final refreshed = await onRefreshRequested();
        _log(
          refreshed
              ? '[API] Token refresh succeeded'
              : '[API] Token refresh unavailable',
        );
        return refreshed;
      } catch (e) {
        _log('[API] Token refresh failed: $e');
        return false;
      }
    }();

    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<void> _prepareAuthorizedRequest({required bool includeAuth}) async {
    final token = _authToken;
    if (!includeAuth || token == null || !_isJwtExpired(token)) {
      return;
    }

    final refreshed = await _attemptTokenRefresh();
    final updatedToken = _authToken;
    if (refreshed && updatedToken != null && !_isJwtExpired(updatedToken)) {
      return;
    }

    _log('[API] Skipping request because the stored JWT is expired');
    _notifyUnauthorized();
    throw UnauthorizedException(
      'Your session expired. Please sign in again.',
      statusCode: 401,
    );
  }

  bool _shouldTreatForbiddenAsUnauthorized(String errorMessage) {
    final token = _authToken;
    if (token != null && _isJwtExpired(token)) {
      return true;
    }

    final normalized = errorMessage.toLowerCase();
    const authIndicators = [
      'anonymous',
      'auth',
      'credential',
      'expired',
      'jwt',
      'login',
      'signature',
      'token',
      'unauthorized',
    ];

    return authIndicators.any(normalized.contains);
  }

  String _networkFailureMessage([Object? error]) {
    final baseUrl = ApiConstants.baseUrl;
    final isRemoteBackend = baseUrl == ApiConstants.remoteBackendUrl;
    final closedBeforeHeaders =
        error is http.ClientException &&
        error.message.contains(
          'Connection closed before full header was received',
        );

    if (isRemoteBackend) {
      if (closedBeforeHeaders) {
        return 'The remote backend at ${ApiConstants.remoteBackendUrl} '
            'closed the connection before finishing the response.';
      }

      return 'Unable to reach the remote backend at ${ApiConstants.remoteBackendUrl}.';
    }

    if (kDebugMode &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        baseUrl.contains('10.0.2.2')) {
      return 'Unable to reach the backend. In Android debug mode, 10.0.2.2 only works on emulators. '
          'If you are using a physical device, run with '
          '--dart-define=EDUOPS_BASE_URL=http://<your-computer-ip>:8080 or set up adb reverse.';
    }

    if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
      return 'Unable to reach the local backend at $baseUrl. '
          'Make sure Docker is running and the backend is listening on port 8080.';
    }

    return 'No internet connection. Please check your network.';
  }

  bool _isAuthenticationEndpoint(String endpoint) {
    return endpoint == ApiConstants.login || endpoint == ApiConstants.refresh;
  }

  Duration _requestTimeoutFor(
    String endpoint, {
    required bool includeAuth,
  }) {
    if (!includeAuth &&
        ApiConstants.baseUrl == ApiConstants.remoteBackendUrl &&
        _isAuthenticationEndpoint(endpoint)) {
      return ApiConstants.remoteAuthTimeout;
    }

    return ApiConstants.connectionTimeout;
  }

  String _timeoutFailureMessage(
    String url, {
    String? endpoint,
    required bool includeAuth,
    Duration? timeout,
  }) {
    final seconds = (timeout ?? ApiConstants.connectionTimeout).inSeconds;

    if (!includeAuth &&
        endpoint != null &&
        _isAuthenticationEndpoint(endpoint) &&
        url.startsWith(ApiConstants.remoteBackendUrl)) {
      return 'Authentication request to $url timed out after $seconds seconds. '
          'The cloud backend is not completing login requests.';
    }

    if (url.startsWith(ApiConstants.remoteBackendUrl)) {
      return 'Request to $url timed out after $seconds seconds. '
          'The remote backend is not responding.';
    }

    if (url.contains('localhost') ||
        url.contains('127.0.0.1') ||
        url.contains('10.0.2.2')) {
      return 'Request to $url timed out after $seconds seconds. '
          'Make sure the local backend is running and healthy on port 8080.';
    }

    return 'Request to $url timed out after $seconds seconds.';
  }

  ApiException _mapAuthenticationException({
    required String endpoint,
    required bool includeAuth,
    required String url,
    required ApiException error,
  }) {
    if (includeAuth ||
        !_isAuthenticationEndpoint(endpoint) ||
        ApiConstants.baseUrl != ApiConstants.remoteBackendUrl) {
      return error;
    }

    if (error is ForbiddenException) {
      return UnauthorizedException(
        'The cloud authentication endpoint at $url rejected the request. '
        'Verify that the cloud backend is deployed correctly and that the '
        'account exists there.',
        statusCode: error.statusCode,
      );
    }

    return error;
  }

  bool _shouldRetryWithRefresh(http.Response response) {
    if (response.statusCode == 401) {
      return true;
    }

    if (response.statusCode != 403) {
      return false;
    }

    final errorMessage = _extractErrorMessage(
      response.body,
      statusCode: response.statusCode,
    );
    return _shouldTreatForbiddenAsUnauthorized(errorMessage);
  }

  Future<dynamic> _sendWithRefreshRetry({
    required Future<http.Response> Function() send,
    required bool includeAuth,
  }) async {
    await _prepareAuthorizedRequest(includeAuth: includeAuth);

    var response = await send();
    if (includeAuth && _shouldRetryWithRefresh(response)) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        response = await send();
      }
    }

    return _handleResponse(response);
  }

  /// Handle HTTP response and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    _log(
      '[API] Response: $statusCode ${response.request?.method} ${response.request?.url}',
    );

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        _log('[API] Body: (empty)');
        return null;
      }

      try {
        final decoded = json.decode(response.body);
        _log('[API] Body: ${_previewResponseBody(response.body)}');
        return decoded;
      } catch (e) {
        _log('[API] PARSE ERROR: $e');
        _log('[API] Raw body: ${_previewResponseBody(response.body)}');
        throw ParseException(
          'Failed to parse response: ${e.toString()}',
          originalError: e,
        );
      }
    }

    _log('[API] ERROR $statusCode: ${_previewResponseBody(response.body)}');

    final errorMessage = _extractErrorMessage(
      response.body,
      statusCode: statusCode,
    );

    switch (statusCode) {
      case 400:
        throw ValidationException(errorMessage, statusCode: statusCode);
      case 401:
        _notifyUnauthorized();
        throw UnauthorizedException(errorMessage, statusCode: statusCode);
      case 403:
        if (_shouldTreatForbiddenAsUnauthorized(errorMessage)) {
          _notifyUnauthorized();
          throw UnauthorizedException(errorMessage, statusCode: statusCode);
        }
        throw ForbiddenException(errorMessage, statusCode: statusCode);
      case 404:
        throw NotFoundException(errorMessage, statusCode: statusCode);
      case >= 500:
        throw ServerException(errorMessage, statusCode: statusCode);
      default:
        throw UnknownException(errorMessage);
    }
  }

  /// Make GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrlForBase(
        ApiConstants.baseUrl,
        endpoint,
        queryParams: queryParams,
      );

      _log('[API] GET $url');
      return await _sendWithRefreshRetry(
        includeAuth: includeAuth,
        send: () => _client
            .get(
              Uri.parse(url),
              headers: _buildHeaders(includeAuth: includeAuth),
            )
            .timeout(ApiConstants.connectionTimeout),
      );
    } on SocketException catch (e) {
      _log('[API] GET SocketException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on http.ClientException catch (e) {
      _log('[API] GET ClientException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on async.TimeoutException catch (e) {
      _log('[API] GET Timeout: $e');
      throw ApiTimeoutException(
        _timeoutFailureMessage(
          _buildUrlForBase(
            ApiConstants.baseUrl,
            endpoint,
            queryParams: queryParams,
          ),
          includeAuth: includeAuth,
        ),
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log('[API] GET Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make POST request
  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrlForBase(
        ApiConstants.baseUrl,
        endpoint,
        queryParams: queryParams,
      );
      final timeout = _requestTimeoutFor(endpoint, includeAuth: includeAuth);

      _log('[API] POST $url');
      _log('[API] POST body: ${_describeBody(body)}');

      return await _sendWithRefreshRetry(
        includeAuth: includeAuth,
        send: () => _client
            .post(
              Uri.parse(url),
              headers: _buildHeaders(includeAuth: includeAuth),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(timeout),
      );
    } on SocketException catch (e) {
      _log('[API] POST SocketException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on http.ClientException catch (e) {
      _log('[API] POST ClientException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on async.TimeoutException catch (e) {
      _log('[API] POST Timeout: $e');
      throw ApiTimeoutException(
        _timeoutFailureMessage(
          _buildUrlForBase(
            ApiConstants.baseUrl,
            endpoint,
            queryParams: queryParams,
          ),
          endpoint: endpoint,
          includeAuth: includeAuth,
          timeout: _requestTimeoutFor(endpoint, includeAuth: includeAuth),
        ),
        originalError: e,
      );
    } on ApiException catch (e) {
      throw _mapAuthenticationException(
        endpoint: endpoint,
        includeAuth: includeAuth,
        url: _buildUrlForBase(
          ApiConstants.baseUrl,
          endpoint,
          queryParams: queryParams,
        ),
        error: e,
      );
    } catch (e) {
      _log('[API] POST Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make PUT request
  Future<dynamic> put(
    String endpoint, {
    Object? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrlForBase(ApiConstants.baseUrl, endpoint);
      _log('[API] PUT $url');
      _log('[API] PUT body: ${_describeBody(body)}');

      return await _sendWithRefreshRetry(
        includeAuth: includeAuth,
        send: () => _client
            .put(
              Uri.parse(url),
              headers: _buildHeaders(includeAuth: includeAuth),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(ApiConstants.connectionTimeout),
      );
    } on SocketException catch (e) {
      _log('[API] PUT SocketException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on http.ClientException catch (e) {
      _log('[API] PUT ClientException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on async.TimeoutException catch (e) {
      _log('[API] PUT Timeout: $e');
      throw ApiTimeoutException(
        _timeoutFailureMessage(
          _buildUrlForBase(ApiConstants.baseUrl, endpoint),
          includeAuth: includeAuth,
        ),
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log('[API] PUT Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make DELETE request
  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final url = _buildUrlForBase(ApiConstants.baseUrl, endpoint);
      _log('[API] DELETE $url');

      return await _sendWithRefreshRetry(
        includeAuth: includeAuth,
        send: () => _client
            .delete(
              Uri.parse(url),
              headers: _buildHeaders(includeAuth: includeAuth),
            )
            .timeout(ApiConstants.connectionTimeout),
      );
    } on SocketException catch (e) {
      _log('[API] DELETE SocketException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on http.ClientException catch (e) {
      _log('[API] DELETE ClientException: $e');
      throw NetworkException(_networkFailureMessage(e), originalError: e);
    } on async.TimeoutException catch (e) {
      _log('[API] DELETE Timeout: $e');
      throw ApiTimeoutException(
        _timeoutFailureMessage(
          _buildUrlForBase(ApiConstants.baseUrl, endpoint),
          includeAuth: includeAuth,
        ),
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      _log('[API] DELETE Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
