// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
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
    AcademicBridgeService.instance.openSession(
      rawCourseCode: 'APS-II',
      openedByRole: 'docente',
      openedByName: 'Profa. Dra. Helena Bittencourt',
      roomCode: 'APS-II',
    );
    Navigator.of(context).pushNamed(
      '/video-call',
      arguments: {
        'name': 'Profa. Dra. Helena Bittencourt',
        'ra': 'DOC-40892',
        'roomCode': 'APS-II',
        'role': 'docente',
      },
    );
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
