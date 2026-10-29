// Desenvolvido por Murillo Caravita - RA: 25014012
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/router/app_router.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
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

  testWidgets('named routes enforce the active user role', (tester) async {
    final session = AppUserSession.instance;
    session.signOut();
    addTearDown(session.signOut);

    await tester.pumpWidget(
      MaterialApp(
        routes: AppRouter.buildRoutes(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const Key('open_teacher_portal'),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.docenteHome),
                  child: const Text('Área docente'),
                ),
                TextButton(
                  key: const Key('open_student_portal'),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.studentHome),
                  child: const Text('Área discente'),
                ),
                TextButton(
                  key: const Key('open_video_call_with_forged_role'),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.videoCall,
                    arguments: const {
                      'roomCode': 'APS-II',
                      'role': 'admin',
                      'identity': 'ADM-00123',
                    },
                  ),
                  child: const Text('Videochamada'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    session.signIn(identity: '2024.1.00901', profile: 'aluno');
    await tester.tap(find.byKey(const Key('open_student_portal')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não há dados acadêmicos de demonstração vinculados a esta conta.',
      ),
      findsOneWidget,
    );
    expect(find.text('Acesso restrito'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('Voltar ao login'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    session.signIn(identity: '2024.1.00892', profile: 'aluno');
    await tester.tap(find.byKey(const Key('open_teacher_portal')));
    await tester.pumpAndSettle();
    expect(
      find.text('Esta área é exclusiva do perfil docente.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_video_call_with_forged_role')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('lobby_name_field')),
    );
    expect(nameField.controller?.text, '2024.1.00892');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('lobby_name_field')),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    session.signOut();
    await tester.tap(find.byKey(const Key('open_video_call_with_forged_role')));
    await tester.pumpAndSettle();
    expect(
      find.text('Faça login para acessar uma videochamada.'),
      findsOneWidget,
    );
  });
}
