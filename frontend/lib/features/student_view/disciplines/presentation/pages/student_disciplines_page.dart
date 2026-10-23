// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'student_ava_cockpit_page.dart';
import '../widgets/student_disciplines_stats_card.dart';
import '../widgets/student_disciplines_grid_view.dart';
import '../widgets/student_disciplines_schedule_table.dart';
import '../widgets/student_disciplines_modals.dart';

/// Tela principal de Minhas Disciplinas da Visão do Aluno.
///
/// Apresenta o cabeçalho institucional, card consolidado de indicadores (Carga Horária,
/// Média Ponderada, Frequência e Situação), barra de filtros e busca, grade de disciplinas 2x2,
/// quadro semanal de horários/laboratórios, próximas avaliações, mural e apoio acadêmico.
class StudentDisciplinesPage extends StatefulWidget {
  const StudentDisciplinesPage({super.key});

  @override
  State<StudentDisciplinesPage> createState() => _StudentDisciplinesPageState();
}

class _StudentDisciplinesPageState extends State<StudentDisciplinesPage> {
  final StudentPortalController _controller = StudentPortalController.instance;
  final TextEditingController _searchController = TextEditingController();
  StudentDisciplineModel? _activeDisciplineCockpit;
  String _selectedFilter = 'Todas as Disciplinas (4)';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentDisciplineModel> get _filteredDisciplines {
    var list = StudentMockData.disciplines;

    if (_selectedFilter == 'Com Tarefas Pendentes (3)') {
      list = list.where((d) => d.hasPendingTask).toList();
    } else if (_selectedFilter == 'Aulas em Laboratório (2)') {
      list = list.where((d) => d.location.toLowerCase().contains('lab')).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((d) {
        return d.name.toLowerCase().contains(query) ||
            d.code.toLowerCase().contains(query) ||
            (d.fullCode?.toLowerCase().contains(query) ?? false) ||
            d.professor.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

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
          _buildFilterAndSearchRow(),
          const SizedBox(height: 24),
          StudentDisciplinesGridView(
            disciplines: _filteredDisciplines,
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
            children: [
              Text(
                'Minhas Disciplinas',
                style: jakarta(
                  size: 24,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ambiente Virtual de Aprendizagem (AVA), cronograma de aulas, tarefas ativas e boletim oficial.',
                style: jakarta(
                  size: 13,
                  color: const Color(0xFF71717A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          key: const Key('btn_boletim_historico_oficial'),
          onPressed: () => StudentDisciplinesModals.showBoletimModal(context),
          icon: const Icon(
            Icons.receipt_long_outlined,
            size: 16,
            color: Color(0xFF18181B),
          ),
          label: Text(
            'Boletim & Histórico Oficial',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchRow() {
    final filters = [
      'Todas as Disciplinas (4)',
      'Com Tarefas Pendentes (3)',
      'Aulas em Laboratório (2)',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 768;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildFilterChips(filters)),
              ),
              const SizedBox(height: 12),
              _buildSearchInput(),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: _buildFilterChips(filters)),
            SizedBox(width: 280, child: _buildSearchInput()),
          ],
        );
      },
    );
  }

  List<Widget> _buildFilterChips(List<String> filters) {
    return filters.map((f) {
      final isSelected = _selectedFilter == f;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = f),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              f,
              style: jakarta(
                size: 11.5,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF52525B),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSearchInput() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: jakarta(size: 12),
        decoration: InputDecoration(
          hintText: 'Filtrar por nome, código ou docente...',
          hintStyle: jakarta(size: 11.5, color: const Color(0xFFA1A1AA)),
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFFA1A1AA)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF18181B)),
          ),
        ),
      ),
    );
  }
}
