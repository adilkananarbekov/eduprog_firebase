import 'dart:convert';
import 'dart:io';

import 'package:eduprog_firebase/core/api/api_client.dart';
import 'package:eduprog_firebase/core/api/api_constants.dart';
import 'package:eduprog_firebase/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _base64UrlJson(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');
}

String _jwtWithExp(int exp) {
  final header = _base64UrlJson({'alg': 'HS256', 'typ': 'JWT'});
  final payload = _base64UrlJson({'exp': exp});
  return '$header.$payload.signature';
}

void main() {
  group('ApiClient', () {
    tearDown(ApiConstants.clearRuntimeBaseUrlOverride);

    test('sends auth header and query params on GET', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.queryParameters['search'], 'ada');
          expect(request.headers['Authorization'], 'Bearer token-123');
          return http.Response(json.encode({'ok': true}), 200);
        }),
      );
      client.setAuthToken('token-123');

      final response = await client.get(
        '/students',
        queryParams: {'search': 'ada'},
      );

      expect(response, {'ok': true});
    });

    test('maps 401 to UnauthorizedException and calls handler', () async {
      var unauthorizedHandled = false;
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(json.encode({'message': 'Nope'}), 401);
        }),
      );
      client.setUnauthorizedHandler(() async {
        unauthorizedHandled = true;
      });

      await expectLater(
        client.get('/secure'),
        throwsA(isA<UnauthorizedException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(unauthorizedHandled, isTrue);
    });

    test(
      'treats expired JWTs as unauthorized before sending the request',
      () async {
        var unauthorizedHandled = false;
        var requestSent = false;
        final client = ApiClient(
          client: MockClient((request) async {
            requestSent = true;
            return http.Response(json.encode({'ok': true}), 200);
          }),
        );
        client.setAuthToken(
          _jwtWithExp(
            DateTime.now()
                    .toUtc()
                    .subtract(const Duration(minutes: 2))
                    .millisecondsSinceEpoch ~/
                1000,
          ),
        );
        client.setUnauthorizedHandler(() async {
          unauthorizedHandled = true;
        });

        await expectLater(
          client.get('/secure'),
          throwsA(isA<UnauthorizedException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(requestSent, isFalse);
        expect(unauthorizedHandled, isTrue);
      },
    );

    test('refreshes an expired JWT before sending the request', () async {
      var refreshCount = 0;
      var requestCount = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          expect(request.headers['Authorization'], 'Bearer fresh-token');
          return http.Response(json.encode({'ok': true}), 200);
        }),
      );
      client.setAuthToken(
        _jwtWithExp(
          DateTime.now()
                  .toUtc()
                  .subtract(const Duration(minutes: 2))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );
      client.setRefreshHandler(() async {
        refreshCount++;
        client.setAuthToken('fresh-token');
        return true;
      });

      final response = await client.get('/secure');

      expect(response, {'ok': true});
      expect(refreshCount, 1);
      expect(requestCount, 1);
    });

    test(
      'maps auth-related 403 responses to UnauthorizedException and calls handler',
      () async {
        var unauthorizedHandled = false;
        final client = ApiClient(
          client: MockClient((request) async {
            return http.Response(
              json.encode({'message': 'JWT token expired'}),
              403,
            );
          }),
        );
        client.setAuthToken('header.payload.signature');
        client.setUnauthorizedHandler(() async {
          unauthorizedHandled = true;
        });

        await expectLater(
          client.get('/secure'),
          throwsA(isA<UnauthorizedException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(unauthorizedHandled, isTrue);
      },
    );

    test('keeps ordinary 403 responses as ForbiddenException', () async {
      var unauthorizedHandled = false;
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response(json.encode({'message': 'Access denied'}), 403);
        }),
      );
      client.setAuthToken('header.payload.signature');
      client.setUnauthorizedHandler(() async {
        unauthorizedHandled = true;
      });

      await expectLater(
        client.get('/secure'),
        throwsA(isA<ForbiddenException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(unauthorizedHandled, isFalse);
    });

    test('retries once after a 401 when token refresh succeeds', () async {
      var refreshCount = 0;
      var requestCount = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          if (requestCount == 1) {
            expect(request.headers['Authorization'], 'Bearer stale-token');
            return http.Response(json.encode({'message': 'Expired'}), 401);
          }

          expect(request.headers['Authorization'], 'Bearer fresh-token');
          return http.Response(json.encode({'ok': true}), 200);
        }),
      );
      client.setAuthToken('stale-token');
      client.setRefreshHandler(() async {
        refreshCount++;
        client.setAuthToken('fresh-token');
        return true;
      });

      final response = await client.get('/secure');

      expect(response, {'ok': true});
      expect(refreshCount, 1);
      expect(requestCount, 2);
    });

    test('throws ParseException for invalid JSON success responses', () async {
      final client = ApiClient(
        client: MockClient((request) async => http.Response('not-json', 200)),
      );

      await expectLater(client.get('/broken'), throwsA(isA<ParseException>()));
    });

    test('keeps auth requests on the remote backend when login fails', () async {
      ApiConstants.setRuntimeBaseUrlOverride(ApiConstants.remoteBackendUrl);

      var remoteAttempts = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          remoteAttempts++;
          throw const SocketException(
            'Connection closed before full header was received',
          );
        }),
      );

      await expectLater(
        client.post(
          ApiConstants.login,
          body: {'email': 'admin@edupage.com', 'password': 'admin123'},
          includeAuth: false,
        ),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.message,
            'message',
            contains(ApiConstants.remoteBackendUrl),
          ),
        ),
      );

      expect(remoteAttempts, 1);
      expect(ApiConstants.baseUrl, ApiConstants.remoteBackendUrl);
    });

    test('maps remote login 403 responses to UnauthorizedException', () async {
      ApiConstants.setRuntimeBaseUrlOverride(ApiConstants.remoteBackendUrl);

      final client = ApiClient(
        client: MockClient((request) async => http.Response('', 403)),
      );

      await expectLater(
        client.post(
          ApiConstants.login,
          body: {'email': 'admin@edupage.com', 'password': 'admin123'},
          includeAuth: false,
        ),
        throwsA(
          isA<UnauthorizedException>().having(
            (error) => error.message,
            'message',
            contains('cloud authentication endpoint'),
          ),
        ),
      );
    });
  });
}
