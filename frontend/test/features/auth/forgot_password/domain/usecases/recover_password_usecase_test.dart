// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';

/// Dublê de testes (Mock / Spy) para o contrato de [AuthRepository].
///
/// Utilizado para validar o isolamento e a integridade de chamadas
/// disparadas pelo caso de uso [RecoverPasswordUseCase].
class MockAuthRepository implements AuthRepository {
  /// Registra a última credencial acadêmica repassada ao repositório.
  String? lastIdentity;

  /// Controla a simulação de falha ou lançamento de erro de autenticação.
  bool shouldFail = false;

  @override
  Future<void> recoverPassword({required String identity}) async {
    if (shouldFail) {
      throw Exception('Identificador não encontrado.');
    }
    lastIdentity = identity;
  }

  @override
  Future<String> login({
    required String identity,
    required String password,
    required String profile,
  }) async => 'test-access-token';

  @override
  Future<bool> verifyOtpToken({
    required String identity,
    required String code,
  }) async => true;

  @override
  Future<String> verifyPasswordRecoveryCode({
    required String identity,
    required String code,
  }) async => 'test-reset-token';

  @override
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
    String? resetToken,
  }) async {}

  @override
  Future<bool> isTwoFactorRequired({
    required String identity,
    required String profile,
  }) async => false;
}

/// Suíte de testes unitários para o caso de uso [RecoverPasswordUseCase].
void main() {
  late MockAuthRepository mockRepository;
  late RecoverPasswordUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RecoverPasswordUseCase(mockRepository);
  });

  test('Deve chamar o repositório com a identidade correta', () async {
    await useCase(identity: '2024.1.00092');

    expect(mockRepository.lastIdentity, '2024.1.00092');
  });
}
