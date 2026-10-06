// Desenvolvido por Marcelo Zarpelon. RA 25015323

import '../../data/datasources/auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<void> sendPasswordResetInstructions({
    required String identity,
  }) async {
    // Simula comunicação remota (HTTP / Firebase)
    await Future.delayed(const Duration(milliseconds: 1500));

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
    await Future.delayed(const Duration(milliseconds: 1000));

    if (identity.toLowerCase().contains('invalid') || password == 'errada') {
      throw Exception('Credenciais inválidas. Verifique seu identificador e senha.');
    }
  }
}
