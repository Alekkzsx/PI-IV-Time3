// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/login/domain/usecases/login_usecase.dart';
import 'package:pi_iv_time3/features/auth/login/presentation/controllers/login_controller.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';

/// Dublê de teste (Fake/Stub) para [AuthRepository].
///
/// Permite simular respostas bem-sucedidas ou falhas com exceções na camada de repositório.
class FakeAuthRepository implements AuthRepository {
  /// Flag de controle para simular erro no servidor durante a chamada de login.
  bool shouldThrow = false;
  Completer<void>? loginCompleter;
  int loginCalls = 0;

  @override
  Future<void> recoverPassword({required String identity}) async {}

  @override
  Future<void> login({
    required String identity,
    required String password,
    required String profile,
  }) async {
    loginCalls++;
    await loginCompleter?.future;
    if (shouldThrow) {
      throw Exception('Credenciais inválidas no servidor.');
    }
  }

  @override
  Future<bool> verifyOtpToken({
    required String identity,
    required String code,
  }) async => true;

  @override
  Future<void> resetPassword({
    required String identity,
    required String newPassword,
  }) async {}

  @override
  Future<bool> isTwoFactorRequired({
    required String identity,
    required String profile,
  }) async => false;
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
    // Assert
    expect(controller.isLoading, false);
    expect(controller.errorMessage, null);
    expect(controller.isSuccess, false);
  });

  test('Deve realizar login com sucesso para credenciais válidas', () async {
    // Act
    final result = await controller.login(
      identity: 'ADM-00123',
      password: 'password123',
      profile: 'admin',
    );

    // Assert
    expect(result, true);
    expect(controller.isSuccess, true);
    expect(controller.isLoading, false);
    expect(controller.errorMessage, null);
  });

  test('Deve capturar e expor erro quando usecase falhar', () async {
    // Act
    final result = await controller.login(
      identity: '   ',
      password: '123',
      profile: 'admin',
    );

    // Assert
    expect(result, false);
    expect(controller.isSuccess, false);
    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNotNull);
  });

  test(
    'Deve capturar e expor erro quando repositório lançar exceção',
    () async {
      // Arrange
      repository.shouldThrow = true;

      // Act
      final result = await controller.login(
        identity: 'ADM-00123',
        password: 'password123',
        profile: 'admin',
      );

      // Assert
      expect(result, false);
      expect(controller.isSuccess, false);
      expect(
        controller.errorMessage,
        'Não foi possível entrar. Confira seus dados e tente novamente.',
      );
    },
  );

  test(
    'Não inicia uma segunda autenticação enquanto a primeira está pendente',
    () async {
      repository.loginCompleter = Completer<void>();

      final firstAttempt = controller.login(
        identity: 'ADM-00123',
        password: 'password123',
        profile: 'admin',
      );
      final secondAttempt = await controller.login(
        identity: 'ADM-00123',
        password: 'password123',
        profile: 'admin',
      );

      expect(secondAttempt, false);
      expect(repository.loginCalls, 1);
      expect(controller.isLoading, true);

      repository.loginCompleter!.complete();
      expect(await firstAttempt, true);
      expect(controller.isLoading, false);
    },
  );

  test('clearError deve resetar mensagem de erro', () async {
    // Arrange
    await controller.login(identity: '', password: '', profile: 'admin');
    expect(controller.errorMessage, isNotNull);

    // Act
    controller.clearError();

    // Assert
    expect(controller.errorMessage, null);
  });
}
