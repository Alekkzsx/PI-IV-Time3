// Desenvolvido por Murillo Caravita - RA: 25014012, Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Painel Geral do Portal Docente redesenhado com fidelidade estrita à imagem de referência

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/docente_assessment_preview_card.dart';
import '../widgets/docente_courses_preview_section.dart';
import '../widgets/docente_notices_preview_card.dart';
import '../widgets/docente_requirements_card.dart';

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
        final isDesktop = constraints.maxWidth >= 1050;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 28 : 20,
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coluna Esquerda: Minhas Turmas e Requerimentos
                            Expanded(
                              flex: 65,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DocenteCoursesPreviewSection(
                                    controller: controller,
                                    onOpenCourseHub: onOpenCourseHub,
                                  ),
                                  const SizedBox(height: 24),
                                  DocenteRequirementsCard(
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Coluna Direita: Avaliação Imediata e Mensagens & Avisos
                            Expanded(
                              flex: 35,
                              child: Column(
                                children: [
                                  DocenteAssessmentPreviewCard(
                                    controller: controller,
                                  ),
                                  const SizedBox(height: 20),
                                  DocenteNoticesPreviewCard(
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DocenteAssessmentPreviewCard(
                              controller: controller,
                            ),
                            const SizedBox(height: 20),
                            DocenteCoursesPreviewSection(
                              controller: controller,
                              onOpenCourseHub: onOpenCourseHub,
                            ),
                            const SizedBox(height: 20),
                            DocenteRequirementsCard(
                              controller: controller,
                            ),
                            const SizedBox(height: 20),
                            DocenteNoticesPreviewCard(
                              controller: controller,
                            ),
                          ],
                        ),
                ),

                // Rodapé Institucional Reutilizável
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
}
