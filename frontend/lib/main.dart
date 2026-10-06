// Desenvolvido por Marcelo Zarpelon e Murilo (Murillo Caravita - Tela de Login)

import 'package:flutter/material.dart';
import 'app/data/repositories/auth_repository_impl.dart';
import 'app/domain/usecases/recover_password_usecase.dart';
import 'app/external/datasources/auth_remote_datasource_impl.dart';
import 'app/presentation/controllers/recover_password_controller.dart';
import 'app/presentation/pages/login_page.dart';
import 'app/presentation/pages/recover_password_page.dart';
import 'app/presentation/pages/reset_password_page.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Inicialização da injeção de dependências (Clean Architecture)
  final remoteDataSource = AuthRemoteDataSourceImpl();
  final repository = AuthRepositoryImpl(remoteDataSource);
  final recoverPasswordUseCase = RecoverPasswordUseCase(repository);
  final controller = RecoverPasswordController(
    recoverPasswordUseCase: recoverPasswordUseCase,
  );

  runApp(PortalAvaApp(controller: controller));
}

class PortalAvaApp extends StatelessWidget {
  final RecoverPasswordController controller;
  final String initialRoute;

  const PortalAvaApp({
    super.key,
    required this.controller,
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
        '/': (context) => const LoginPage(),
        '/recover-password': (context) => RecoverPasswordPage(controller: controller),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}
