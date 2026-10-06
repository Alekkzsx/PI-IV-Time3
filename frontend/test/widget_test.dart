// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/app/data/repositories/auth_repository_impl.dart';
import 'package:pi_iv_time3/app/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/app/external/datasources/auth_remote_datasource_impl.dart';
import 'package:pi_iv_time3/app/presentation/controllers/recover_password_controller.dart';
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
}
