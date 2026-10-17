// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth_view/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'features/auth_view/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'features/auth_view/forgot_password/presentation/pages/recover_password_page.dart';
import 'features/auth_view/login/domain/usecases/login_usecase.dart';
import 'features/auth_view/login/presentation/controllers/login_controller.dart';
import 'features/auth_view/login/presentation/pages/login_page.dart';
import 'features/auth_view/reset_password/presentation/pages/reset_password_page.dart';
import 'features/auth_view/verify_code/presentation/pages/verify_code_page.dart';
import 'features/student_view/student_messages/presentation/pages/student_messages_page.dart';
import 'features/student_view/student_secretariat/presentation/pages/student_secretariat_page.dart';
import 'features/video_call/presentation/pages/video_call_lobby_page.dart';
import 'shared/auth/data/auth_repository_impl.dart';
import 'shared/auth/external/auth_remote_datasource_impl.dart';

/// Ponto de entrada da aplicação Flutter.
///
/// Inicializa e injeta as dependências de Clean Architecture (DataSources, Repositories,
/// UseCases e Controllers) e inicia a execução do [PortalAvaApp].
void main() {
  const initialRoute = String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/');

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
    initialRoute: initialRoute,
  ));
}

/// Widget raiz da aplicação Portal Acadêmico AVA.
class PortalAvaApp extends StatelessWidget {
  /// Controlador de recuperação de senha compartilhado com a rota correspondente.
  final RecoverPasswordController controller;

  /// Controlador de autenticação compartilhado com a página de login.
  final LoginController? loginController;

  /// Rota inicial da aplicação (padrão: '/').
  final String initialRoute;

  /// Cria uma instância da aplicação configurando seus controladores e rota inicial.
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
        '/student/messages': (context) => const StudentMessagesPage(),
        '/student/secretaria': (context) => const StudentSecretariatPage(),
        '/video-call': (context) => const VideoCallLobbyPage(),
      },
    );
  }
}

