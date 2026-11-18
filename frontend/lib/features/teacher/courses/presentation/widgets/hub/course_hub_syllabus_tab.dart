// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de Plano de Ensino real da turma com edição e exportação sincronizada ao aluno.
class CourseHubSyllabusTab extends StatelessWidget {
  final DocenteCourse course;
  final DocenteController controller;

  const CourseHubSyllabusTab({
    super.key,
    required this.course,
    required this.controller,
  });

  Future<void> _exportTxt(BuildContext context) async {
    final buffer = StringBuffer()
      ..writeln('====================================================')
      ..writeln('          AGM-RM • PLANO DE ENSINO REGIMENTAL       ')
      ..writeln('====================================================')
      ..writeln('Disciplina: ${course.title} (${course.code})')
      ..writeln('Semestre/Turno: ${course.term} • ${course.shift}')
      ..writeln('Carga Horária: ${course.totalHours}h')
      ..writeln('Critério de Avaliação: ${course.evaluationFormula}')
      ..writeln('----------------------------------------------------')
      ..writeln('\n1. EMENTA\n${_effectiveSyllabus(course)}')
      ..writeln('\n2. OBJETIVOS\n${_effectiveObjectives(course)}')
      ..writeln('\n3. METODOLOGIA\n${_effectiveMethodology(course)}')
      ..writeln('\n4. UNIDADES CURRICULARES');
    for (final u in course.syllabusUnits) {
      buffer.writeln(
        '  ${u.unitNumber}. ${u.title} (${u.completedClasses}/${u.totalClasses} aulas)',
      );
    }
    if (course.bibliography.isNotEmpty) {
      buffer.writeln('\n5. BIBLIOGRAFIA');
      for (final b in course.bibliography) {
        buffer.writeln(
          '  [${b['type'] ?? 'Básica'}] ${b['authors'] ?? ''}. ${b['title'] ?? ''}',
        );
      }
    }
    final bytes = utf8.encode(buffer.toString());
    final fileName = 'plano_ensino_${course.code.toLowerCase()}.txt';
    await PlatformFileHelper.saveOrDownloadFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/plain',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plano de Ensino ($fileName) exportado.'),
        backgroundColor: const Color(0xFF18181B),
      ),
    );
  }

  String _effectiveSyllabus(DocenteCourse c) => c.syllabus.trim().isNotEmpty
      ? c.syllabus
      : 'Estudo teórico-prático e desenvolvimento aplicado aos fundamentos de ${c.title}.';

  String _effectiveObjectives(DocenteCourse c) => c.objectives.trim().isNotEmpty
      ? c.objectives
      : 'Capacitar os discentes na análise crítica, projeto estruturado e resolução de problemas reais em ${c.title}.';

  String _effectiveMethodology(DocenteCourse c) =>
      c.methodology.trim().isNotEmpty
          ? c.methodology
          : 'Aulas expositivas dialogadas, laboratórios práticos assistidos, entregas avaliativas por rubrica e projeto integrador.';

  Future<void> _openEditPlanModal(BuildContext context) async {
    final syllabusCtrl = TextEditingController(
      text: _effectiveSyllabus(course),
    );
    final objectivesCtrl = TextEditingController(
      text: _effectiveObjectives(course),
    );
    final methodologyCtrl = TextEditingController(
      text: _effectiveMethodology(course),
    );
    final formulaCtrl = TextEditingController(
      text: course.evaluationFormula.isNotEmpty
          ? course.evaluationFormula
          : '(N1 × 0.4) + (N2 × 0.6)',
    );
    var isSaving = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'AUTORIA DOCENTE • ${course.code}',
      title: 'Editar Plano de Ensino',
      subtitle:
          'As alterações são refletidas imediatamente no Programa da Disciplina visto pelos alunos.',
      maxWidth: 660,
      disposeOnClose: [
        syllabusCtrl,
        objectivesCtrl,
        methodologyCtrl,
        formulaCtrl,
      ],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: syllabusCtrl,
              maxLines: 3,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(labelText: 'Ementa Oficial'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: objectivesCtrl,
              maxLines: 3,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Objetivos de Aprendizagem',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: methodologyCtrl,
              maxLines: 2,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Metodologia Didática',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: formulaCtrl,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                labelText: 'Fórmula de Avaliação PPC',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(modalCtx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Salvar Plano de Ensino',
                  icon: Icons.check_rounded,
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          final ok = await controller.updateSyllabusPlan(
                            courseId: course.id,
                            syllabus: syllabusCtrl.text.trim(),
                            objectives: objectivesCtrl.text.trim(),
                            methodology: methodologyCtrl.text.trim(),
                            evaluationFormula: formulaCtrl.text.trim(),
                          );
                          if (!modalCtx.mounted) return;
                          Navigator.of(modalCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Plano de Ensino atualizado e sincronizado.'
                                    : (controller.remoteError ??
                                          'Erro ao salvar plano de ensino.'),
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'DOCUMENTO CURRICULAR • ${course.code}',
          title: 'Plano de Ensino e Ementa',
          subtitle:
              'Conteúdo sincronizado diretamente com a aba Programa da Disciplina no AVA dos discentes.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourseHubPillButton(
                label: 'Exportar (.txt)',
                icon: Icons.download_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => _exportTxt(context),
              ),
              CourseHubPillButton(
                label: 'Editar Plano',
                icon: Icons.edit_outlined,
                compact: true,
                onPressed: () => _openEditPlanModal(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        CourseHubSurfaceCard(
          overlineTag: 'EMENTA DO COMPONENTE CURRICULAR',
          title: course.title,
          subtitle: 'Carga horária total: ${course.totalHours}h • ${course.term}',
          child: Text(
            _effectiveSyllabus(course),
            style: jakarta(size: 13.5, color: const Color(0xFF3F3F46), height: 1.5),
          ),
        ),
        const SizedBox(height: 16),

        CourseHubSurfaceCard(
          overlineTag: 'DIRETRIZES PEDAGÓGICAS',
          title: 'Objetivos & Metodologia',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Objetivos de Aprendizagem',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _effectiveObjectives(course),
                style: jakarta(
                  size: 13,
                  color: const Color(0xFF52525B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 14),
              Text(
                'Metodologia Didática',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _effectiveMethodology(course),
                style: jakarta(
                  size: 13,
                  color: const Color(0xFF52525B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CourseHubSurfaceCard(
          overlineTag: 'REGIMENTO E CRITÉRIOS DE APROVAÇÃO',
          title: 'Critérios de Avaliação PPC',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fórmula: ${course.evaluationFormula.isEmpty ? "(N1 × 0.4) + (N2 × 0.6)" : course.evaluationFormula}',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nota mínima para aprovação direta: 6.0 • Exame: 4.0 a 5.9 • Frequência mínima regimental: 75%.',
                      style: jakarta(size: 12.5, color: const Color(0xFF52525B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (course.bibliography.isNotEmpty) ...[
          const SizedBox(height: 16),
          CourseHubSurfaceCard(
            overlineTag: 'REFERÊNCIAS BIBLIOGRÁFICAS',
            title: 'Bibliografia Recomendada (${course.bibliography.length})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < course.bibliography.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 14, color: Color(0xFFF4F4F5)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CourseHubBadge(
                        label: (course.bibliography[i]['type'] ?? 'Básica')
                            .toString(),
                        tone: CourseHubBadgeTone.neutral,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${course.bibliography[i]['authors'] ?? ''} — ${course.bibliography[i]['title'] ?? ''}',
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF3F3F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
