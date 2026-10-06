// Desenvolvido por Marcelo Zarpelon. RA 25015323

abstract class AuthRepository {
  Future<void> recoverPassword({
    required String identity,
  });

  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  });
}
