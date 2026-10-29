// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/features/auth/shared/external/auth_remote_datasource_impl.dart';

void main() {
  test(
    'login envia credenciais ao serviço e devolve o token emitido',
    () async {
      late http.Request capturedRequest;
      final source = AuthRemoteDataSourceImpl(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'accessToken': 'jwt-token'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final token = await source.authenticateUser(
        identity: '2024.1.00001',
        password: 'valid-password',
        profile: 'aluno',
      );

      expect(capturedRequest.url.path, '/api/auth/login');
      expect(capturedRequest.method, 'POST');
      expect(jsonDecode(capturedRequest.body), {
        'identity': '2024.1.00001',
        'password': 'valid-password',
        'profile': 'aluno',
      });
      expect(token, 'jwt-token');
    },
  );

  test(
    'recuperação usa grant do backend ao verificar e redefinir senha',
    () async {
      final requests = <http.Request>[];
      final source = AuthRemoteDataSourceImpl(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/verify-recovery-otp')) {
            return http.Response(
              jsonEncode({
                'valid': true,
                'resetToken': 'temporary-one-time-reset-token',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 204);
        }),
      );

      final resetToken = await source.verifyPasswordRecoveryCodeRemote(
        identity: '2024.1.00001',
        code: '246810',
      );
      await source.updatePasswordRemote(
        identity: '2024.1.00001',
        newPassword: 'new-secure-password',
        resetToken: resetToken,
      );

      expect(requests, hasLength(2));
      expect(requests.first.url.path, '/api/auth/verify-recovery-otp');
      expect(requests.last.url.path, '/api/auth/reset-password');
      expect(jsonDecode(requests.last.body), {
        'identity': '2024.1.00001',
        'resetToken': 'temporary-one-time-reset-token',
        'newPassword': 'new-secure-password',
      });
    },
  );

  test(
    'falha de login do servidor não é contornada por fallback local',
    () async {
      final source = AuthRemoteDataSourceImpl(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'code': 'invalid_credentials',
              'message': 'Credenciais inválidas.',
            }),
            401,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        source.authenticateUser(
          identity: 'invalid-user',
          password: 'wrong-password',
          profile: 'aluno',
        ),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Credenciais inválidas.',
              ),
        ),
      );
    },
  );
}
