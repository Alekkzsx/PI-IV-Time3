// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/shared/auth/domain/auth_repository.dart';

/// Repositório dublê (Fake) implementando o contrato [AuthRepository]
/// para testes de unidade do [RecoverPasswordController].
class FakeAuthRepository implements AuthRepository {
  /// Define se o método assíncrono deve simular um lançamento de exceção.
  bool shouldThrow = false;

  @override
  Future<void> recoverPassword({
    required String identity,
  }) async {
    if (shouldThrow) {
      throw Exception('Erro de servidor');
    }
  }

  @override
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  }) async {}
}

/// Suíte de testes unitários para o [RecoverPasswordController].
void main() {

  late FakeAuthRepository repository;
  late RecoverPasswordUseCase useCase;
  late RecoverPasswordController controller;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = RecoverPasswordUseCase(repository);
    controller = RecoverPasswordController(recoverPasswordUseCase: useCase);
  });

  test('Estado inicial deve ser sem erros', () {
    expect(controller.identity, '');
    expect(controller.isLoading, false);
    expect(controller.errorMessage, null);
    expect(controller.isSuccess, false);
  });

  test('Deve retornar erro de validação para campo vazio', () async {
    final result = await controller.submit();
    expect(result, false);
    expect(controller.errorMessage, isNotNull);
  });

  test('Deve submeter com sucesso para entrada válida', () async {
    controller.setIdentity('2024.1.00092');
    final result = await controller.submit();

    expect(result, true);
    expect(controller.isSuccess, true);
    expect(controller.errorMessage, null);
  });
}
