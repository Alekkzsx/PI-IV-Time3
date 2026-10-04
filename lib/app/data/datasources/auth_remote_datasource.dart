// Desenvolvido por Marcelo Zarpelon. RA 25015323

abstract class AuthRemoteDataSource {
  Future<void> sendPasswordResetInstructions({
    required String identity,
  });
}
