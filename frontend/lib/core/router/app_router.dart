// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/pages/admin_shell_page.dart';
import 'package:pi_iv_time3/features/auth_view/forgot_password/presentation/controllers/recover_password_controller.dart';
import 'package:pi_iv_time3/features/auth_view/forgot_password/presentation/pages/recover_password_page.dart';
import 'package:pi_iv_time3/features/auth_view/login/presentation/controllers/login_controller.dart';
import 'package:pi_iv_time3/features/auth_view/login/presentation/pages/login_page.dart';
import 'package:pi_iv_time3/features/auth_view/reset_password/presentation/pages/reset_password_page.dart';
import 'package:pi_iv_time3/features/auth_view/verify_code/presentation/pages/verify_code_page.dart';
import 'package:pi_iv_time3/features/docente_view/shell/presentation/pages/docente_shell_page.dart';
import 'package:pi_iv_time3/features/student_view/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:pi_iv_time3/features/student_view/messages/presentation/pages/student_messages_page.dart';
import 'package:pi_iv_time3/features/student_view/secretariat/presentation/pages/student_secretariat_page.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/pages/student_portal_shell.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';
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
  static const String docenteHome = '/docente/home';
  static const String adminShell = '/admin-shell';
  static const String videoCall = '/video-call';
}

/// Roteador centralizado da aplicação, desacoplando a árvore de rotas do bootstrap (`main.dart`).
class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> buildRoutes({
    required RecoverPasswordController recoverController,
    LoginController? loginController,
  }) {
    return {
      AppRoutes.login: (context) => LoginPage(controller: loginController),
      AppRoutes.recoverPassword: (context) => RecoverPasswordPage(controller: recoverController),
      AppRoutes.verifyCode: (context) => const VerifyCodePage(),
      AppRoutes.resetPassword: (context) => const ResetPasswordPage(),
      AppRoutes.studentHome: (context) => const StudentPortalShell(
        headerTitle: 'Painel Geral',
        activeNavItem: StudentNavItem.painelGeral,
        child: StudentDashboardPage(),
      ),
      AppRoutes.studentMessages: (context) => const StudentMessagesPage(),
      AppRoutes.studentSecretaria: (context) => const StudentSecretariatPage(),
      AppRoutes.videoCall: (context) => const VideoCallLobbyPage(),
      AppRoutes.adminShell: (context) => const AdminShellPage(),
      AppRoutes.docenteHome: (context) => const DocenteShellPage(),
    };
  }
}

