// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Banner descritivo da Fórmula Regimental de Avaliação (PPC) com critérios de aprovação
class DocenteGradesFormulaBanner extends StatelessWidget {
  const DocenteGradesFormulaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF4F4F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF52525B),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fórmula Regimental de Avaliação (PPC da Disciplina)',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Média Semestral = (N1 x 0.4) + (N2 x 0.6) • Onde N1 e N2 são compostas por: 40% Atividades/Entregas + 60% Provas Regimentais.',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCriteriaBadge(
                'Aprovação Direta: Média ≥ 7.0 e Freq. ≥ 75%',
                const Color(0xFF16A34A),
              ),
              _buildCriteriaBadge(
                'Exame: 4.0 ≤ Média < 7.0',
                const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Text(
        label,
        style: jakarta(size: 11, weight: FontWeight.w600, color: color),
      ),
    );
  }
}
