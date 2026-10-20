// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/docente_course.dart';
import '../controllers/docente_controller.dart';
import '../widgets/syllabus_materials_modal.dart';
import 'docente_assignments_tab.dart';
import 'docente_diary_tab.dart';
import 'docente_grades_tab.dart';

/// Full-page Course Hub (AVA) providing a centralized cockpit for a specific discipline.
class DocenteCourseHubPage extends StatefulWidget {
  /// Selected course entity.
  final DocenteCourse course;

  /// Reactive controller for state access.
  final DocenteController controller;

  const DocenteCourseHubPage({
    super.key,
    required this.course,
    required this.controller,
  });

  @override
  State<DocenteCourseHubPage> createState() => _DocenteCourseHubPageState();
}

class _DocenteCourseHubPageState extends State<DocenteCourseHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSyllabusModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => SyllabusMaterialsModal(
        course: widget.course,
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocenteColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavBar(),
            _buildTabsHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  DocenteDiaryTab(controller: widget.controller),
                  DocenteGradesTab(controller: widget.controller),
                  DocenteAssignmentsTab(controller: widget.controller),
                  _buildMaterialsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: DocenteColors.white,
        border: Border(bottom: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Voltar para Minhas Turmas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.course.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DocenteColors.offWhite,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: DocenteColors.border),
                      ),
                      child: Text(
                        widget.course.code,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DocenteColors.slate),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.course.semester} • ${widget.course.schedule} • ${widget.course.room} • Carga Horária: ${widget.course.workloadHours}h',
                  style: const TextStyle(fontSize: 12, color: DocenteColors.slate),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/video-call');
            },
            icon: const Icon(Icons.videocam_rounded, size: 18),
            label: const Text('Iniciar Transmissão ao Vivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.emerald,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsHeader() {
    return Container(
      color: DocenteColors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: DocenteColors.charcoal,
        unselectedLabelColor: DocenteColors.slate,
        indicatorColor: DocenteColors.charcoal,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Visão Geral & Cockpit'),
          Tab(text: 'Diário de Classe & Frequência'),
          Tab(text: 'Livro de Notas & Gradebook'),
          Tab(text: 'Atividades & Rubricas'),
          Tab(text: 'Ementa & Materiais Didáticos'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewMetrics(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _buildCourseStatusCard(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _buildPedagogicalAlertsCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    return Row(
      children: [
        _buildMetricCard('Progresso da Ementa', '${(widget.course.progress * 100).toInt()}%', Icons.menu_book_outlined, DocenteColors.charcoal),
        const SizedBox(width: 16),
        _buildMetricCard('Média Semestral da Turma', '7.8', Icons.bar_chart_rounded, DocenteColors.emerald),
        const SizedBox(width: 16),
        _buildMetricCard('Taxa Média de Presença', '88.4%', Icons.fact_check_outlined, DocenteColors.charcoal),
        const SizedBox(width: 16),
        _buildMetricCard('Alunos Matriculados', '${widget.course.enrolledCount}', Icons.groups_outlined, DocenteColors.charcoal),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DocenteColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DocenteColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                ),
                Text(label, style: const TextStyle(fontSize: 11, color: DocenteColors.slate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStatusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unidades do Plano de Ensino (MEC)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
              ),
              OutlinedButton.icon(
                onPressed: _openSyllabusModal,
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Gerenciar Plano', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.charcoal,
                  side: const BorderSide(color: DocenteColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.course.syllabusUnits.map((unit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DocenteColors.offWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DocenteColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unit.description,
                          style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: unit.isCompleted ? DocenteColors.emerald.withOpacity(0.1) : DocenteColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: unit.isCompleted ? DocenteColors.emerald : DocenteColors.border),
                    ),
                    child: Text(
                      '${unit.completedClasses}/${unit.totalClasses} Aulas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: unit.isCompleted ? DocenteColors.emerald : DocenteColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPedagogicalAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: DocenteColors.amber, size: 20),
              SizedBox(width: 10),
              Text(
                'Alertas Pedagógicos da Turma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAlertItem(
            'Frequência Crítica',
            'Lucas Silva (RA: 24801122) atingiu 23.7% de faltas acumuladas (limite MEC: 25%).',
            DocenteColors.crimson,
          ),
          const SizedBox(height: 12),
          _buildAlertItem(
            'Entregas Pendentes',
            '2 discentes ainda não enviaram a APS 1 (Prazo encerra em 48 horas).',
            DocenteColors.amber,
          ),
          const SizedBox(height: 12),
          _buildAlertItem(
            'Homologação Quinzenal',
            'Diário de classe da aula de 20/09/2026 pendente de homologação oficial.',
            const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: DocenteColors.charcoal, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repositório de Materiais & Slides',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Arquivos, apostilas e diretrizes disponibilizadas para os estudantes da disciplina',
                    style: TextStyle(fontSize: 13, color: DocenteColors.slate),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openSyllabusModal,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Publicar Novo Arquivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DocenteColors.charcoal,
                  foregroundColor: DocenteColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.course.materials.map((mat) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DocenteColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DocenteColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DocenteColors.offWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DocenteColors.border),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: DocenteColors.crimson, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mat.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                        ),
                        Text(
                          'Publicado em: ${mat.date} • Tamanho: ${mat.size} • Formato: ${mat.type}',
                          style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Download do arquivo "${mat.title}" iniciado.'),
                          backgroundColor: DocenteColors.charcoal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Baixar', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DocenteColors.charcoal,
                      side: const BorderSide(color: DocenteColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
