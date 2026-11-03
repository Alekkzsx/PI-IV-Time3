// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_hero_header.dart';
import 'package:pi_iv_time3/shared/widgets/institutional_kpi_card.dart';
import '../widgets/docente_courses_preview_section.dart';
import '../widgets/docente_deadlines_notices_section.dart';
import '../widgets/docente_live_class_card.dart';

/// Visão principal do Painel Geral do Portal Docente.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1050;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Welcome Section
                      const InstitutionalHeroHeader(
                        greeting: 'Bem-vindo(a), Docente.',
                        subtitleItems: ['Portal Docente', 'Gestão acadêmica'],
                      ),
                      const SizedBox(height: 28),

                      // 4 KPI Metric Cards
                      _buildKpiMetricsGrid(context),
                      const SizedBox(height: 28),

                      // Layout em 2 Colunas (Esquerda: Aula do Dia, Minhas Turmas, Requerimentos | Direita: Prazos, Avisos)
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coluna Esquerda
                            Expanded(
                              flex: 64,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DocenteLiveClassCard(
                                    onOpenVideoCall: onOpenVideoCall,
                                    onOpenCourseHub: onOpenCourseHub,
                                  ),
                                  const SizedBox(height: 28),
                                  DocenteCoursesPreviewSection(
                                    controller: controller,
                                    onOpenCourseHub: onOpenCourseHub,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Coluna Direita
                            Expanded(
                              flex: 36,
                              child: DocenteDeadlinesNoticesSection(
                                controller: controller,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DocenteLiveClassCard(
                              onOpenVideoCall: onOpenVideoCall,
                              onOpenCourseHub: onOpenCourseHub,
                            ),
                            const SizedBox(height: 28),
                            DocenteCoursesPreviewSection(
                              controller: controller,
                              onOpenCourseHub: onOpenCourseHub,
                            ),
                            const SizedBox(height: 28),
                            DocenteDeadlinesNoticesSection(
                              controller: controller,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Rodapé Institucional Reutilizável
                const DocenteFooter(
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiMetricsGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;

    final courses = controller.courses;
    final assignments = controller.assignments;
    final sessions = controller.sessions;
    final enrolledCount = courses.fold<int>(
      0,
      (total, course) => total + course.enrolledCount,
    );
    final completedHours = courses.fold<int>(
      0,
      (total, course) => total + course.completedHours,
    );
    final totalHours = courses.fold<int>(
      0,
      (total, course) => total + course.totalHours,
    );
    final attendance = sessions.expand((session) => session.attendanceList);
    final attendanceRecords = attendance.toList();
    final attendanceRate = attendanceRecords.isEmpty
        ? 0.0
        : attendanceRecords
                  .where((record) => record.status.name == 'presente')
                  .length /
              attendanceRecords.length;
    final cards = [
      InstitutionalKpiCard(
        title: 'TURMAS ATIVAS',
        value: courses.length.toString(),
        subtitle: 'no Semestre',
        footerLabel: 'Discentes Matriculados',
        footerValue: '$enrolledCount alunos',
        progress: courses.isEmpty ? 0 : 1,
      ),
      InstitutionalKpiCard(
        title: 'ATIVIDADES',
        value: assignments.length.toString(),
        subtitle: 'cadastradas',
        footerLabel: 'Avisos acadêmicos',
        footerValue: '${controller.notices.length}',
        progress: assignments.isEmpty ? 0 : 1,
      ),
      InstitutionalKpiCard(
        title: 'CARGA HORÁRIA TOTAL',
        value: '${completedHours}h',
        subtitle: '/ ${totalHours}h',
        footerLabel: 'Cumprimento do Plano',
        footerValue: totalHours == 0
            ? '0%'
            : '${(completedHours / totalHours * 100).toStringAsFixed(1)}%',
        progress: totalHours == 0 ? 0 : completedHours / totalHours,
      ),
      InstitutionalKpiCard(
        title: 'FREQUÊNCIA MÉDIA',
        value: '${(attendanceRate * 100).toStringAsFixed(1)}%',
        subtitle: 'das Turmas',
        footerLabel: 'Situação Geral',
        footerValue: attendanceRecords.isEmpty ? 'Sem registros' : 'Atualizada',
        progress: attendanceRate,
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
}
