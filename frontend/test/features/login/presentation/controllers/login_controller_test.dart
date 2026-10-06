// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/login/domain/usecases/login_usecase.dart';
import 'package:pi_iv_time3/features/login/presentation/controllers/login_controller.dart';
import 'package:pi_iv_time3/shared/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldThrow = false;

  @override
  Future<void> recoverPassword({required String identity}) async {}

  @override
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    if (shouldThrow) {
      throw Exception('Credenciais inválidas no servidor.');
    }
  }
}

void main() {
  late FakeAuthRepository repository;
  late LoginUseCase useCase;
  late LoginController controller;

  setUp(() {
    repository = FakeAuthRepository();
    useCase = LoginUseCase(repository);
    controller = LoginController(loginUseCase: useCase);
  });

  test('Estado inicial deve ser sem erros e sem loading', () {
    expect(controller.isLoading, false);
    expect(controller.errorMessage, null);
    expect(controller.isSuccess, false);
  });

  test('Deve realizar login com sucesso para credenciais válidas', () async {
    final result = await controller.login(
      identity: 'ADM-00123',
      password: 'password123',
      profile: 'admin',
    );

    expect(result, true);
    expect(controller.isSuccess, true);
    expect(controller.isLoading, false);
    expect(controller.errorMessage, null);
  });

  test('Deve capturar e expor erro quando usecase falhar', () async {
    final result = await controller.login(
      identity: '   ',
      password: '123',
      profile: 'admin',
    );

    expect(result, false);
    expect(controller.isSuccess, false);
    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNotNull);
  });

  test('Deve capturar e expor erro quando repositório lançar exceção', () async {
    repository.shouldThrow = true;

    final result = await controller.login(
      identity: 'ADM-00123',
      password: 'password123',
      profile: 'admin',
    );

    expect(result, false);
    expect(controller.isSuccess, false);
    expect(controller.errorMessage, contains('Credenciais inválidas no servidor.'));
  });

  test('clearError deve resetar mensagem de erro', () async {
    await controller.login(
      identity: '',
      password: '',
      profile: 'admin',
    );
    expect(controller.errorMessage, isNotNull);

    controller.clearError();
    expect(controller.errorMessage, null);
  });
}

