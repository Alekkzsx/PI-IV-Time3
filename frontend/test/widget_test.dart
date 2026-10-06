// Desenvolvido por Marcelo Zarpelon e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/shared/auth/data/auth_repository_impl.dart';
import 'package:pi_iv_time3/shared/auth/external/auth_remote_datasource_impl.dart';
import 'package:pi_iv_time3/main.dart';

void main() {
  testWidgets('Renderiza a tela de Login (Acesse seu AVA) por padrão', (WidgetTester tester) async {
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
}
