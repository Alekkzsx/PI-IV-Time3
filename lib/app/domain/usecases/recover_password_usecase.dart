// Desenvolvido por Marcelo Zarpelon. RA 25015323

import '../repositories/auth_repository.dart';

class RecoverPasswordUseCase {
  final AuthRepository repository;

  RecoverPasswordUseCase(this.repository);

  Future<void> call({
    required String identity,
  }) {
    return repository.recoverPassword(
      identity: identity,
    );
  }
}
