// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/pages/docente_assignments_tab.dart';
import 'package:pi_iv_time3/features/teacher/calendar/presentation/pages/docente_calendar_tab.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/pages/docente_course_hub_page.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/pages/docente_courses_tab.dart';
import 'package:pi_iv_time3/features/teacher/dashboard/presentation/pages/docente_dashboard_tab.dart';
import 'package:pi_iv_time3/features/teacher/diary/presentation/pages/docente_diary_tab.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/pages/docente_grades_tab.dart';
import 'package:pi_iv_time3/features/teacher/messages/presentation/pages/docente_messages_tab.dart';
import 'package:pi_iv_time3/features/teacher/settings/presentation/pages/docente_settings_tab.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';
import '../widgets/docente_header.dart';
import '../widgets/docente_sidebar.dart';

/// Main navigation shell for the Docente Portal providing sidebar, header, and reactive tab rendering.
class DocenteShellPage extends StatefulWidget {
  /// Optional initial tab.
  final DocenteNavTab initialTab;

  const DocenteShellPage({super.key, this.initialTab = DocenteNavTab.painel});

  @override
  State<DocenteShellPage> createState() => _DocenteShellPageState();
}

class _DocenteShellPageState extends State<DocenteShellPage> {
  late final DocenteController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = DocenteController();
    unawaited(_controller.loadRemote());
    if (widget.initialTab != DocenteNavTab.painel) {
      _controller.navigateToTab(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCourseHub(String courseId) {
    _controller.selectCourse(courseId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocenteCourseHubPage(
          course: _controller.selectedCourse,
          controller: _controller,
        ),
      ),
    );
  }

  void _openVideoCall() {
    final course = _controller.selectedCourse;
    Navigator.of(
      context,
    ).pushNamed('/video-call', arguments: {'roomCode': course.code});
  }

  void _logout() {
    AppUserSession.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Widget _buildCurrentTab(DocenteNavTab tab) {
    switch (tab) {
      case DocenteNavTab.painel:
        return DocenteDashboardTab(
          controller: _controller,
          onOpenVideoCall: _openVideoCall,
          onOpenCourseHub: _openCourseHub,
        );
      case DocenteNavTab.turmas:
        return DocenteCoursesTab(
          controller: _controller,
          onOpenCourseHub: _openCourseHub,
        );
      case DocenteNavTab.diario:
        return DocenteDiaryTab(controller: _controller);
      case DocenteNavTab.atividades:
        return DocenteAssignmentsTab(controller: _controller);
      case DocenteNavTab.notas:
        return DocenteGradesTab(controller: _controller);
      case DocenteNavTab.agenda:
        return DocenteCalendarTab(controller: _controller);
      case DocenteNavTab.comunicados:
        return DocenteMessagesTab(controller: _controller);
      case DocenteNavTab.configuracoes:
        return DocenteSettingsTab(controller: _controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoadingRemote && _controller.courses.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_controller.remoteError != null && _controller.courses.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Portal Docente'),
              actions: [
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_controller.remoteError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => unawaited(_controller.loadRemote(force: true)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (_controller.courses.isEmpty) {
              return Scaffold(
                backgroundColor: DocenteColors.offWhite,
                appBar: AppBar(
                  title: const Text('Portal Docente'),
                  actions: [
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nenhuma turma está vinculada a esta matrícula docente.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/video-call'),
                          icon: const Icon(Icons.video_call_outlined),
                          label: const Text('Acessar videochamada da turma'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final isDesktop = constraints.maxWidth >= 1000;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: DocenteColors.offWhite,
              drawer: isDesktop
                  ? null
                  : Drawer(
                      width: 280,
                      backgroundColor: Colors.white,
                      child: DocenteSidebar(
                        controller: _controller,
                        onLogout: () {
                          Navigator.of(context).pop();
                          _logout();
                        },
                      ),
                    ),
              body: Row(
                children: [
                  if (isDesktop)
                    DocenteSidebar(controller: _controller, onLogout: _logout),
                  Expanded(
                    child: Column(
                      children: [
                        DocenteHeader(
                          controller: _controller,
                          onOpenDrawer: isDesktop
                              ? null
                              : () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Expanded(
                          child: _buildCurrentTab(_controller.activeTab),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
