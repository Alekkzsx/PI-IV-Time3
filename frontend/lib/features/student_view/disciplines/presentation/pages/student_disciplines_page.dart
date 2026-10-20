// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'student_ava_cockpit_page.dart';
import '../widgets/student_disciplines_stats_card.dart';
import '../widgets/student_disciplines_grid_view.dart';
import '../widgets/student_disciplines_schedule_table.dart';
import '../widgets/student_disciplines_modals.dart';

/// Tela principal de Minhas Disciplinas da Visão do Aluno.
/// Exibe carga horária total, média consolidada, ensalamento semanal,
/// modais de Boletim Oficial e Ementário, e acesso ao Ambiente Virtual (AVA).
class StudentDisciplinesPage extends StatefulWidget {
  const StudentDisciplinesPage({super.key});

  @override
  State<StudentDisciplinesPage> createState() => _StudentDisciplinesPageState();
}

class _StudentDisciplinesPageState extends State<StudentDisciplinesPage> {
  final StudentPortalController _controller = StudentPortalController.instance;
  StudentDisciplineModel? _activeDisciplineCockpit;
  String _selectedFilter = 'Todas as Disciplinas (4)';

  @override
  Widget build(BuildContext context) {
    if (_activeDisciplineCockpit != null) {
      return StudentAvaCockpitPage(
        discipline: _activeDisciplineCockpit!,
        onBack: () => setState(() => _activeDisciplineCockpit = null),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const StudentDisciplinesStatsCard(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 24),
          StudentDisciplinesGridView(
            disciplines: StudentMockData.disciplines,
            onSelectDiscipline: (discipline) {
              _controller.selectDiscipline(discipline);
              setState(() => _activeDisciplineCockpit = discipline);
            },
          ),
          const SizedBox(height: 32),
          const StudentDisciplinesScheduleTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Minhas Disciplinas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ambiente Virtual de Aprendizagem (AVA), cronograma de aulas, tarefas ativas e boletim oficial.',
                style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  StudentDisciplinesModals.showPlanoEnsinoModal(context),
              icon: const Icon(Icons.menu_book_outlined,
                  size: 18, color: Color(0xFF18181B)),
              label: const Text('Plano de Ensino & Ementa',
                  style: TextStyle(color: Color(0xFF18181B))),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  StudentDisciplinesModals.showBoletimModal(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Boletim & Histórico Oficial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      'Todas as Disciplinas (4)',
      'Com Tarefas Pendentes (3)',
      'Aulas em Laboratório (2)',
    ];

    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = f),
            selectedColor: const Color(0xFF18181B),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE2E8F0),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }).toList(),
    );
  }
}
