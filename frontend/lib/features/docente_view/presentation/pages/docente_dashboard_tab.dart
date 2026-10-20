// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../controllers/docente_controller.dart';

/// Main dashboard view for the Docente Portal.
class DocenteDashboardTab extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback onOpenVideoCall;
  final void Function(String courseId) onOpenCourseHub;

  const DocenteDashboardTab({
    super.key,
    required this.controller,
    required this.onOpenVideoCall,
    required this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Section
              _buildHeroSection(),
              const SizedBox(height: 32),

              // 4 KPI Metric Cards
              _buildKpiMetricsGrid(context),
              const SizedBox(height: 32),

              // Aula do Dia & Plantão Card
              _buildLiveClassCard(context),
              const SizedBox(height: 32),

              // Minhas Turmas Cards
              _buildCoursesPreview(context),
              const SizedBox(height: 32),

              // Bottom Split: Prazos e Entregas + Mensagens e Avisos
              _buildBottomSplitSection(context),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bem-vinda, Helena.',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: DocenteColors.textPrimary,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: const [
            Text(
              'Departamento de Computação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: DocenteColors.textSecondary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                fontSize: 16,
                color: DocenteColors.textMuted,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Docência 2026/2',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: DocenteColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiMetricsGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;

    final cards = [
      _buildStatCard(
        title: 'TURMAS ATIVAS',
        value: '03',
        subtitle: 'no Semestre',
        footerLabel: 'Discentes Matriculados',
        footerValue: '101 alunos',
        progress: 1.0,
      ),
      _buildStatCard(
        title: 'ENTREGAS DO MÊS',
        value: '04',
        subtitle: 'Cadastradas',
        footerLabel: 'Próximo Vencimento',
        footerValue: 'Hoje, 23:59',
        progress: 0.5,
      ),
      _buildStatCard(
        title: 'CARGA HORÁRIA TOTAL',
        value: '158h',
        subtitle: '/ 240h',
        footerLabel: 'Cumprimento do Plano',
        footerValue: '65.8%',
        progress: 0.658,
      ),
      _buildStatCard(
        title: 'FREQUÊNCIA MÉDIA',
        value: '94.8%',
        subtitle: 'das Turmas',
        footerLabel: 'Situação Geral',
        footerValue: 'Regular',
        progress: 0.948,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map(
              (c) => SizedBox(
                width: (width - 80) / (width > 600 ? 2 : 1),
                child: c,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required String footerLabel,
    required String footerValue,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DocenteColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EEE9),
              valueColor: const AlwaysStoppedAnimation<Color>(DocenteColors.textPrimary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  footerLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                footerValue,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
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
                'Aula do Dia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DocenteColors.dangerLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: DocenteColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AO VIVO • TRANSMITINDO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.danger,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'HOJE, 20 SET • 19:10 - 20:50',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Análise e Projeto de Sistemas II',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '43 alunos conectados no AVA • Lab 04 • Sala Virtual Teams',
            style: TextStyle(
              fontSize: 14,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onOpenVideoCall,
                icon: const Icon(Icons.videocam_rounded, size: 20),
                label: const Text('Iniciar Transmissão'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DocenteColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => onOpenCourseHub('course-aps2'),
                icon: const Icon(Icons.hub_outlined, size: 18),
                label: const Text('Abrir Course Hub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.textPrimary,
                  side: const BorderSide(color: DocenteColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DocenteColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.schedule_rounded, size: 18, color: DocenteColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Atendimento Docente:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Plantão de dúvidas e orientação às 17:30 no Gabinete 12.',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: DocenteColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Turmas e Disciplinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DocenteColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => controller.navigateToTab(DocenteNavTab.turmas),
              child: const Text('Ver todas as turmas →'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide
                ? Row(
                    children: controller.courses.map((course) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildCourseCard(course),
                        ),
                      );
                    }).toList(),
                  )
                : Column(
                    children: controller.courses.map((course) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCourseCard(course),
                      );
                    }).toList(),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.code,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.enrolledCount} alunos',
                style: const TextStyle(
                  fontSize: 12,
                  color: DocenteColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.schedule,
            style: const TextStyle(
              fontSize: 12,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (course.progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EEE9),
              valueColor: const AlwaysStoppedAnimation<Color>(DocenteColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carga Horária: ${course.completedHours}h / ${course.totalHours}h',
                style: const TextStyle(fontSize: 12, color: DocenteColors.textSecondary),
              ),
              Text(
                '${course.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.selectCourse(course.id);
                    controller.navigateToTab(DocenteNavTab.diario);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Diário', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.selectCourse(course.id);
                    controller.navigateToTab(DocenteNavTab.notas);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Notas', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSplitSection(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    final prazosCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Prazos e Entregas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '04 tarefas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            title: 'Entrega: Diagrama de Classes e Sequência',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Hoje, 20/09 às 23:59',
            isUrgent: true,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Fórum Temático: Arquitetura de Software',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Amanhã, 21/09 às 18:00',
            isUrgent: true,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Atividade Prática: Modelagem Relacional e Normalização',
            course: 'Estudos de Banco de Dados II',
            date: 'Quinta, 24/09 às 23:59',
            isUrgent: false,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Avaliação Parcial: Gerenciamento de Memória',
            course: 'Fundamentos de Sistemas Operacionais',
            date: 'Terça, 29/09 às 20:40',
            isUrgent: false,
          ),
        ],
      ),
    );

    final avisosCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
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
                'Mensagens e Avisos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => controller.navigateToTab(DocenteNavTab.comunicados),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoticeItem(
            author: 'Você (Profa. Helena Bittencourt)',
            time: 'Hoje, 14:10',
            title: 'Feedback da Sprint 1 e Orientações para o Diagrama UML',
            preview:
                'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildNoticeItem(
            author: 'Coordenação de Curso (Sistemas de Informação)',
            time: 'Ontem, 17:45',
            title: 'Homologação de Diários de Classe - Fechamento 1º Bimestre',
            preview:
                'Lembramos aos docentes que a consolidação das notas parciais e faltas deve ser realizada até sexta-feira.',
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildNoticeItem(
            author: 'Secretaria Acadêmica AGMRM',
            time: '18 de set',
            title: 'Calendário de Provas Regimentais 2026/2 Homologado',
            preview: 'O cronograma definitivo de avaliações institucionais encontra-se disponível no sistema.',
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: prazosCard),
          const SizedBox(width: 24),
          Expanded(child: avisosCard),
        ],
      );
    } else {
      return Column(
        children: [
          prazosCard,
          const SizedBox(height: 24),
          avisosCard,
        ],
      );
    }
  }

  Widget _buildDeadlineItem({
    required String title,
    required String course,
    required String date,
    required bool isUrgent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textPrimary,
                ),
              ),
            ),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DocenteColors.warningLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Urgente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.warning,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              course,
              style: const TextStyle(fontSize: 12, color: DocenteColors.textSecondary),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUrgent ? DocenteColors.warning : DocenteColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoticeItem({
    required String author,
    required String time,
    required String title,
    required String preview,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                author,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: DocenteColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DocenteColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: DocenteColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
