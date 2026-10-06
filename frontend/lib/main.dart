// Desenvolvido por Marcelo Zarpelon, Murilo (Murillo Caravita - Tela de Login) e Alex Gabriel Soares Sousa (RA: 24802449 - Verificação de E-mail)

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'features/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'features/forgot_password/presentation/pages/recover_password_page.dart';
import 'features/login/domain/usecases/login_usecase.dart';
import 'features/login/presentation/controllers/login_controller.dart';
import 'features/login/presentation/pages/login_page.dart';
import 'features/reset_password/presentation/pages/reset_password_page.dart';
import 'features/verify_code/presentation/pages/verify_code_page.dart';
import 'shared/auth/data/auth_repository_impl.dart';
import 'shared/auth/external/auth_remote_datasource_impl.dart';

void main() {
  // Inicialização da injeção de dependências (Clean Architecture)
  final remoteDataSource = AuthRemoteDataSourceImpl();
  final repository = AuthRepositoryImpl(remoteDataSource);
  
  final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
  final recoverController = RecoverPasswordController(
    recoverPasswordUseCase: recoverPasswordUseCase,
  );

  final loginUseCase = LoginUseCase(repository);
  final loginController = LoginController(
    loginUseCase: loginUseCase,
  );

  runApp(PortalAvaApp(
    controller: recoverController,
    loginController: loginController,
  ));
}

class PortalAvaApp extends StatelessWidget {
  final RecoverPasswordController controller;
  final LoginController? loginController;
  final String initialRoute;

  const PortalAvaApp({
    super.key,
    required this.controller,
    this.loginController,
    this.initialRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGMRM - Portal Acadêmico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => LoginPage(controller: loginController),
        '/recover-password': (context) => RecoverPasswordPage(controller: controller),
        '/verify-code': (context) => const VerifyCodePage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}
