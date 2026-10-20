// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import '../widgets/ava_assignments_tab.dart';
import '../widgets/ava_evaluations_grades_tab.dart';
import '../widgets/ava_forum_collaboration_tab.dart';
import '../widgets/ava_live_classroom_tab.dart';
import '../widgets/ava_syllabus_materials_tab.dart';

/// Cockpit do Ambiente Virtual de Aprendizagem (AVA) do discente para a disciplina selecionada.
/// Implementa as 12 seções pedagógicas com suporte a chat, fórum, notas, sala virtual e entregas.
class StudentAvaCockpitPage extends StatefulWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onBack;

  const StudentAvaCockpitPage({
    super.key,
    required this.discipline,
    required this.onBack,
  });

  @override
  State<StudentAvaCockpitPage> createState() => _StudentAvaCockpitPageState();
}

class _StudentAvaCockpitPageState extends State<StudentAvaCockpitPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

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
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Voltar para Minhas Disciplinas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 16),
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
                  widget.discipline.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.discipline.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.discipline.professor} • ${widget.discipline.location} • 2026/2',
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
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat(
                'Progresso Geral',
                '${(widget.discipline.progress * 100).toInt()}%',
              ),
              const SizedBox(width: 32),
              _buildHeaderStat(
                'Frequência Homologada',
                '${widget.discipline.attendancePercentage}% (${widget.discipline.absences} faltas)',
              ),
              const SizedBox(width: 32),
              _buildHeaderStat(
                'Média Ponderada Parcial',
                widget.discipline.partialAverage.toStringAsFixed(2),
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
        return AvaEvaluationsGradesTab(discipline: widget.discipline);
      default:
        return AvaSyllabusMaterialsTab(activeTabIndex: 0);
    }
  }
}
