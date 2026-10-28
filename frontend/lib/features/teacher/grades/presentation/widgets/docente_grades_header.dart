// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_chancela_dialog.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_retificacao_dialog.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Cabeçalho da aba de Livro de Notas do Docente com seletor de curso e ação de ata
class DocenteGradesHeader extends StatelessWidget {
  final DocenteController controller;
  final DocenteCourse selectedCourse;

  const DocenteGradesHeader({
    super.key,
    required this.controller,
    required this.selectedCourse,
  });

  @override
  Widget build(BuildContext context) {
    final isHomologada = controller.isPautaHomologada(selectedCourse.id);

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Livro de Notas & Gradebook Oficial',
          style: jakarta(
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consolidação de avaliações, cálculo automatizado de médias pelo PPC e emissão de atas.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        // Status de Chancela / Homologação
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isHomologada
                ? const Color(0xFFECFDF5)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHomologada
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHomologada ? Icons.lock_rounded : Icons.edit_note_rounded,
                size: 14,
                color: isHomologada
                    ? const Color(0xFF047857)
                    : const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 6),
              Text(
                isHomologada
                    ? 'Chancela Ativa: ${controller.getChancelaCode(selectedCourse.id) ?? "Homologada"}'
                    : 'Pauta Aberta para Digitação',
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: isHomologada
                      ? const Color(0xFF047857)
                      : const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        ),

        // Dropdown Seletor de Disciplina
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            width: 240,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCourse.id,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF71717A),
                ),
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
                onChanged: (newCourseId) {
                  if (newCourseId != null) {
                    controller.selectCourse(newCourseId);
                  }
                },
                items: controller.courses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course.id,
                    child: SizedBox(
                      width: 220,
                      child: Text(
                        '${course.code} - ${course.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Botão Chancela Digital ou Retificação
        if (!isHomologada)
          ElevatedButton.icon(
            onPressed: () {
              DocenteChancelaDialog.show(
                context: context,
                course: selectedCourse,
                onConfirm: () {
                  controller.homologarPautaComChancela(selectedCourse.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pauta da disciplina ${selectedCourse.title} homologada com chancela digital.',
                        style: jakarta(size: 13, color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF047857),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.verified_outlined,
              size: 15,
              color: Colors.white,
            ),
            label: Text(
              'Homologar com Chancela Digital',
              style: jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              DocenteRetificacaoDialog.show(
                context: context,
                course: selectedCourse,
                gradebook: controller.gradebook,
                onConfirm:
                    ({
                      required String studentRa,
                      required String studentName,
                      required String avaliacao,
                      required double notaAnterior,
                      required double novaNota,
                      required String justificativa,
                    }) {
                      controller.solicitarRetificacaoNota(
                        courseId: selectedCourse.id,
                        studentRa: studentRa,
                        studentName: studentName,
                        avaliacao: avaliacao,
                        notaAnterior: notaAnterior,
                        novaNota: novaNota,
                        justificativa: justificativa,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Solicitação de retificação enviada para a Coordenação de Curso com sucesso.',
                            style: jakarta(size: 13, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFFD97706),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              );
            },
            icon: const Icon(
              Icons.edit_note_rounded,
              size: 16,
              color: Color(0xFFD97706),
            ),
            label: Text(
              'Solicitar Retificação à Coordenação',
              style: jakarta(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        // Botão Emitir Ata da Turma
        OutlinedButton.icon(
          onPressed: () {
            final chancela = controller.getChancelaCode(selectedCourse.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  chancela != null
                      ? 'Ata Oficial gerada com Chancela Digital $chancela.'
                      : 'Ata Provisória gerada para conferência.',
                  style: jakarta(size: 13, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(
            Icons.description_outlined,
            size: 15,
            color: Color(0xFF18181B),
          ),
          label: Text(
            'Emitir Ata da Turma',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w500,
              color: const Color(0xFF18181B),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF18181B),
            side: const BorderSide(color: Color(0xFFD4D4D8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 16), actions],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            actions,
          ],
        );
      },
    );
  }
}
