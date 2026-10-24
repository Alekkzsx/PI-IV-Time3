// Desenvolvido por Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/router/app_router.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/domain/usecases/recover_password_usecase.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth/login/domain/usecases/login_usecase.dart';
import 'package:pi_iv_time3/features/auth/login/presentation/controllers/login_controller.dart';
import 'package:pi_iv_time3/features/auth/shared/data/auth_repository_impl.dart';
import 'package:pi_iv_time3/features/auth/shared/external/auth_remote_datasource_impl.dart';

void main() {
  test('all authentication steps use the smooth page transition', () {
    final repository = AuthRepositoryImpl(AuthRemoteDataSourceImpl());
    final recoverController = RecoverPasswordController(
      recoverPasswordUseCase: RecoverPasswordUseCase(repository),
    );
    final loginController = LoginController(
      loginUseCase: LoginUseCase(repository),
    );

    for (final routeName in [
      AppRoutes.login,
      AppRoutes.recoverPassword,
      AppRoutes.verifyCode,
      AppRoutes.resetPassword,
    ]) {
      final route = AppRouter.onGenerateRoute(
        settings: RouteSettings(name: routeName),
        recoverController: recoverController,
        authRepository: repository,
        loginController: loginController,
      );

      expect(route, isA<PageRoute<dynamic>>(), reason: routeName);
      expect(route!.settings.name, routeName);
      final pageRoute = route as PageRoute<dynamic>;
      expect(
        pageRoute.transitionDuration,
        const Duration(milliseconds: 420),
        reason: routeName,
      );
      expect(
        pageRoute.reverseTransitionDuration,
        const Duration(milliseconds: 340),
        reason: routeName,
      );
    }

    recoverController.dispose();
    loginController.dispose();
  });
}
