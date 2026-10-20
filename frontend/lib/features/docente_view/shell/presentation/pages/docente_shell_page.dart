// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/assignments/presentation/pages/docente_assignments_tab.dart';
import 'package:pi_iv_time3/features/docente_view/calendar/presentation/pages/docente_calendar_tab.dart';
import 'package:pi_iv_time3/features/docente_view/courses/presentation/pages/docente_course_hub_page.dart';
import 'package:pi_iv_time3/features/docente_view/courses/presentation/pages/docente_courses_tab.dart';
import 'package:pi_iv_time3/features/docente_view/dashboard/presentation/pages/docente_dashboard_tab.dart';
import 'package:pi_iv_time3/features/docente_view/diary/presentation/pages/docente_diary_tab.dart';
import 'package:pi_iv_time3/features/docente_view/grades/presentation/pages/docente_grades_tab.dart';
import 'package:pi_iv_time3/features/docente_view/messages/presentation/pages/docente_messages_tab.dart';
import 'package:pi_iv_time3/features/docente_view/settings/presentation/pages/docente_settings_tab.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';
import '../widgets/docente_header.dart';
import '../widgets/docente_sidebar.dart';

/// Main navigation shell for the Docente Portal providing sidebar, header, and reactive tab rendering.
class DocenteShellPage extends StatefulWidget {
  /// Optional initial tab.
  final DocenteNavTab initialTab;

  const DocenteShellPage({
    super.key,
    this.initialTab = DocenteNavTab.painel,
  });

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
    Navigator.of(context).pushNamed('/video-call');
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
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
        return LayoutBuilder(
          builder: (context, constraints) {
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
                    DocenteSidebar(
                      controller: _controller,
                      onLogout: _logout,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        DocenteHeader(
                          controller: _controller,
                          onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
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

