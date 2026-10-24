// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import '../widgets/student_ava_left_sidebar.dart';
import '../widgets/student_ava_right_sidebar.dart';
import '../widgets/student_ava_home_tab.dart';
import '../widgets/ava_assignments_tab.dart';
import '../widgets/ava_evaluations_grades_tab.dart';
import '../widgets/ava_forum_collaboration_tab.dart';
import '../widgets/ava_live_classroom_tab.dart';
import '../widgets/ava_syllabus_materials_tab.dart';

/// Cockpit do Ambiente Virtual de Aprendizagem (AVA) do discente para a disciplina selecionada.
/// Implementa a arquitetura de 3 colunas fiel à interface oficial:
/// - Cabeçalho institucional com breadcrumbs e dados da turma
/// - Submenu lateral vertical com pills e contadores de pendências
/// - Área central com "Módulos & Conteúdos de Aprendizagem" e checklist interativo
/// - Barra lateral direita com Dados da Matrícula, Frequência, Atendimento e Plano de Ensino
class StudentAvaCockpitPage extends StatefulWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onBack;
  final int initialTabIndex;
  final ValueChanged<StudentDisciplineModel>? onSwitchDiscipline;

  const StudentAvaCockpitPage({
    super.key,
    required this.discipline,
    required this.onBack,
    this.initialTabIndex = 0,
    this.onSwitchDiscipline,
  });

  @override
  State<StudentAvaCockpitPage> createState() => _StudentAvaCockpitPageState();
}

class _StudentAvaCockpitPageState extends State<StudentAvaCockpitPage> {
  final StudentPortalController _controller = StudentPortalController.instance;
  late StudentDisciplineModel _currentDiscipline;

  @override
  void initState() {
    super.initState();
    _currentDiscipline = widget.discipline;
    if (widget.initialTabIndex != 0) {
      _controller.setAvaTab(widget.initialTabIndex);
    }
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(StudentAvaCockpitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discipline.code != widget.discipline.code) {
      setState(() {
        _currentDiscipline = widget.discipline;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _switchDiscipline(StudentDisciplineModel newDiscipline) {
    setState(() {
      _currentDiscipline = newDiscipline;
    });
    _controller.selectDiscipline(newDiscipline);
    widget.onSwitchDiscipline?.call(newDiscipline);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumbAndHeader(),
          const SizedBox(height: 24),
          _buildMainLayout(),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO & BREADCRUMBS
  // ==========================================
  Widget _buildBreadcrumbAndHeader() {
    final fullCode = _currentDiscipline.fullCode ?? '218131 - ${_currentDiscipline.code}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb row
        Row(
          children: [
            InkWell(
              key: const Key('btn_voltar_minhas_disciplinas'),
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 14, color: Color(0xFF71717A)),
                    const SizedBox(width: 4),
                    Text(
                      'Minhas Disciplinas',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '>',
              style: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
            ),
            const SizedBox(width: 8),
            Text(
              fullCode,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const Spacer(),
            // Seletor rápido de disciplina no topo
            _buildDisciplineSwitcher(),
          ],
        ),
        const SizedBox(height: 12),

        // Título da disciplina
        Text(
          _currentDiscipline.name,
          style: jakarta(
            size: 24,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),

        // Subtítulo da disciplina
        Text(
          'Docente Responsável: ${_currentDiscipline.professor} • Turno Noturno • Semestre 2026/2',
          style: jakarta(
            size: 12.5,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildDisciplineSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Trocar disciplina:',
            style: jakarta(size: 11, color: const Color(0xFF71717A), weight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          for (final d in StudentMockData.disciplines) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                onTap: () => _switchDiscipline(d),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _currentDiscipline.code == d.code
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _currentDiscipline.code == d.code
                          ? const Color(0xFF18181B)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    d.code,
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: _currentDiscipline.code == d.code
                          ? Colors.white
                          : const Color(0xFF52525B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // LAYOUT DE 3 COLUNAS DO AVA
  // ==========================================
  Widget _buildMainLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1050;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentAvaLeftSidebar(
                activeIndex: _controller.activeAvaTabIndex,
                onSelectTab: (idx) => _controller.setAvaTab(idx),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildActiveTabContent(),
              ),
              const SizedBox(width: 24),
              StudentAvaRightSidebar(discipline: _currentDiscipline),
            ],
          );
        }

        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentAvaLeftSidebar(
                activeIndex: _controller.activeAvaTabIndex,
                onSelectTab: (idx) => _controller.setAvaTab(idx),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActiveTabContent(),
                    const SizedBox(height: 24),
                    StudentAvaRightSidebar(discipline: _currentDiscipline),
                  ],
                ),
              ),
            ],
          );
        }

        // Mobile
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(StudentAvaLeftSidebar.menuItems.length, (index) {
                  final item = StudentAvaLeftSidebar.menuItems[index];
                  final isSelected = _controller.activeAvaTabIndex == index;
                  final title = item['title'] as String;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(title),
                      selected: isSelected,
                      onSelected: (_) => _controller.setAvaTab(index),
                      selectedColor: const Color(0xFF18181B),
                      backgroundColor: Colors.white,
                      labelStyle: jakarta(
                        size: 11.5,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF52525B),
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            _buildActiveTabContent(),
            const SizedBox(height: 24),
            StudentAvaRightSidebar(discipline: _currentDiscipline),
          ],
        );
      },
    );
  }

  Widget _buildActiveTabContent() {
    final idx = _controller.activeAvaTabIndex;

    switch (idx) {
      case 0:
        return StudentAvaHomeTab(
          discipline: _currentDiscipline,
          onNavigateToAssignments: () => _controller.setAvaTab(1),
        );
      case 1:
        return AvaAssignmentsTab(controller: _controller);
      case 2:
        return AvaLiveClassroomTab(controller: _controller);
      case 3:
        return AvaForumCollaborationTab(
          activeTabIndex: 3,
          controller: _controller,
        );
      case 4:
        return AvaEvaluationsGradesTab(discipline: _currentDiscipline);
      case 5:
        return AvaForumCollaborationTab(
          activeTabIndex: 5,
          controller: _controller,
        );
      case 6:
        return AvaSyllabusMaterialsTab(activeTabIndex: 6);
      case 7:
        return AvaSyllabusMaterialsTab(activeTabIndex: 7);
      case 8:
        return AvaForumCollaborationTab(
          activeTabIndex: 8,
          controller: _controller,
        );
      case 9:
        return AvaForumCollaborationTab(
          activeTabIndex: 9,
          controller: _controller,
        );
      case 10:
        return AvaForumCollaborationTab(
          activeTabIndex: 10,
          controller: _controller,
        );
      default:
        return StudentAvaHomeTab(
          discipline: _currentDiscipline,
          onNavigateToAssignments: () => _controller.setAvaTab(1),
        );
    }
  }
}
