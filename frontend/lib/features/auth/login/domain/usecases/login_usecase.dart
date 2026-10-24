// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/core/utils/input_validators.dart';

/// Caso de uso responsável pelas regras de negócio e validações defensivas do login.
///
/// Valida a integridade do identificador de acesso e da credencial informada
/// antes de delegar a execução da autenticação ao [AuthRepository].
class LoginUseCase {
  /// Repositório de autenticação que efetua a comunicação com a camada de dados/API.
  final AuthRepository repository;

  /// Cria uma instância de [LoginUseCase] recebendo o [repository] injetado.
  LoginUseCase(this.repository);

  /// Executa o fluxo de validação e autenticação.
  ///
  /// Validações defensivas executadas:
  /// - [identity]: identificador do usuário (R.A., matrícula ou e-mail), não pode ser vazio.
  /// - [password]: senha de acesso, não pode ser vazia e deve conter ao menos 6 caracteres.
  /// - [profile]: perfil de acesso selecionado (aluno, docente ou admin).
  ///
  /// Lança [Exception] caso alguma validação defensiva falhe ou caso o repositório
  /// rejeite as credenciais informadas.
  Future<void> call({
    required String identity,
    required String password,
    required String profile,
  }) async {
    final cleanIdentity = identity.trim();
    final identityError = InputValidators.validateIdentity(cleanIdentity);
    if (identityError != null) {
      throw Exception(identityError);
    }

    if (password.trim().isEmpty) {
      throw Exception('Informe sua senha.');
    }

    if (password.length < 6) {
      throw Exception('A senha precisa ter pelo menos 6 caracteres.');
    }

    if (!const {'aluno', 'docente', 'admin'}.contains(profile)) {
      throw Exception('Perfil de acesso inválido.');
    }

    await repository.login(
      identity: cleanIdentity,
      password: password,
      profile: profile,
    );
  }
}
