// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/docente_diary_attendance_table.dart';
import '../widgets/docente_diary_lesson_plan_card.dart';

/// Aba do diário de classe eletrônico, registro de frequência e homologação MEC.
class DocenteDiaryTab extends StatelessWidget {
  final DocenteController controller;

  const DocenteDiaryTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final session = controller.currentSession;
        final selectedCourse = controller.selectedCourse;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Título & Subtítulo à esquerda, Seletor de Turma à direita
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 20,
                                runSpacing: 14,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Diário de Classe Eletrônico & Registro de Chamada',
                                        style: jakarta(
                                          size: 22,
                                          weight: FontWeight.w700,
                                          color: InstColors.ink,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Registro documental de presença, conteúdo ministrado e controle do teto regimental de faltas.',
                                        style: jakarta(
                                          size: 12.5,
                                          color: InstColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Course Selector Dropdown + Badge de Dias Regimentais
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Turma: ',
                                            style: jakarta(
                                              size: 12,
                                              color: InstColors.muted,
                                              weight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: InstColors.border,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedCourse.id,
                                                icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: InstColors.muted,
                                                ),
                                                onChanged: (newId) {
                                                  if (newId != null) {
                                                    controller.selectCourse(
                                                      newId,
                                                    );
                                                  }
                                                },
                                                items: controller.courses.map((
                                                  course,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: course.id,
                                                    child: Text(
                                                      '${course.code} - ${course.title}',
                                                      style: jakarta(
                                                        size: 12,
                                                        weight:
                                                            FontWeight.w500,
                                                        color: InstColors.ink,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: InstColors.stone,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: InstColors.muted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Dias Letivos: ${selectedCourse.classDaysLabel} (${selectedCourse.schedule})',
                                              style: jakarta(
                                                size: 10.5,
                                                weight: FontWeight.w600,
                                                color: InstColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Card 1: Sessão / Plano de Aula (MEC)
                              DocenteDiaryLessonPlanCard(
                                controller: controller,
                                session: session,
                              ),
                              const SizedBox(height: 24),

                              // Card 2: Tabela de Chamada e Estatísticas
                              DocenteDiaryAttendanceTable(
                                controller: controller,
                                session: session,
                              ),
                              const SizedBox(height: 24),

                              // Card 3: Banner Inferior e Botão de Homologação
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: InstColors.stone,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: InstColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: InstColors.muted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ao homologar o diário, a frequência é consolidada nos servidores acadêmicos e atualizada no portal do discente.',
                                        style: jakarta(
                                          size: 11.5,
                                          color: InstColors.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        controller.homologateSession();
                                        ScaffoldMessenger.of(context)
                                          ..removeCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: InstColors.ink,
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .check_circle_outline_rounded,
                                                    color: InstColors.success,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Aula homologada e presenças consolidadas com sucesso no sistema acadêmico!',
                                                    style: jakarta(size: 12, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                      },
                                      icon: const Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Salvar e Homologar Aula',
                                        style: jakarta(
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: InstColors.ink,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rodapé Institucional Docente
                    const DocenteFooter(
                      padding: EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
