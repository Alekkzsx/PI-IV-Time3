// Desenvolvido por Marcelo Zarpelon. RA 25015323

abstract class AuthRepository {
  Future<void> recoverPassword({
    required String identity,
  });
}
