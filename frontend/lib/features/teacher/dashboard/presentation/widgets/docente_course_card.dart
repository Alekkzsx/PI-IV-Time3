// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Card individual de disciplina na visão docente - Pixel-perfect fiel ao PDF
// Chip código + "Sala de Aula AVA" + progresso + "Autoria & Edição habilitadas"

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Card institucional representando uma turma ativa do docente no Painel Geral.
/// Fiel ao PDF:
/// - Chip com código da turma (ex: 218131-APS-II)
/// - Link "Sala de Aula AVA" com ícone sparkle
/// - Nome da disciplina
/// - Turno + discentes
/// - "Progresso do Plano" + barra de progresso
/// - "Autoria & Edição habilitadas" + "Acessar →"
class DocenteCourseCard extends StatefulWidget {
  final DocenteCourse course;
  final VoidCallback onOpenCourseHub;

  const DocenteCourseCard({
    super.key,
    required this.course,
    required this.onOpenCourseHub,
  });

  @override
  State<DocenteCourseCard> createState() => _DocenteCourseCardState();
}

class _DocenteCourseCardState extends State<DocenteCourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final progress = (course.progressPercentage / 100).clamp(0.0, 1.0);
    final progressPct = course.progressPercentage.round();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: InstColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? InstColors.borderStrong : InstColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.04 : 0.015),
              blurRadius: _isHovered ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // Linha 1: Chip código + "Sala de Aula AVA"
            // ═══════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Chip código da turma
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    course.code,
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ),

                // Link "Sala de Aula AVA"
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onOpenCourseHub,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: InstColors.success,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sala de Aula AVA',
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: InstColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ═══════════════════════════════════════════
            // Título da Disciplina
            // ═══════════════════════════════════════════
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 15.5,
                weight: FontWeight.w700,
                color: InstColors.ink,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),

            // Turno e quantidade de discentes
            Text(
              '${course.shift} • ${course.enrolledCount} discentes',
              style: jakarta(
                size: 12,
                color: InstColors.muted,
              ),
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════════
            // Progresso do Plano
            // ═══════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso do Plano',
                  style: jakarta(
                    size: 11.5,
                    color: InstColors.muted,
                  ),
                ),
                Text(
                  '$progressPct%',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFF4F4F5),
                valueColor: const AlwaysStoppedAnimation<Color>(InstColors.ink),
              ),
            ),
            const SizedBox(height: 18),

            // ═══════════════════════════════════════════
            // Rodapé: "Autoria & Edição" + "Acessar →"
            // ═══════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Autoria & Edição habilitadas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w600,
                      color: InstColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onOpenCourseHub,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.only(right: _isHovered ? 0 : 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Acessar',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w600,
                              color: InstColors.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: InstColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
