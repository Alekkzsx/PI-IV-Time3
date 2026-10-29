// Desenvolvido por Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/models/recovery_session.dart';
import 'package:pi_iv_time3/features/auth/verify_code/presentation/pages/verify_code_page.dart';

class _FakeAuthRepository implements AuthRepository {
  String? verifiedCode;
  String recoveryToken = '';

  @override
  Future<void> recoverPassword({required String identity}) async {}

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
  }) async {
    verifiedCode = code;
    return false;
  }

  @override
  Future<String> verifyPasswordRecoveryCode({
    required String identity,
    required String code,
  }) async {
    verifiedCode = code;
    return recoveryToken;
  }

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
  testWidgets('OTP e botão cabem em viewport compacto', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final session = RecoverySession.fromProfileAndIdentity(
      profile: UserProfile.aluno,
      identity: '2024.1.00092',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VerifyCodePage(
          repository: _FakeAuthRepository(),
          session: session,
        ),
      ),
    );

    final renderException = tester.takeException();
    expect(renderException, isNull);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Confirmar Código'), findsOneWidget);
  });

  testWidgets('Colar código parcial limpa dígitos antigos dos outros campos', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final session = RecoverySession.fromProfileAndIdentity(
      profile: UserProfile.aluno,
      identity: '2024.1.00092',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VerifyCodePage(repository: repository, session: session),
      ),
    );

    final codeFields = find.byType(TextField);
    await tester.enterText(codeFields.first, '123456');
    await tester.pump();

    await tester.enterText(codeFields.first, '12');
    await tester.pump();

    final values = tester
        .widgetList<TextField>(codeFields)
        .map((field) => field.controller!.text)
        .toList();
    expect(values, ['1', '2', '', '', '', '']);

    await tester.enterText(codeFields.first, '654321');
    await tester.pump();
    await tester.tap(find.text('Confirmar Código'));
    await tester.pumpAndSettle();

    expect(repository.verifiedCode, '654321');
  });

  testWidgets('grant emitido pelo backend segue para redefinição', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..recoveryToken = 'backend-reset-token';
    final session = RecoverySession.fromProfileAndIdentity(
      profile: UserProfile.aluno,
      identity: '2024.1.00092',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VerifyCodePage(repository: repository, session: session),
        onGenerateRoute: (settings) {
          if (settings.name != '/reset-password') return null;
          final recoverySession = settings.arguments as RecoverySession;
          return MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: Text(recoverySession.resetToken ?? 'missing-reset-token'),
            ),
          );
        },
      ),
    );

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.tap(find.text('Confirmar Código'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('backend-reset-token'), findsOneWidget);
  });
}
