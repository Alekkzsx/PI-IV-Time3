// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'dart:async';
import 'package:flutter/material.dart';
import 'core/backend/backend_process_launcher.dart';
import 'core/network/server_health_monitor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_user_session.dart';
import 'core/widgets/server_unavailable_guard.dart';
import 'features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'features/auth/login/domain/usecases/login_usecase.dart';
import 'features/auth/login/presentation/controllers/login_controller.dart';
import 'features/auth/shared/data/auth_repository_impl.dart';
import 'features/auth/shared/external/auth_remote_datasource_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const autoStartBackend = bool.fromEnvironment(
    'AUTO_START_LOCAL_BACKEND',
    defaultValue: true,
  );
  if (autoStartBackend) {
    // Garante inicialização automática dos serviços locais em execução Desktop
    unawaited(BackendProcessLauncher.ensureBackendRunning());
  }

  // Inicia o monitoramento Fail-Closed (Servidor Java :8080 + Backend :3001)
  ServerHealthMonitor.instance.start();
  final serversOnline = await ServerHealthMonitor.instance.checkNow();

  // Só libera entrada direta em rotas internas se ambos servidores estiverem online
  // e a sessão salva for confirmada por GET /api/auth/me.
  var validRestoredSession = false;
  if (serversOnline && AppUserSession.instance.restoreFromStorage()) {
    final result = await AppUserSession.instance.verifySessionWithServer();
    validRestoredSession = result == SessionRefreshResult.valid;
  }

  const configuredRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: '',
  );
  final initialRoute = configuredRoute.isNotEmpty
      ? configuredRoute
      : (validRestoredSession
            ? AppUserSession.instance.defaultHomeRoute
            : AppRoutes.login);

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
      enableServerGuard: true,
    ),
  );
}

class PortalAvaApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  final RecoverPasswordController controller;
  final LoginController? loginController;
  final String initialRoute;
  final bool enableServerGuard;

  const PortalAvaApp({
    super.key,
    required this.controller,
    this.loginController,
    this.initialRoute = AppRoutes.login,
    this.enableServerGuard = false,
  });

  @override
  Widget build(BuildContext context) {
    AppUserSession.instance.onExpired = () {
      Future.microtask(
        () => navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        ),
      );
    };
    final authRepository =
        loginController?.loginUseCase.repository ??
        controller.recoverPasswordUseCase.repository;
    final effectiveLoginController =
        loginController ??
        LoginController(loginUseCase: LoginUseCase(authRepository));

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AGMRM - Portal Acadêmico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      builder: (context, child) => ServerUnavailableGuard(
        enabled: enableServerGuard,
        child: child ?? const SizedBox.shrink(),
      ),
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
