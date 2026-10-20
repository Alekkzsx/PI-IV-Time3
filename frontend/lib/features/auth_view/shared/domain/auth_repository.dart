// Desenvolvido por Marcelo Zarpelon - RA: 25015323

/// Contrato de repositório para operações de autenticação e recuperação de acesso na camada de Domínio.
abstract class AuthRepository {
  /// Solicita o envio de instruções para recuperação de senha associada à [identity].
  ///
  /// Lança exceção de domínio caso o identificador não seja encontrado ou ocorra falha de rede.
  Future<void> recoverPassword({
    required String identity,
  });

  /// Realiza a autenticação do usuário utilizando [identity], [password] e [profile].
  ///
  /// Lança exceção de domínio caso as credenciais sejam inválidas ou haja erro de comunicação.
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  });
}

