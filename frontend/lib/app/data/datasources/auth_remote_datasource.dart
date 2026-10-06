// Desenvolvido por Marcelo Zarpelon. RA 25015323

abstract class AuthRemoteDataSource {
  Future<void> sendPasswordResetInstructions({
    required String identity,
  });

  Future<void> authenticateUser({
    required String identity,
    required String password,
    required String profile,
  });
}
