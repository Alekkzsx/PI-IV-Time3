import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/reset_password/presentation/pages/reset_password_page.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/models/recovery_session.dart';

class _FakeAuthRepo implements AuthRepository {
  @override
  Future<void> recoverPassword({required String identity}) async {}

  @override
  Future<Map<String, dynamic>> recoverPasswordDetails({required String identity}) async => {};

  @override
  Future<String> login({required String identity, required String password, required String profile}) async => '';

  @override
  Future<bool> verifyOtpToken({required String identity, required String code}) async => true;

  @override
  Future<String> verifyPasswordRecoveryCode({required String identity, required String code}) async => '';

  @override
  Future<RecoverySession> verifyRecoverySession({required RecoverySession currentSession, required String code}) async => currentSession;

  @override
  Future<void> resetPassword({required String identity, required String newPassword, String? resetToken}) async {}

  @override
  Future<bool> isTwoFactorRequired({required String identity, required String profile}) async => false;
}

void main() {
  testWidgets('ResetPasswordPage exibe saudacao personalizada e card com dados reais do MongoDB', (tester) async {
    final realSession = RecoverySession(
      profile: UserProfile.aluno,
      identity: '24802449',
      displayName: 'Alex Gabriel Soares Sousa',
      institutionalEmail: 'alex.soares.gabriel111@gmail.com',
      departmentOrCourse: 'Engenharia de Software',
      roleBadge: 'Aluno',
      resetToken: 'jwt-recovery-token-123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordPage(
          repository: _FakeAuthRepo(),
          session: realSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifica saudacao com primeiro nome real ("Alex")
    expect(find.text('Olá, Alex 👋'), findsOneWidget);

    // 2. Verifica dados reais exibidos no AcademicIdentityCard
    expect(find.text('Alex Gabriel Soares Sousa'), findsOneWidget);
    expect(find.text('• R.A. 24802449'), findsOneWidget);
    expect(find.text('Engenharia de Software'), findsOneWidget);
    expect(find.text('alex.soares.gabriel111@gmail.com'), findsOneWidget);

    // 3. Garante que nao existem dados mockados / estaticos de fallback
    expect(find.text('Olá, Usuário 👋'), findsNothing);
    expect(find.text('e-mail cadastrado'), findsNothing);
  });
}
