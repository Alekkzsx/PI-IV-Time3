// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../../../shared/auth/domain/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<void> call({
    required String identity,
    required String password,
    required String profile,
  }) async {
    final cleanIdentity = identity.trim();
    if (cleanIdentity.isEmpty) {
      throw Exception('Informe seu identificador de acesso.');
    }

    if (password.trim().isEmpty) {
      throw Exception('Informe sua senha.');
    }

    if (password.length < 6) {
      throw Exception('A senha precisa ter pelo menos 6 caracteres.');
    }

    await repository.login(
      identity: cleanIdentity,
      password: password,
      profile: profile,
    );
  }
}

