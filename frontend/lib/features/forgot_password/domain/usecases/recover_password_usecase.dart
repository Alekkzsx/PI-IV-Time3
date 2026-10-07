// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../../../../shared/auth/domain/auth_repository.dart';

/// Caso de uso responsável por encapsular a regra de negócio de recuperação
/// de senha no sistema.
///
/// Delega a validação e o envio da solicitação de recuperação de credenciais
/// diretamente ao contrato abstrato de [AuthRepository].
class RecoverPasswordUseCase {
  /// Contrato do repositório de autenticação utilizado para processar a recuperação.
  final AuthRepository repository;

  /// Cria uma instância do caso de uso [RecoverPasswordUseCase] recebendo
  /// a dependência de [repository].
  RecoverPasswordUseCase(this.repository);

  /// Executa o fluxo de recuperação de senha para a identidade informada.
  ///
  /// Parâmetros:
  /// - [identity]: Identificador acadêmico do usuário (RA, matrícula funcional ou e-mail institucional).
  ///
  /// Retorna um [Future<void>] que se completa com sucesso quando a solicitação
  /// for despachada pelo repositório ou lança uma exceção em caso de falha.
  Future<void> call({
    required String identity,
  }) {
    return repository.recoverPassword(
      identity: identity,
    );
  }
}

