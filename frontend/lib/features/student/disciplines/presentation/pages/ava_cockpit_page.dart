// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../widgets/ava/ava_left_sidebar.dart';
import '../widgets/ava/ava_right_sidebar.dart';
import '../widgets/ava/ava_home_tab.dart';
import '../widgets/ava/ava_assignments_tab.dart';
import '../widgets/ava/ava_live_classroom_tab.dart';
import '../widgets/ava/ava_evaluations_grades_tab.dart';
import '../widgets/ava/tabs/ava_tabs.dart';
import '../../../../../core/theme/institutional_tokens.dart';

/// [AvaCockpitPage]
///
/// Página principal do Ambiente Virtual de Aprendizagem (AVA) para a visão do estudante.
/// Implementa uma arquitetura responsiva de 3 colunas (Menu Lateral Esquerdo,
/// Conteúdo Central Dinâmico das 11 Abas `0..10` e Painel de Informações Direita).
class AvaCockpitPage extends StatefulWidget {
  /// Disciplina acadêmica inicialmente selecionada para carregamento no cockpit.
  final StudentDisciplineModel discipline;

  /// Índice numérico inicial da aba do AVA a ser exibida.
  final int initialTabIndex;

  /// Callback de navegação para retorno à listagem geral de disciplinas.
  final VoidCallback onBack;

  /// Callback opcional para notificar troca de disciplina no cockpit.
  final ValueChanged<StudentDisciplineModel>? onSwitchDiscipline;

  /// Cria uma nova instância de [AvaCockpitPage].
  const AvaCockpitPage({
    super.key,
    required this.discipline,
    this.initialTabIndex = 0,
    required this.onBack,
    this.onSwitchDiscipline,
  });

  @override
  State<AvaCockpitPage> createState() => _AvaCockpitPageState();
}

class _AvaCockpitPageState extends State<AvaCockpitPage> {
  final StudentPortalController _controller = StudentPortalController.instance;
  late StudentDisciplineModel _currentDiscipline;

  @override
  void initState() {
    super.initState();
    _currentDiscipline = widget.discipline;
    _controller.activeAvaTabIndex = widget.initialTabIndex;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AvaCockpitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discipline.code != widget.discipline.code) {
      _currentDiscipline = widget.discipline;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        if (_controller.selectedDiscipline != null) {
          _currentDiscipline = _controller.selectedDiscipline!;
        }
      });
    }
  }

  /// Altera a disciplina ativa em foco no cockpit.
  void switchDiscipline(StudentDisciplineModel newDisc) {
    _controller.selectDiscipline(newDisc);
    widget.onSwitchDiscipline?.call(newDisc);
    setState(() {
      _currentDiscipline = newDisc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE5E7EB),
        textTheme: theme.textTheme.apply(fontFamily: 'Plus Jakarta Sans'),
        colorScheme: theme.colorScheme.copyWith(
          primary: InstColors.ink,
          surface: Colors.white,
        ),
      ),
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumbAndHeader(),
              const SizedBox(height: 20),
              _buildMainLayout(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CABEÇALHO & BREADCRUMBS
  // ==========================================
  Widget _buildBreadcrumbAndHeader() {
    final fullCode =
        _currentDiscipline.fullCode ?? '218131 - ${_currentDiscipline.code}';
    final shift =
        _currentDiscipline.time.toLowerCase().contains('noturno') ||
            _currentDiscipline.schedule.toLowerCase().contains('noturno')
        ? 'Turno Noturno'
        : 'Turno Diurno';
    final semester = _currentDiscipline.semester.isNotEmpty
        ? _currentDiscipline.semester
        : '2026/2';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            InkWell(
              key: const Key('btn_voltar_minhas_disciplinas'),
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 13,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Minhas Disciplinas',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFFA1A1AA)),
            Text(
              fullCode,
              style: jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _currentDiscipline.name,
          style: jakarta(
            size: 24,
            weight: FontWeight.w800,
            color: const Color(0xFF18181B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Docente Responsável: ${_currentDiscipline.professor} • $shift • Semestre $semester',
          style: jakarta(size: 13, color: const Color(0xFF71717A)),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  // ==========================================
  // LAYOUT DE 3 COLUNAS DO AVA
  // ==========================================
  Widget _buildMainLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1050;
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1050;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentAvaLeftSidebar(
                activeIndex: _controller.activeAvaTabIndex,
                onSelectTab: (idx) => _controller.setAvaTab(idx),
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildActiveTabContent()),
              const SizedBox(width: 20),
              Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                padding: const EdgeInsets.only(left: 20),
                child: StudentAvaRightSidebar(discipline: _currentDiscipline),
              ),
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

        // Mobile Layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  StudentAvaLeftSidebar.menuItems.length,
                  (index) {
                    final isSelected = _controller.activeAvaTabIndex == index;
                    final title =
                        StudentAvaLeftSidebar.menuItems[index]['title']
                            as String;
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
                          weight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF52525B),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF18181B)
                              : const Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
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

  /// Roteia diretamente para o widget modular de responsabilidade única
  /// correspondente a cada uma das 11 abas (`0..10`) do Cockpit AVA.
  Widget _buildActiveTabContent() {
    return switch (_controller.activeAvaTabIndex) {
      0 => StudentAvaHomeTab(
        discipline: _currentDiscipline,
        onNavigateToAssignments: () => _controller.setAvaTab(1),
      ),
      1 => AvaAssignmentsTab(
        controller: _controller,
        disciplineCode: _currentDiscipline.code,
      ),
      2 => AvaLiveClassroomTab(controller: _controller),
      3 => AvaForumTab(controller: _controller),
      4 => AvaEvaluationsGradesTab(discipline: _currentDiscipline),
      5 => AvaPeopleTab(controller: _controller),
      6 => const AvaFilesTab(),
      7 => const AvaSyllabusTab(),
      8 => const AvaCollaborationsTab(),
      9 => AvaNotebookTab(controller: _controller),
      10 => const AvaChatTab(),
      _ => StudentAvaHomeTab(
        discipline: _currentDiscipline,
        onNavigateToAssignments: () => _controller.setAvaTab(1),
      ),
    };
  }
}

typedef StudentAvaCockpitPage = AvaCockpitPage;
