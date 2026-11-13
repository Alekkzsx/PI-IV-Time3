// Desenvolvido por Murillo Caravita - RA: 25014012, Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Painel Geral do Portal Docente - Padrão estético fiel às telas de referência
// Dados 100% tratados e agregados no backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/docente_stats_cards_row.dart';
import '../widgets/docente_live_class_card.dart';
import '../widgets/docente_courses_preview_section.dart';
import '../widgets/docente_requirements_card.dart';
import '../widgets/docente_assessment_preview_card.dart';
import '../widgets/docente_notices_preview_card.dart';

/// Visão principal do Painel Geral do Portal Docente.
/// Segue exatamente o mesmo padrão estético e layout de 2 colunas das referências.
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
        final isDesktop = constraints.maxWidth >= 1024;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 28 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HERO: Saudação + Departamento + Semestre
                      _buildHeroSection(),
                      const SizedBox(height: 28),

                      // 2. CARDS DE ESTATÍSTICAS (4 KPIs)
                      DocenteStatsCardsRow(controller: controller),
                      const SizedBox(height: 32),

                      // 3. LAYOUT DE DUAS COLUNAS ASSIMÉTRICAS (Desktop)
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coluna Esquerda: Aula do Dia + Minhas Turmas + Requerimentos Acadêmicos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DocenteLiveClassCard(
                                    controller: controller,
                                    onOpenVideoCall: onOpenVideoCall,
                                    onOpenCourseHub: onOpenCourseHub,
                                  ),
                                  const SizedBox(height: 36),
                                  DocenteCoursesPreviewSection(
                                    controller: controller,
                                    onOpenCourseHub: onOpenCourseHub,
                                  ),
                                  const SizedBox(height: 36),
                                  DocenteRequirementsCard(
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 28),

                            // Coluna Direita: Prazos e Entregas + Mensagens e Avisos
                            SizedBox(
                              width: 380,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DocenteAssessmentPreviewCard(
                                    controller: controller,
                                  ),
                                  const SizedBox(height: 24),
                                  DocenteNoticesPreviewCard(
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DocenteLiveClassCard(
                              controller: controller,
                              onOpenVideoCall: onOpenVideoCall,
                              onOpenCourseHub: onOpenCourseHub,
                            ),
                            const SizedBox(height: 24),
                            DocenteAssessmentPreviewCard(
                              controller: controller,
                            ),
                            const SizedBox(height: 28),
                            DocenteCoursesPreviewSection(
                              controller: controller,
                              onOpenCourseHub: onOpenCourseHub,
                            ),
                            const SizedBox(height: 28),
                            DocenteNoticesPreviewCard(controller: controller),
                            const SizedBox(height: 28),
                            DocenteRequirementsCard(controller: controller),
                          ],
                        ),
                    ],
                  ),
                ),

                // RODAPÉ INSTITUCIONAL
                DocenteFooter(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    final hero = controller.dashboard.hero;
    final greetingPrefix = hero.greetingPrefix;
    final firstName = hero.firstName;
    final department = hero.department;
    final semester = hero.semester;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greetingPrefix $firstName.',
          style: jakarta(
            size: 34,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              department,
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFD4D4D8),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              semester,
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
