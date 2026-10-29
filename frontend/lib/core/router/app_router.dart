// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/pages/admin_shell_page.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth/forgot_password/presentation/pages/recover_password_page.dart';
import 'package:pi_iv_time3/features/auth/login/presentation/controllers/login_controller.dart';
import 'package:pi_iv_time3/features/auth/login/presentation/pages/login_page.dart';
import 'package:pi_iv_time3/features/auth/reset_password/presentation/pages/reset_password_page.dart';
import 'package:pi_iv_time3/features/auth/shared/domain/auth_repository.dart';
import 'package:pi_iv_time3/features/auth/verify_code/presentation/pages/verify_code_page.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/pages/docente_shell_page.dart';
import 'package:pi_iv_time3/features/student/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/pages/student_calendar_page.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/pages/student_deliveries_page.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/pages/student_disciplines_page.dart';
import 'package:pi_iv_time3/features/student/messages/presentation/pages/student_messages_page.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/pages/student_secretariat_page.dart';
import 'package:pi_iv_time3/features/student/settings/presentation/pages/student_settings_page.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/pages/student_portal_shell.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/student_sidebar.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_lobby_page.dart';

/// Nomes padronizados das rotas do Portal Acadêmico.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/';
  static const String recoverPassword = '/recover-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String studentHome = '/student/home';
  static const String studentMessages = '/student/messages';
  static const String studentSecretaria = '/student/secretaria';
  static const String studentDisciplines = '/student/disciplinas';
  static const String studentCalendar = '/student/calendario';
  static const String studentDeliveries = '/student/entregas';
  static const String studentSettings = '/student/configuracoes';
  static const String docenteHome = '/docente/home';
  static const String adminShell = '/admin-shell';
  static const String videoCall = '/video-call';
}

/// Roteador centralizado da aplicação, desacoplando a árvore de rotas do bootstrap (`main.dart`).
class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      AppRoutes.studentHome: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Painel Geral',
          activeNavItem: StudentNavItem.painelGeral,
          child: StudentDashboardPage(),
        ),
      ),
      // Todas as rotas do aluno usam o mesmo shell. Isso evita que links
      // diretos renderizem uma página sem navegação, cabeçalho e rodapé.
      AppRoutes.studentMessages: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Mensagens',
          activeNavItem: StudentNavItem.mensagens,
          child: StudentMessagesPage(),
        ),
      ),
      AppRoutes.studentSecretaria: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Secretaria Virtual',
          activeNavItem: StudentNavItem.secretaria,
          child: StudentSecretariatPage(),
        ),
      ),
      AppRoutes.studentDisciplines: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Disciplinas',
          activeNavItem: StudentNavItem.disciplinas,
          child: StudentDisciplinesPage(),
        ),
      ),
      AppRoutes.studentCalendar: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Calendário',
          activeNavItem: StudentNavItem.calendario,
          child: StudentCalendarPage(),
        ),
      ),
      AppRoutes.studentDeliveries: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Entregas',
          activeNavItem: StudentNavItem.entregas,
          child: StudentDeliveriesPage(),
        ),
      ),
      AppRoutes.studentSettings: _studentRoute(
        const StudentPortalShell(
          headerTitle: 'Configurações',
          activeNavItem: StudentNavItem.configuracoes,
          child: StudentSettingsPage(),
        ),
      ),
      AppRoutes.videoCall: _buildVideoCallRoute,
      AppRoutes.adminShell: _roleRoute('admin', const AdminShellPage()),
      AppRoutes.docenteHome: _roleRoute('docente', const DocenteShellPage()),
    };
  }

  static WidgetBuilder _roleRoute(String role, Widget child) => (context) {
    if (AppUserSession.instance.hasRole(role)) return child;
    return _accessDenied(context, 'Esta área é exclusiva do perfil $role.');
  };

  static WidgetBuilder _studentRoute(Widget child) => (context) {
    final session = AppUserSession.instance;
    if (!session.hasRole('aluno')) {
      return _accessDenied(context, 'Esta área é exclusiva do perfil aluno.');
    }
    if (!StudentMockData.ownsDemoRecords(session.identity ?? '')) {
      return _accessDenied(
        context,
        'Não há dados acadêmicos de demonstração vinculados a esta conta.',
      );
    }
    return child;
  };

  static Widget _buildVideoCallRoute(BuildContext context) {
    final session = AppUserSession.instance;
    if (!session.isAuthenticated) {
      return _accessDenied(
        context,
        'Faça login para acessar uma videochamada.',
      );
    }

    final arguments = ModalRoute.of(context)?.settings.arguments;
    final roomCode = arguments is Map
        ? arguments['roomCode']?.toString()
        : null;
    if (roomCode == null || roomCode.trim().isEmpty) {
      return _accessDenied(context, 'Selecione uma turma para continuar.');
    }

    return VideoCallLobbyPage(initialRoomCode: roomCode);
  }

  static Widget _accessDenied(BuildContext context, String message) {
    return AccessDeniedView(
      message: message,
      fullPage: true,
      onReturn: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
    );
  }

  static Route<dynamic>? onGenerateRoute({
    required RouteSettings settings,
    required RecoverPasswordController recoverController,
    required AuthRepository authRepository,
    required LoginController loginController,
  }) {
    final WidgetBuilder? pageBuilder = switch (settings.name) {
      AppRoutes.login => (_) => LoginPage(controller: loginController),
      AppRoutes.recoverPassword => (_) => RecoverPasswordPage(
        controller: recoverController,
      ),
      AppRoutes.verifyCode => (_) => VerifyCodePage(repository: authRepository),
      AppRoutes.resetPassword => (_) => ResetPasswordPage(
        repository: authRepository,
      ),
      _ => buildRoutes()[settings.name],
    };

    if (pageBuilder == null) return null;

    if (_isAuthRoute(settings.name)) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, secondaryAnimation) =>
            pageBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.045, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                        begin: Offset.zero,
                        end: const Offset(-0.025, 0),
                      )
                      .chain(CurveTween(curve: Curves.easeInOutCubic))
                      .animate(secondaryAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1)
                    .chain(CurveTween(curve: Curves.easeOutCubic))
                    .animate(animation),
                child: child,
              ),
            ),
          );
        },
      );
    }

    return MaterialPageRoute<dynamic>(settings: settings, builder: pageBuilder);
  }

  static bool _isAuthRoute(String? routeName) {
    return routeName == AppRoutes.login ||
        routeName == AppRoutes.recoverPassword ||
        routeName == AppRoutes.verifyCode ||
        routeName == AppRoutes.resetPassword;
  }
}
