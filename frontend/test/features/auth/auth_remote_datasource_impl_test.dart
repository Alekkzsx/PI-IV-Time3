// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/features/auth/shared/external/auth_remote_datasource_impl.dart';

void main() {
  test(
    '2FA requires a real challenge before obtaining an access token',
    () async {
      final source = AuthRemoteDataSourceImpl(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) {
            return http.Response(
              jsonEncode({
                'requiresTwoFactor': true,
                'challengeToken': 'opaque-login-challenge',
              }),
              202,
            );
          }
          expect(request.url.path, '/api/auth/verify-two-factor');
          expect(jsonDecode(request.body), {
            'challengeToken': 'opaque-login-challenge',
            'code': '456789',
          });
          return http.Response(
            jsonEncode({'accessToken': 'verified-token'}),
            200,
          );
        }),
      );
      await expectLater(
        source.authenticateUser(
          identity: 'admin.test',
          password: 'test-password',
          profile: 'admin',
        ),
        throwsA(isA<TwoFactorChallenge>()),
      );
      expect(
        await source.completeTwoFactor(
          challengeToken: 'opaque-login-challenge',
          code: '456789',
        ),
        'verified-token',
      );
    },
  );
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

  test(
    'sendPasswordResetInstructions returns server metadata with maskedEmail and profile',
    () async {
      final source = AuthRemoteDataSourceImpl(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/send-recovery-otp');
          expect(jsonDecode(request.body), {'identity': '24802449'});
          return http.Response(
            jsonEncode({
              'status': 200,
              'success': true,
              'maskedEmail': 'a***1@gmail.com',
              'identity': '24802449',
              'displayName': 'Alex Gabriel Soares Sousa',
              'profile': 'aluno',
              'departmentOrCourse': 'Engenharia de Software',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await source.sendPasswordResetInstructions(identity: '24802449');
      expect(result['maskedEmail'], 'a***1@gmail.com');
      expect(result['displayName'], 'Alex Gabriel Soares Sousa');
      expect(result['profile'], 'aluno');
      expect(result['departmentOrCourse'], 'Engenharia de Software');
    },
  );

  test(
    'verifyRecoverySessionRemote returns complete verified user details from MongoDB',
    () async {
      final source = AuthRemoteDataSourceImpl(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/verify-recovery-otp');
          expect(jsonDecode(request.body), {
            'identity': '24802449',
            'code': '654321',
          });
          return http.Response(
            jsonEncode({
              'status': 200,
              'valid': true,
              'resetToken': 'valid-mongo-recovery-token',
              'identity': '24802449',
              'displayName': 'Alex Gabriel Soares Sousa',
              'email': 'alex.soares.gabriel111@gmail.com',
              'profile': 'aluno',
              'departmentOrCourse': 'Engenharia de Software',
              'campus': 'Unidade Sede',
              'semester': '2026/2 - 4º Semestre',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final sessionResult = await source.verifyRecoverySessionRemote(
        identity: '24802449',
        code: '654321',
      );

      expect(sessionResult.resetToken, 'valid-mongo-recovery-token');
      expect(sessionResult.displayName, 'Alex Gabriel Soares Sousa');
      expect(sessionResult.email, 'alex.soares.gabriel111@gmail.com');
      expect(sessionResult.departmentOrCourse, 'Engenharia de Software');
      expect(sessionResult.profile, 'aluno');
      expect(sessionResult.campus, 'Unidade Sede');
    },
  );
}
