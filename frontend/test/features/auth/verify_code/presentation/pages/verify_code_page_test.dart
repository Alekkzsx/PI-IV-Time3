// Desenvolvido por Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/theme/app_theme.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/features/auth/verify_code/presentation/pages/verify_code_page.dart';

class _FakeAuthRepository implements AuthRepository {
  String? verifiedCode;
  String recoveryToken = '';

  @override
  Future<void> recoverPassword({
    required String identity,
    String? profile,
  }) async {}

  @override
  Future<Map<String, dynamic>> recoverPasswordDetails({
    required String identity,
    String? profile,
  }) async => {};

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
  Future<RecoverySession> verifyRecoverySession({
    required RecoverySession currentSession,
    required String code,
  }) async {
    verifiedCode = code;
    return currentSession.withResetToken(recoveryToken);
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

  testWidgets(
    'Campos OTP não herdam borda duplicada do InputDecorationTheme global',
    (tester) async {
      final session = RecoverySession.fromProfileAndIdentity(
        profile: UserProfile.aluno,
        identity: 'aluno.test',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VerifyCodePage(
            repository: _FakeAuthRepository(),
            session: session,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(6));
      for (final field in fields) {
        final dec = field.decoration!;
        expect(dec.isCollapsed, isTrue);
        expect(dec.border, InputBorder.none);
        expect(dec.enabledBorder, InputBorder.none);
        expect(dec.focusedBorder, InputBorder.none);
        expect(dec.disabledBorder, InputBorder.none);
        expect(dec.errorBorder, InputBorder.none);
        expect(dec.focusedErrorBorder, InputBorder.none);
        expect(dec.filled, isFalse);
      }

      // Clicar no 3º bloco move o foco sem erro
      await tester.tap(find.byType(TextField).at(2));
      await tester.pump();
      expect(fields[2].focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets(
    'Sinaliza progresso, exibe erro inline em código inválido, permite editar dígito e limpar',
    (tester) async {
      final repository = _FakeAuthRepository();
      final session = RecoverySession.fromProfileAndIdentity(
        profile: UserProfile.aluno,
        identity: 'aluno.test',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VerifyCodePage(repository: repository, session: session),
        ),
      );
      await tester.pumpAndSettle();

      // Estado inicial
      expect(find.text('CÓDIGO DE 6 DÍGITOS'), findsOneWidget);
      expect(find.text('0 de 6 dígitos'), findsOneWidget);
      expect(find.text('Limpar'), findsNothing);

      // Preenchimento parcial
      final codeFields = find.byType(TextField);
      await tester.enterText(codeFields.first, '123');
      await tester.pump();
      expect(find.text('3 de 6 dígitos'), findsOneWidget);
      expect(find.text('Limpar'), findsOneWidget);

      // Preenchimento completo
      await tester.enterText(codeFields.first, '123456');
      await tester.pump();
      expect(find.text('Pronto para validar'), findsOneWidget);

      // Edição pontual no 3º bloco (índice 2) sem apagar os demais dígitos
      await tester.enterText(codeFields.at(2), '39');
      await tester.pump();
      final afterEdit = tester
          .widgetList<TextField>(codeFields)
          .map((field) => field.controller!.text)
          .toList();
      expect(afterEdit, ['1', '2', '9', '4', '5', '6']);

      // Submissão com código inválido exibe banner inline de erro
      await tester.tap(find.text('Confirmar Código'));
      await tester.pumpAndSettle();
      expect(find.text('Verifique o código'), findsOneWidget);
      expect(
        find.text(
          'Código inválido ou expirado. Confira os 6 dígitos e tente novamente.',
        ),
        findsOneWidget,
      );

      // Botão Limpar restaura os 6 blocos e remove o erro inline
      await tester.tap(find.text('Limpar'));
      await tester.pump();
      expect(find.text('0 de 6 dígitos'), findsOneWidget);
      expect(find.text('Verifique o código'), findsNothing);
    },
  );
}
