// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

/// Resultado da validação do código de recuperação contendo metadados reais do MongoDB.
class RecoveryVerificationResult {
  final String resetToken;
  final String identity;
  final String displayName;
  final String email;
  final String profile;
  final String departmentOrCourse;
  final String campus;
  final String semester;

  const RecoveryVerificationResult({
    required this.resetToken,
    this.identity = '',
    this.displayName = '',
    this.email = '',
    this.profile = '',
    this.departmentOrCourse = '',
    this.campus = '',
    this.semester = '',
  });

  factory RecoveryVerificationResult.fromMap(Map<String, dynamic> map, String fallbackToken) {
    return RecoveryVerificationResult(
      resetToken: map['resetToken']?.toString() ?? map['recoveryToken']?.toString() ?? fallbackToken,
      identity: map['identity']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      profile: map['profile']?.toString() ?? '',
      departmentOrCourse: map['departmentOrCourse']?.toString() ?? map['department']?.toString() ?? '',
      campus: map['campus']?.toString() ?? '',
      semester: map['semester']?.toString() ?? '',
    );
  }
}

/// Contrato para comunicação remota com serviços e APIs de autenticação no backend.
abstract class AuthRemoteDataSource {
  Future<String> completeTwoFactor({
    required String challengeToken,
    required String code,
  });

  /// Envia requisição remota de redefinição de senha para a [identity] informada.
  /// Retorna o mapa de resposta do servidor contendo o maskedEmail real quando disponível.
  Future<Map<String, dynamic>> sendPasswordResetInstructions({
    required String identity,
    String? profile,
  });

  /// Envia credenciais ([identity], [password], [profile]) para autenticação remota junto ao servidor.
  ///
  /// Lança [Exception] em caso de credenciais incorretas ou falha de comunicação com o servidor.
  Future<String> authenticateUser({
    required String identity,
    required String password,
    required String profile,
  });

  /// Valida o token numérico OTP remotamente junto ao servidor.
  Future<bool> verifyOtpTokenRemote({
    required String identity,
    required String code,
  });

  /// Confirma o OTP de recuperação e devolve o grant temporário para redefinição.
  Future<String> verifyPasswordRecoveryCodeRemote({
    required String identity,
    required String code,
  });

  /// Confirma o OTP de recuperação e devolve a sessão completa com metadados do MongoDB.
  Future<RecoveryVerificationResult> verifyRecoverySessionRemote({
    required String identity,
    required String code,
    String? profile,
  });

  /// Atualiza a credencial de senha do usuário no servidor backend.
  Future<void> updatePasswordRemote({
    required String identity,
    required String newPassword,
    required String resetToken,
  });

  /// Consulta se a conta do usuário possui duplo fator (2FA) habilitado.
  Future<bool> checkTwoFactorStatusRemote({
    required String identity,
    required String profile,
  });
}
