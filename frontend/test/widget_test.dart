// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/forgot_password/presentation/widgets/recovery_input_field.dart';
import 'package:pi_iv_time3/features/reset_password/presentation/widgets/password_reset_field.dart';
import 'package:pi_iv_time3/features/verify_code/presentation/pages/verify_code_page.dart';
import 'package:pi_iv_time3/main.dart';
import 'package:pi_iv_time3/shared/auth/data/auth_repository_impl.dart';
import 'package:pi_iv_time3/shared/auth/external/auth_remote_datasource_impl.dart';

/// Configura resolução de tela desktop (largura >= 900px) padrão do Portal AVA.
void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

/// Suíte de testes de widgets e integração de fluxo visual do Portal AVA.
void main() {
  testWidgets('Renderiza a tela de Login (Acesse seu AVA) por padrão', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(controller: controller));

    expect(find.text('Acesse seu AVA'), findsOneWidget);
    expect(find.text('Identificação Administrativa ou E-mail Corporativo'), findsOneWidget);
    expect(find.text('ex: ADM-00123'), findsOneWidget);
    expect(find.text('Entrar no AVA'), findsOneWidget);
  });

  testWidgets('Renderiza a tela de Esqueceu sua senha? via rota de recuperação', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/recover-password',
    ));

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.text('Enviar Instruções de Recuperação'), findsOneWidget);
  });

  testWidgets('Clica em Voltar ao Login e retorna para a tela de Login', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/recover-password',
    ));

    expect(find.text('Voltar ao Login'), findsOneWidget);
    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('Renderiza a tela de Verifique seu e-mail via rota /verify-code', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/verify-code',
    ));

    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(find.text('Confirmar Código'), findsOneWidget);
    expect(find.text('Reenviar e-mail'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('Preenche código 123456 e confirma com sucesso', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/verify-code',
    ));

    final textFields = find.byType(TextField);
    final digits = ['1', '2', '3', '4', '5', '6'];

    for (int i = 0; i < 6; i++) {
      await tester.enterText(textFields.at(i), digits[i]);
    }
    await tester.pump();

    // Clica no botão Confirmar Código
    await tester.tap(find.text('Confirmar Código'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Deve navegar para ResetPasswordPage
    expect(find.text('Olá, Gabriel Martins 👋'), findsOneWidget);
  });

  testWidgets('Navega de LoginPage para RecoverPasswordPage pelo link Esqueceu a senha?', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    expect(find.text('Acesse seu AVA'), findsOneWidget);
    final forgotFinder = find.text('Esqueceu a senha?');
    expect(forgotFinder, findsOneWidget);

    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.text('Enviar Instruções de Recuperação'), findsOneWidget);
  });

  testWidgets('Navega de RecoverPasswordPage de volta para LoginPage via pop após navegar do login', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    final forgotFinder = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('RecoverPasswordPage submete com sucesso e navega para VerifyCodePage com o identificador', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    final forgotFinder = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();

    final inputFinder = find.descendant(
      of: find.byType(RecoveryInputField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputFinder, '2024.1.00892');
    await tester.pump();

    final submitBtn = find.text('Enviar Instruções de Recuperação');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('2024.1.00892'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('VerifyCodePage volta para LoginPage via pop quando veio do fluxo de recuperação', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    final forgotFinder = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();

    final inputFinder = find.descendant(
      of: find.byType(RecoveryInputField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputFinder, '2024.1.00892');
    await tester.pump();

    final submitBtn = find.text('Enviar Instruções de Recuperação');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Verifique seu e-mail'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('VerifyCodePage volta para LoginPage via fallback pushReplacementNamed quando aberta diretamente', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/verify-code',
    ));

    expect(find.text('Verifique seu e-mail'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('ResetPasswordPage volta para LoginPage pelo botão Voltar ao Login na barra superior', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/reset-password',
    ));

    expect(find.text('Olá, Gabriel Martins 👋'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('ResetPasswordPage salva nova senha e retorna para LoginPage', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/reset-password',
    ));

    expect(find.text('Olá, Gabriel Martins 👋'), findsOneWidget);

    final newPassWrapper = find.widgetWithText(PasswordResetField, 'NOVA SENHA');
    final confirmPassWrapper = find.widgetWithText(PasswordResetField, 'CONFIRMAR NOVA SENHA');
    final newPasswordField = find.descendant(of: newPassWrapper, matching: find.byType(TextField));
    final confirmPasswordField = find.descendant(of: confirmPassWrapper, matching: find.byType(TextField));

    await tester.enterText(newPasswordField, 'novaSenha123');
    await tester.enterText(confirmPasswordField, 'novaSenha123');
    await tester.pump();

    final saveButton = find.text('Salvar Nova Senha e Voltar para Login');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('Ciclo completo E2E: Login -> Recuperar -> Código OTP -> Redefinir Senha -> Retorno limpo ao Login', (WidgetTester tester) async {
    _setDesktopViewport(tester);
    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    // 1. Tela de Login inicial
    expect(find.text('Acesse seu AVA'), findsOneWidget);

    // 2. Clica em Esqueceu a senha? -> navega para RecoverPasswordPage
    final forgotFinder = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();
    expect(find.text('Esqueceu sua senha?'), findsOneWidget);

    // 3. Preenche identificador e submete com sucesso -> navega para VerifyCodePage
    final recoverInput = find.descendant(
      of: find.byType(RecoveryInputField),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(recoverInput, '2024.1.00892');
    await tester.pump();
    final submitBtn = find.text('Enviar Instruções de Recuperação');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Verifique seu e-mail'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('2024.1.00892'),
      ),
      findsOneWidget,
    );

    // 4. Preenche código OTP 123456 e confirma -> avança para ResetPasswordPage
    final otpFields = find.descendant(
      of: find.byType(VerifyCodePage),
      matching: find.byType(TextField),
    );
    final digits = ['1', '2', '3', '4', '5', '6'];
    for (int i = 0; i < 6; i++) {
      await tester.enterText(otpFields.at(i), digits[i]);
    }
    await tester.pump();
    await tester.tap(find.text('Confirmar Código'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Olá, Gabriel Martins 👋'), findsOneWidget);

    // 5. Preenche nova senha e confirmação -> salva e retorna limpamente para a LoginPage
    final newPassWrapper = find.widgetWithText(PasswordResetField, 'NOVA SENHA');
    final confirmPassWrapper = find.widgetWithText(PasswordResetField, 'CONFIRMAR NOVA SENHA');
    final newPasswordField = find.descendant(of: newPassWrapper, matching: find.byType(TextField));
    final confirmPasswordField = find.descendant(of: confirmPassWrapper, matching: find.byType(TextField));

    await tester.enterText(newPasswordField, 'minhaNovaSenha@2024');
    await tester.enterText(confirmPasswordField, 'minhaNovaSenha@2024');
    await tester.pump();
    final saveButton = find.text('Salvar Nova Senha e Voltar para Login');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 6. Deve ter retornado com sucesso para a LoginPage
    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });

  testWidgets('Navega em layout compacto/mobile: LoginPage -> RecoverPasswordPage -> LoginPage via pop', (WidgetTester tester) async {
    // Configura resolução compacta (< 900px) para exercitar o layout móvel do Portal AVA
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final remoteDataSource = AuthRemoteDataSourceImpl();
    final repository = AuthRepositoryImpl(remoteDataSource);
    final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
    final controller = RecoverPasswordController(
      recoverPasswordUseCase: recoverPasswordUseCase,
    );

    await tester.pumpWidget(PortalAvaApp(
      controller: controller,
      initialRoute: '/',
    ));

    expect(find.text('Acesse seu AVA'), findsOneWidget);

    final forgotFinder = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgotFinder);
    await tester.tap(forgotFinder);
    await tester.pumpAndSettle();

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Login'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse seu AVA'), findsOneWidget);
  });
}
