// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/app/domain/repositories/auth_repository.dart';
import 'package:pi_iv_time3/app/domain/usecases/recover_password_usecase.dart';

class MockAuthRepository implements AuthRepository {
  String? lastIdentity;
  bool shouldFail = false;

  @override
  Future<void> recoverPassword({
    required String identity,
  }) async {
    if (shouldFail) {
      throw Exception('Identificador não encontrado.');
    }
    lastIdentity = identity;
  }

  @override
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  }) async {}
}

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
