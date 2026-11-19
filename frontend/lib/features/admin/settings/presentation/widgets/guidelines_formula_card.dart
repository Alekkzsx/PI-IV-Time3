// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card descritivo da fórmula de ponderação regimental e órgão deliberador.
class GuidelinesFormulaCard extends StatelessWidget {
  final TextEditingController formulaController;
  final TextEditingController? resolutionController;
  final String lastUpdatedLabel;

  const GuidelinesFormulaCard({
    super.key,
    required this.formulaController,
    this.resolutionController,
    this.lastUpdatedLabel = 'Aguardando sincronização',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: InstColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InstColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descrição da Fórmula Regimental e Ponderação',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Parâmetro exibido para os professores no diário de notas e para os alunos na consulta de rendimento.',
                style: jakarta(size: 12, color: InstColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formulaController,
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w500,
                  color: InstColors.ink,
                ),
                decoration: InstText.inputDecoration(
                  hintText: 'Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)',
                ).copyWith(fillColor: InstColors.stone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final resolutionCard = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstColors.stone,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: InstColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: InstColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolução / Órgão Deliberador',
                          style: jakarta(size: 11, color: InstColors.muted),
                        ),
                        const SizedBox(height: 4),
                        if (resolutionController != null)
                          TextField(
                            controller: resolutionController,
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: InstColors.ink,
                            ),
                            decoration: InstText.inputDecoration(
                              hintText: 'RESOLUÇÃO CONSEPE 2026/04',
                            ),
                          )
                        else
                          Text(
                            'RESOLUÇÃO CONSEPE 2026/04',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: InstColors.ink,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            final updatedCard = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstColors.stone,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: InstColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: InstColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Última Homologação Registrada',
                          style: jakarta(size: 11, color: InstColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastUpdatedLabel,
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w700,
                            color: InstColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            return isNarrow
                ? Column(
                    children: [
                      resolutionCard,
                      const SizedBox(height: 12),
                      updatedCard,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: resolutionCard),
                      const SizedBox(width: 16),
                      Expanded(child: updatedCard),
                    ],
                  );
          },
        ),
      ],
    );
  }
}
