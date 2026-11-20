// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:agmrm_security/security.dart';
export 'package:agmrm_security/security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenericFeedbackPolicy - Defesa Anti-Enumeração e Sanitização (M1)', () {
    test('Mensagem de falha de autenticação não revela existência de conta (R2)', () {
      expect(
        GenericFeedbackPolicy.authFailureMessage,
        equals('Credenciais inválidas. Verifique seu identificador e senha.'),
      );
    });

    test('Mensagens de recuperação são estritamente neutras e anti-enumeração (R3)', () {
      expect(
        GenericFeedbackPolicy.passwordResetRequestedMessage,
        equals(
          'Se o identificador informado estiver cadastrado em nosso sistema, as instruções de recuperação foram enviadas.',
        ),
      );
      expect(
        GenericFeedbackPolicy.recoveryRequestSuccessMessage,
        equals(
          'Se o identificador informado estiver cadastrado no sistema, as instruções e o código de verificação foram enviados para o e-mail institucional.',
        ),
      );
    });

    test('Formatação da contagem regressiva de lockout (R2)', () {
      expect(
        GenericFeedbackPolicy.lockoutMessage(30),
        equals('Muitas tentativas incorretas. Tente novamente em 30 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutMessage(1),
        equals('Muitas tentativas incorretas. Tente novamente em 1 segundo.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutMessage(0),
        equals('Muitas tentativas incorretas. Tente novamente em 0 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutMessage(-5),
        equals('Muitas tentativas incorretas. Tente novamente em 0 segundos.'),
      );

      // Countdown banner variant
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(30),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 30 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(0),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.'),
      );
    });

    test('Formatação de tentativas inválidas de código OTP (R3)', () {
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(2),
        equals('Código de verificação incorreto. Tentativas restantes: 2.'),
      );
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(1),
        equals('Código de verificação incorreto. Tentativas restantes: 1.'),
      );
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(0),
        equals('Código de verificação incorreto. Tentativas restantes: 0.'),
      );
    });

    test('Mensagens estáticas de expiração e revogação de tokens (R3)', () {
      expect(
        GenericFeedbackPolicy.expiredTokenMessage,
        equals('Código de verificação expirado. Solicite um novo código.'),
      );
      expect(
        GenericFeedbackPolicy.tokenExpiredMessage,
        equals('O código de verificação expirou. Solicite um novo código para continuar.'),
      );
      expect(
        GenericFeedbackPolicy.revokedSessionMessage,
        equals('Sessão de recuperação revogada por excesso de tentativas. Solicite um novo código.'),
      );
      expect(
        GenericFeedbackPolicy.tokenRevokedMessage,
        equals(
          'Número máximo de tentativas incorretas excedido. Por segurança, a sessão foi cancelada. Solicite uma nova recuperação.',
        ),
      );
    });

    test('Mensagens de complexidade de senha e sucesso de redefinição (R3)', () {
      expect(
        GenericFeedbackPolicy.weakPasswordMessage,
        contains('A nova senha não atende aos requisitos mínimos de segurança'),
      );
      expect(
        GenericFeedbackPolicy.passwordTooWeakMessage,
        contains('pontuação mínima: 3/4'),
      );
      expect(
        GenericFeedbackPolicy.passwordResetSuccessMessage,
        equals('Senha redefinida com sucesso. Faça login com a nova senha.'),
      );
    });

    test('Mensagens de payload e limites do servidor (R4)', () {
      expect(
        GenericFeedbackPolicy.badRequestPayloadMessage,
        equals('Dados da requisição inválidos.'),
      );
      expect(
        GenericFeedbackPolicy.invalidPayloadMessage,
        equals('Dados de requisição inválidos ou fora do formato permitido.'),
      );
      expect(
        GenericFeedbackPolicy.payloadTooLargeMessage,
        equals('Tamanho da requisição excede o limite permitido de 64 KB.'),
      );
      expect(
        GenericFeedbackPolicy.internalErrorMessage,
        equals('Ocorreu um erro interno ao processar a solicitação. Tente novamente mais tarde.'),
      );
      expect(
        GenericFeedbackPolicy.internalServerErrorMessage,
        equals('Ocorreu um erro no processamento da solicitação. Tente novamente mais tarde.'),
      );
    });

    test('Sanitização de exceções brutas impede vazamento de detalhes internos (R4)', () {
      // Exceções com termos de usuário inexistente devem ser mascaradas como falha genérica
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Exception: Usuário não encontrado no banco de dados'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('SQLException: relation "users" does not exist'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('NullPointerException at com.agmrm.auth.AuthService.login:42'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage(null),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
    });

    test('Sanitização categoriza mensagens operacionais de segurança corretamente', () {
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Lockout ativo - conta bloqueada'),
        equals('Acesso temporariamente bloqueado por excesso de tentativas.'),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Token expirado após 300 segundos'),
        equals(GenericFeedbackPolicy.tokenExpiredMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Sessão revogada por 3 tentativas inválidas'),
        equals(GenericFeedbackPolicy.tokenRevokedMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Senha fraca - entropia insuficiente'),
        equals(GenericFeedbackPolicy.passwordTooWeakMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Payload excedeu 64KB'),
        equals(GenericFeedbackPolicy.invalidPayloadMessage),
      );
    });

    test('Sanitização impede vazamento de revogação de OTP em contexto de autenticação', () {
      // Mensagens de tentativas de login NÃO podem retornar revogação de sessão de recuperação
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Erro ao decrementar tentativas de login'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Falha de autenticação após 3 tentativas'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Tentativas restantes: 2'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );

      // Lockout / Rate limiting legítimo mapeia para bloqueio temporário
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Limite de tentativas de login excedido'),
        equals(GenericFeedbackPolicy.accountLockedMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Acesso temporariamente bloqueado por cooldown'),
        equals(GenericFeedbackPolicy.accountLockedMessage),
      );

      // Revogação de OTP legítima requer contexto de código/verificação
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Código de verificação: limite de 3 tentativas excedido'),
        equals(GenericFeedbackPolicy.tokenRevokedMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Número máximo de tentativas do código OTP excedido'),
        equals(GenericFeedbackPolicy.tokenRevokedMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Sessão revogada por excesso de tentativas'),
        equals(GenericFeedbackPolicy.tokenRevokedMessage),
      );
    });
  });
}
