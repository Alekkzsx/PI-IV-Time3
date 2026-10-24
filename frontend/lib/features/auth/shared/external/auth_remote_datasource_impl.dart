// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

import '../data/auth_remote_datasource.dart';

/// Implementação simulada (mock) de [AuthRemoteDataSource] com delays de latência e validações de teste.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<void> sendPasswordResetInstructions({required String identity}) async {
    // Simula comunicação remota (HTTP / Firebase)
    await Future.delayed(const Duration(milliseconds: 900));

    if (identity.toLowerCase().contains('invalid')) {
      throw Exception('Identificador não encontrado nos registros do portal.');
    }
  }

  @override
  Future<void> authenticateUser({
    required String identity,
    required String password,
    required String profile,
  }) async {
    // Simula comunicação remota (HTTP / Backend)
    await Future.delayed(const Duration(milliseconds: 700));

    if (identity.toLowerCase().contains('invalid') || password == 'errada') {
      throw Exception(
        'Credenciais inválidas. Verifique seu identificador e senha.',
      );
    }
  }

  @override
  Future<bool> verifyOtpTokenRemote({
    required String identity,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Código de teste institucional aceito
    return code == '123456';
  }

  @override
  Future<void> updatePasswordRemote({
    required String identity,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (newPassword.length < 6) {
      throw Exception('A nova senha deve possuir no mínimo 6 caracteres.');
    }
  }

  @override
  Future<bool> checkTwoFactorStatusRemote({
    required String identity,
    required String profile,
  }) async {
    // Preparação arquitetural de prontidão para 2FA
    await Future.delayed(const Duration(milliseconds: 200));
    return false; // Desabilitado por padrão conforme diretiva do usuário
  }
}
