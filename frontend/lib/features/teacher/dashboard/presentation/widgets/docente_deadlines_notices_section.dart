// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Coluna direita do Painel Geral do Docente com Avaliação e Avisos

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'docente_assessment_preview_card.dart';
import 'docente_notices_preview_card.dart';

/// Seção da coluna direita contendo a próxima avaliação e as mensagens/avisos.
class DocenteDeadlinesNoticesSection extends StatelessWidget {
  final DocenteController controller;

  const DocenteDeadlinesNoticesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DocenteAssessmentPreviewCard(controller: controller),
        const SizedBox(height: 20),
        DocenteNoticesPreviewCard(controller: controller),
      ],
    );
  }
}
