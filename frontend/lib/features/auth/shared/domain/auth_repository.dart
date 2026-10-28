// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

/// Resultado detalhado de uma tentativa de autenticação, suportando prontidão para 2FA.
class AuthResult {
  /// Indica se a autenticação foi completada com sucesso.
  final bool isSuccess;

  /// Indica se a conta exige validação complementar de dois fatores (2FA).
  final bool requiresTwoFactor;

  /// Token de desafio temporário para validação do código 2FA.
  final String? challengeToken;

  /// Mensagem de erro em caso de falha de credenciais.
  final String? errorMessage;

  const AuthResult({
    required this.isSuccess,
    this.requiresTwoFactor = false,
    this.challengeToken,
    this.errorMessage,
  });

  factory AuthResult.success() => const AuthResult(isSuccess: true);
  factory AuthResult.twoFactorRequired(String token) => AuthResult(
    isSuccess: false,
    requiresTwoFactor: true,
    challengeToken: token,
  );
  factory AuthResult.failure(String error) =>
      AuthResult(isSuccess: false, errorMessage: error);
}

/// Contrato de repositório para operações de autenticação e recuperação de acesso na camada de Domínio.
abstract class AuthRepository {
  /// Solicita o envio de instruções para recuperação de senha associada à [identity].
  ///
  /// Lança exceção de domínio caso o identificador não seja encontrado ou ocorra falha de rede.
  Future<void> recoverPassword({required String identity});

  /// Realiza a autenticação do usuário utilizando [identity], [password] e [profile].
  ///
  /// Lança exceção de domínio caso as credenciais sejam inválidas ou haja erro de comunicação.
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  });

  /// Valida o token numérico OTP informado na recuperação de senha ou 2FA.
  Future<bool> verifyOtpToken({required String identity, required String code});

  /// Executa a redefinição da senha do usuário após verificação bem-sucedida do código.
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
  });

  /// Verifica se o usuário possui autenticação de dois fatores (2FA) ativada.
  /// (Preparação arquitetural de prontidão para 2FA).
  Future<bool> isTwoFactorRequired({
    required String identity,
    required String profile,
  });
}
