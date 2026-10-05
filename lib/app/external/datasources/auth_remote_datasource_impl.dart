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
}
