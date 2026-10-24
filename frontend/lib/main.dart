// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'features/auth/login/domain/usecases/login_usecase.dart';
import 'features/auth/login/presentation/controllers/login_controller.dart';
import 'features/auth/shared/data/auth_repository_impl.dart';
import 'features/auth/shared/external/auth_remote_datasource_impl.dart';

/// Ponto de entrada da aplicação Flutter.
///
/// Inicializa e injeta as dependências de Clean Architecture (DataSources, Repositories,
/// UseCases e Controllers) e inicia a execução do [PortalAvaApp].
void main() {
  const initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: AppRoutes.login,
  );

  // Inicialização da injeção de dependências (Clean Architecture)
  final remoteDataSource = AuthRemoteDataSourceImpl();
  final repository = AuthRepositoryImpl(remoteDataSource);

  final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
  final recoverController = RecoverPasswordController(
    recoverPasswordUseCase: recoverPasswordUseCase,
  );

  final loginUseCase = LoginUseCase(repository);
  final loginController = LoginController(loginUseCase: loginUseCase);

  runApp(
    PortalAvaApp(
      controller: recoverController,
      loginController: loginController,
      initialRoute: initialRoute,
    ),
  );
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
    this.initialRoute = AppRoutes.login,
  });

  @override
  Widget build(BuildContext context) {
    final authRepository =
        loginController?.loginUseCase.repository ??
        AuthRepositoryImpl(AuthRemoteDataSourceImpl());
    final effectiveLoginController =
        loginController ??
        LoginController(loginUseCase: LoginUseCase(authRepository));

    return MaterialApp(
      title: 'AGMRM - Portal Acadêmico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: const {},
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings: settings,
        recoverController: controller,
        authRepository: authRepository,
        loginController: effectiveLoginController,
      ),
      onGenerateInitialRoutes: (routeName) {
        final route = AppRouter.onGenerateRoute(
          settings: RouteSettings(name: routeName),
          recoverController: controller,
          authRepository: authRepository,
          loginController: effectiveLoginController,
        );
        if (route != null) return [route];

        final fallback = AppRouter.onGenerateRoute(
          settings: const RouteSettings(name: AppRoutes.login),
          recoverController: controller,
          authRepository: authRepository,
          loginController: effectiveLoginController,
        );
        return [fallback!];
      },
    );
  }
}
