// Desenvolvido por Guilherme Henrique Moreira e Rafael Henrique Inácio - RA: 25009719
// Card de Próxima Avaliação/Prazo Imediato da coluna direita do Painel Geral

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

/// Card de destaque para a próxima avaliação ou prazo acadêmico imediato.
class DocenteAssessmentPreviewCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteAssessmentPreviewCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avaliação Parcial: Gerenciamento de Memória',
            style: jakarta(
              size: 14.5,
              weight: FontWeight.w700,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fundamentos de Sistemas Operacionais',
            style: jakarta(
              size: 12.5,
              color: InstColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: InstColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                'Terça, 29/09 às 20:40',
                style: jakarta(
                  size: 12,
                  color: InstColors.muted,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
