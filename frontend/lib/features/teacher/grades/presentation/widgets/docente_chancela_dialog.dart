// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Diálogo de homologação da pauta de notas com chancela digital do professor titular.
class DocenteChancelaDialog extends StatelessWidget {
  final DocenteCourse course;
  final VoidCallback onConfirm;

  const DocenteChancelaDialog({
    super.key,
    required this.course,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required DocenteCourse course,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) =>
          DocenteChancelaDialog(course: course, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Homologação com Chancela Digital',
                        style: jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fechamento oficial de notas da disciplina perante a Coordenação',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Resumo da Pauta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryItem(
                    'Disciplina',
                    '${course.code} - ${course.title}',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'Docente Titular',
                    'Profa. Dra. Helena Bittencourt (DOC-88410)',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem('Período Letivo', course.term),
                  const SizedBox(height: 8),
                  _buildSummaryItem(
                    'Total de Alunos',
                    '${course.enrolledCount} matriculados',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Aviso de Lacre Regimental CONSEPE
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ao homologar, a pauta de notas é lacrada digitalmente. Quaisquer alterações futuras exigirão protocolo formal de retificação avaliado pela Coordenação de Curso.',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF71717A),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    'Aplicar Chancela & Homologar',
                    style: jakarta(size: 13, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: jakarta(
            size: 12.5,
            weight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
