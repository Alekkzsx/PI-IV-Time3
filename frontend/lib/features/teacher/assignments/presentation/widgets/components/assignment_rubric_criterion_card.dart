// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card atômico para edição de um critério avaliativo individual na matriz de rubrica.
class AssignmentRubricCriterionCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController pointsController;
  final TextEditingController descController;
  final VoidCallback? onRemove;
  final VoidCallback onPointsChanged;

  const AssignmentRubricCriterionCard({
    super.key,
    required this.titleController,
    required this.pointsController,
    required this.descController,
    this.onRemove,
    required this.onPointsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Nome do Critério
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome do critério',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: titleController,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(0xFF18181B),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF18181B),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Pontos
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pontos',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(0xFF18181B),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        suffixText: 'pts',
                        suffixStyle: jakarta(
                          size: 12,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF18181B),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => onPointsChanged(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botão Remover
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFDC2626),
                  tooltip: 'Remover critério',
                  splashRadius: 18,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Descrição do que é esperado
          Text(
            'Descrição do que é esperado para pontuação máxima',
            style: jakarta(
              size: 11,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: descController,
            style: jakarta(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF18181B),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF18181B), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
