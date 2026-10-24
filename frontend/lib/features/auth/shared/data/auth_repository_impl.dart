// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

/// Implementação concreta de [AuthRepository] que gerencia e delega chamadas para [AuthRemoteDataSource].
class AuthRepositoryImpl implements AuthRepository {
  /// Fonte de dados remota utilizada para operações de autenticação de rede.
  final AuthRemoteDataSource remoteDataSource;

  /// Cria uma instância de [AuthRepositoryImpl] com a [remoteDataSource] injetada.
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> recoverPassword({required String identity}) async {
    await remoteDataSource.sendPasswordResetInstructions(identity: identity);
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

  @override
  Future<bool> verifyOtpToken({
    required String identity,
    required String code,
  }) async {
    return await remoteDataSource.verifyOtpTokenRemote(
      identity: identity,
      code: code,
    );
  }

  @override
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
  }) async {
    await remoteDataSource.updatePasswordRemote(
      identity: identity,
      newPassword: newPassword,
    );
  }

  @override
  Future<bool> isTwoFactorRequired({
    required String identity,
    required String profile,
  }) async {
    return await remoteDataSource.checkTwoFactorStatusRemote(
      identity: identity,
      profile: profile,
    );
  }
}
