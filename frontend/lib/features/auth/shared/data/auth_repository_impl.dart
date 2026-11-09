// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

import '../domain/models/recovery_session.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';

/// Implementação concreta de [AuthRepository] que gerencia e delega chamadas para [AuthRemoteDataSource].
class AuthRepositoryImpl implements AuthRepository {
  /// Fonte de dados remota utilizada para operações de autenticação de rede.
  final AuthRemoteDataSource remoteDataSource;

  /// Cria uma instância de [AuthRepositoryImpl] com a [remoteDataSource] injetada.
  AuthRepositoryImpl(this.remoteDataSource);

  Future<String> completeTwoFactor({
    required String challengeToken,
    required String code,
  }) => remoteDataSource.completeTwoFactor(
    challengeToken: challengeToken,
    code: code,
  );

  @override
  Future<void> recoverPassword({required String identity}) async {
    await remoteDataSource.sendPasswordResetInstructions(identity: identity);
  }

  @override
  Future<Map<String, dynamic>> recoverPasswordDetails({required String identity}) async {
    return await remoteDataSource.sendPasswordResetInstructions(identity: identity);
  }

  @override
  Future<String> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    return remoteDataSource.authenticateUser(
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
  Future<String> verifyPasswordRecoveryCode({
    required String identity,
    required String code,
  }) {
    return remoteDataSource.verifyPasswordRecoveryCodeRemote(
      identity: identity,
      code: code,
    );
  }

  @override
  Future<RecoverySession> verifyRecoverySession({
    required RecoverySession currentSession,
    required String code,
  }) async {
    final result = await remoteDataSource.verifyRecoverySessionRemote(
      identity: currentSession.identity,
      code: code,
    );
    final profile = switch (result.profile.toLowerCase()) {
      'admin' => UserProfile.admin,
      'docente' => UserProfile.docente,
      'aluno' => UserProfile.aluno,
      _ => currentSession.profile,
    };
    return currentSession.copyWith(
      profile: profile,
      identity: result.identity.isNotEmpty ? result.identity : currentSession.identity,
      displayName: result.displayName.isNotEmpty ? result.displayName : currentSession.displayName,
      institutionalEmail: result.email.isNotEmpty ? result.email : currentSession.institutionalEmail,
      departmentOrCourse: result.departmentOrCourse.isNotEmpty ? result.departmentOrCourse : currentSession.departmentOrCourse,
      resetToken: result.resetToken,
    );
  }

  @override
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
    String? resetToken,
  }) async {
    await remoteDataSource.updatePasswordRemote(
      identity: identity,
      newPassword: newPassword,
      resetToken: resetToken ?? '',
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
