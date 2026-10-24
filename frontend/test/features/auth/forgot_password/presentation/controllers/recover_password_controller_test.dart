// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';

/// Repositório dublê (Fake) implementando o contrato [AuthRepository]
/// para testes de unidade do [RecoverPasswordController].
class FakeAuthRepository implements AuthRepository {
  /// Define se o método assíncrono deve simular um lançamento de exceção.
  bool shouldThrow = false;
  Completer<void>? recoveryCompleter;
  String? lastIdentity;

  @override
  Future<void> recoverPassword({required String identity}) async {
    lastIdentity = identity;
    await recoveryCompleter?.future;
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

  test(
    'Editar a identidade durante o envio invalida a resposta antiga',
    () async {
      repository.recoveryCompleter = Completer<void>();
      controller.setIdentity(' 2024.1.00092 ');

      final pendingSubmit = controller.submit();
      expect(controller.isLoading, true);
      expect(repository.lastIdentity, '2024.1.00092');

      controller.setIdentity('DOC-40892');
      expect(controller.isLoading, false);
      repository.recoveryCompleter!.complete();

      expect(await pendingSubmit, false);
      expect(controller.identity, 'DOC-40892');
      expect(controller.isSuccess, false);
      expect(controller.errorMessage, null);
    },
  );

  test('Alterar a identidade remove o feedback de sucesso anterior', () async {
    controller.setIdentity('2024.1.00092');
    expect(await controller.submit(), true);

    controller.setIdentity('DOC-40892');

    expect(controller.isSuccess, false);
    expect(controller.errorMessage, null);
  });

  test('Não expõe a mensagem bruta retornada pela recuperação', () async {
    repository.shouldThrow = true;
    controller.setIdentity('2024.1.00092');

    expect(await controller.submit(), false);
    expect(
      controller.errorMessage,
      'Não foi possível solicitar a recuperação agora. Tente novamente.',
    );
  });
}
