// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/app/domain/repositories/auth_repository.dart';
import 'package:pi_iv_time3/app/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/app/presentation/controllers/recover_password_controller.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldThrow = false;

  @override
  Future<void> recoverPassword({
    required String identity,
  }) async {
    if (shouldThrow) {
      throw Exception('Erro de servidor');
    }
  }
}

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
