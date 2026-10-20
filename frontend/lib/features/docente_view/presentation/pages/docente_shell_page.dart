// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../controllers/docente_controller.dart';
import '../widgets/docente_header.dart';
import '../widgets/docente_sidebar.dart';
import 'docente_assignments_tab.dart';
import 'docente_calendar_tab.dart';
import 'docente_courses_tab.dart';
import 'docente_dashboard_tab.dart';
import 'docente_diary_tab.dart';
import 'docente_grades_tab.dart';
import 'docente_messages_tab.dart';
import 'docente_settings_tab.dart';

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

  Widget _buildCurrentTab(DocenteNavTab tab) {
    switch (tab) {
      case DocenteNavTab.painel:
        return DocenteDashboardTab(controller: _controller);
      case DocenteNavTab.turmas:
        return DocenteCoursesTab(controller: _controller);
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
                      child: DocenteSidebar(
                        controller: _controller,
                        onTabSelected: () => Navigator.of(context).pop(),
                      ),
                    ),
              body: Row(
                children: [
                  if (isDesktop)
                    DocenteSidebar(controller: _controller),
                  Expanded(
                    child: Column(
                      children: [
                        DocenteHeader(
                          controller: _controller,
                          onMenuPressed: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
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
