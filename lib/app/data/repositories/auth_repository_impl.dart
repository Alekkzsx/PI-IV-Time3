// Desenvolvido por Marcelo Zarpelon. RA 25015323

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

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
}
