// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Contrato para comunicação remota com serviços e APIs de autenticação no backend.
abstract class AuthRemoteDataSource {
  /// Envia requisição remota de redefinição de senha para a [identity] informada.
  ///
  /// Lança [Exception] caso o serviço remoto rejeite a requisição ou ocorra falha de conexão.
  Future<void> sendPasswordResetInstructions({
    required String identity,
  });

  /// Envia credenciais ([identity], [password], [profile]) para autenticação remota junto ao servidor.
  ///
  /// Lança [Exception] em caso de credenciais incorretas ou falha de comunicação com o servidor.
  Future<void> authenticateUser({
    required String identity,
    required String password,
    required String profile,
  });
}

