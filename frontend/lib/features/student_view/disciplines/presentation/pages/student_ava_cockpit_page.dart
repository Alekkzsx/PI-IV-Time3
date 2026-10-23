// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import '../widgets/ava_assignments_tab.dart';
import '../widgets/ava_evaluations_grades_tab.dart';
import '../widgets/ava_forum_collaboration_tab.dart';
import '../widgets/ava_live_classroom_tab.dart';
import '../widgets/ava_syllabus_materials_tab.dart';

/// Cockpit do Ambiente Virtual de Aprendizagem (AVA) do discente para a disciplina selecionada.
/// Implementa as seções pedagógicas com suporte a chat, fórum, notas, sala virtual,
/// entregas e alternância rápida entre disciplinas ativas.
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

  final List<String> _tabs = [
    'Módulos & Conteúdos',
    'Tarefas e Atividades',
    'Sala Virtual (Ao Vivo)',
    'Fórum de Dúvidas',
    'Notas & Boletim',
    'Pessoas & Turma',
    'Arquivos & Materiais',
    'Programa (Syllabus)',
    'Colaborações (Equipe)',
    'Caderno Pessoal',
    'Chat da Turma',
  ];

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
          _buildCockpitHeader(),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 24),
          _buildActiveTabContent(),
        ],
      ),
    );
  }

  Widget _buildCockpitHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Back button + Switcher pills + Live room badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                key: const Key('btn_voltar_minhas_disciplinas'),
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Voltar para Minhas Disciplinas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SALA VIRTUAL DISPONÍVEL',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Course title and icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _currentDiscipline.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentDiscipline.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentDiscipline.professor} • ${_currentDiscipline.location} • 2026/2',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Discipline quick switcher pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Trocar disciplina no AVA:',
                  style: jakarta(size: 11, color: const Color(0xFF71717A), weight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
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
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),

          // Header stats
          Row(
            children: [
              _buildHeaderStat(
                'Progresso Geral',
                '${(_currentDiscipline.progress * 100).toInt()}%',
              ),
              const SizedBox(width: 32),
              _buildHeaderStat(
                'Frequência Homologada',
                '${_currentDiscipline.attendancePercentage}% (${_currentDiscipline.absences} faltas)',
              ),
              const SizedBox(width: 32),
              _buildHeaderStat(
                'Média Ponderada Parcial',
                _currentDiscipline.partialAverage.toStringAsFixed(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18181B),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _controller.activeAvaTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => _controller.setAvaTab(index),
              selectedColor: const Color(0xFF18181B),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    final idx = _controller.activeAvaTabIndex;
    switch (idx) {
      case 0:
      case 6:
      case 7:
      case 8:
        return AvaSyllabusMaterialsTab(activeTabIndex: idx);
      case 1:
        return AvaAssignmentsTab(controller: _controller);
      case 2:
        return AvaLiveClassroomTab(controller: _controller);
      case 3:
      case 5:
      case 9:
      case 10:
        return AvaForumCollaborationTab(
          activeTabIndex: idx,
          controller: _controller,
        );
      case 4:
        return AvaEvaluationsGradesTab(discipline: _currentDiscipline);
      default:
        return AvaSyllabusMaterialsTab(activeTabIndex: 0);
    }
  }
}
