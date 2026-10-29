// Desenvolvido por Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/pages/recover_password_page.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  int recoveryRequests = 0;

  @override
  Future<void> recoverPassword({required String identity}) async {
    recoveryRequests++;
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

void main() {
  testWidgets('reentry does not submit a stale, invisible identity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _FakeAuthRepository();
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: RecoverPasswordUseCase(repository),
    )..setIdentity('2024.1.00892');

    await tester.pumpWidget(
      MaterialApp(home: RecoverPasswordPage(controller: controller)),
    );

    expect(controller.identity, isEmpty);

    final submitButton = find.text('Enviar Instruções de Recuperação');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(repository.recoveryRequests, 0);
    expect(controller.errorMessage, isNotNull);
    controller.dispose();
  });
}
