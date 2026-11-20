// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/features/auth/shared/external/auth_remote_datasource_impl.dart';

/// Repositório dublê (Fake) implementando o contrato [AuthRepository]
/// para testes de unidade do [RecoverPasswordController].
class FakeAuthRepository implements AuthRepository {
  /// Define se o método assíncrono deve simular um lançamento de exceção.
  bool shouldThrow = false;
  Object? customError;
  Completer<void>? recoveryCompleter;
  String? lastIdentity;
  String? lastProfile;
  String? responseProfile;

  @override
  Future<void> recoverPassword({
    required String identity,
    String? profile,
  }) async {
    lastIdentity = identity;
    lastProfile = profile;
    await recoveryCompleter?.future;
    if (customError != null) {
      throw customError!;
    }
    if (shouldThrow) {
      throw Exception('Erro de servidor');
    }
  }

  @override
  Future<Map<String, dynamic>> recoverPasswordDetails({
    required String identity,
    String? profile,
  }) async {
    await recoverPassword(identity: identity, profile: profile);
    return {
      'status': 200,
      'maskedEmail': 't***t@example.com',
      if (responseProfile != null) 'profile': responseProfile,
    };
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
  Future<RecoverySession> verifyRecoverySession({
    required RecoverySession currentSession,
    required String code,
  }) async => currentSession.withResetToken('test-reset-token');

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

  test('Exibe erro explícito 404 quando e-mail ou RA não está cadastrado', () async {
    repository.customError = const AuthApiException(
      'E-mail ou identificador nao cadastrado no sistema.',
      statusCode: 404,
    );
    controller.setIdentity('naoexiste@gmail.com');

    expect(await controller.submit(), false);
    expect(
      controller.errorMessage,
      'E-mail ou identificador nao cadastrado no sistema.',
    );
    expect(controller.isSuccess, false);
  });

  test(
    'Rejeita com erro de tipo de usuário inválido quando perfil selecionado diverge da conta',
    () async {
      repository.responseProfile = 'aluno';
      controller.setIdentity('alex@puccampinas.edu.br');

      final result = await controller.submit(profile: 'admin');

      expect(result, isFalse);
      expect(controller.isSuccess, isFalse);
      expect(repository.lastProfile, 'admin');
      expect(
        controller.errorMessage,
        'Tipo de usuário inválido: esta conta pertence ao perfil de Aluno, não ao perfil selecionado (Admin).',
      );
    },
  );
}
