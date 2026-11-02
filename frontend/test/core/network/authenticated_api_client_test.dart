// Desenvolvido por Guilherme Henrique Moreira
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';

void main() {
  setUp(() {
    AppUserSession.instance.onExpired = null;
    AppUserSession.instance.signOut();
  });
  tearDown(() => AppUserSession.instance.signOut());
  void signIn(String token) => AppUserSession.instance.signIn(
    identity: 'admin.test',
    profile: 'admin',
    accessToken: token,
  );

  test('sends the bearer token and decodes the actual response', () async {
    signIn('test-token');
    final api = AuthenticatedApiClient(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(jsonEncode({'profile': 'admin'}), 200);
      }),
    );
    expect(await api.request('GET', '/api/auth/me'), {'profile': 'admin'});
  });
  test('clears revoked sessions when the server rejects their token', () async {
    signIn('revoked-token');
    final api = AuthenticatedApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'session_revoked',
            'message': 'Entre novamente.',
          }),
          401,
        ),
      ),
    );
    await expectLater(
      api.request('GET', '/api/auth/me'),
      throwsA(isA<ApiException>()),
    );
    expect(AppUserSession.instance.isAuthenticated, false);
  });
  test(
    'keeps the current session when password confirmation is incorrect',
    () async {
      signIn('valid-token');
      final api = AuthenticatedApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'code': 'invalid_password',
              'message': 'Senha incorreta.',
            }),
            401,
          ),
        ),
      );
      await expectLater(
        api.request('POST', '/api/auth/change-password'),
        throwsA(isA<ApiException>()),
      );
      expect(AppUserSession.instance.accessToken, 'valid-token');
    },
  );
  test('an old request cannot clear a newer login session', () async {
    signIn('old-token');
    final received = Completer<void>();
    final response = Completer<http.Response>();
    final api = AuthenticatedApiClient(
      client: MockClient((_) async {
        received.complete();
        return response.future;
      }),
    );
    final pending = expectLater(
      api.request('GET', '/api/auth/me'),
      throwsA(isA<ApiException>()),
    );
    await received.future;
    signIn('new-token');
    response.complete(
      http.Response(jsonEncode({'code': 'invalid_token'}), 401),
    );
    await pending;
    expect(AppUserSession.instance.accessToken, 'new-token');
  });
  testWidgets('expires the local session at the JWT expiry time', (
    tester,
  ) async {
    final expiry =
        DateTime.now().add(const Duration(seconds: 2)).millisecondsSinceEpoch ~/
        1000;
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'exp': expiry})))
        .replaceAll('=', '');
    signIn('header.$payload.signature');
    expect(AppUserSession.instance.isAuthenticated, true);
    await tester.pump(const Duration(seconds: 3));
    expect(AppUserSession.instance.isAuthenticated, false);
  });
}
