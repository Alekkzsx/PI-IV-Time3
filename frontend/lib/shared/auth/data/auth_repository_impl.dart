// Desenvolvido por Marcelo Zarpelon. RA 25015323

import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> recoverPassword({
    required String identity,
  }) async {
    await remoteDataSource.sendPasswordResetInstructions(
      identity: identity,
    );
  }

  @override
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    await remoteDataSource.authenticateUser(
      identity: identity,
      password: password,
      profile: profile,
    );
  }
}
