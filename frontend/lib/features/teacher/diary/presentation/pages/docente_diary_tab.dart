// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
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
                                    children: const [
                                      Text(
                                        'Diário de Classe Eletrônico & Registro de Chamada',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF09090B),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Registro documental de presença, conteúdo ministrado e controle do teto regimental de faltas.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF71717A),
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
                                          const Text(
                                            'Turma: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF71717A),
                                              fontWeight: FontWeight.w500,
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
                                                color: const Color(0xFFE4E4E7),
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedCourse.id,
                                                icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: Color(0xFF71717A),
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
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color(
                                                          0xFF18181B,
                                                        ),
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
                                          color: const Color(0xFFF4F4F5),
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
                                              color: Color(0xFF71717A),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Dias Letivos: ${selectedCourse.classDaysLabel} (${selectedCourse.schedule})',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF71717A),
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
                                  color: const Color(0xFFFBFBFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE4E4E7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Color(0xFF71717A),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Ao homologar o diário, a frequência é consolidada nos servidores acadêmicos e atualizada no portal do discente.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF71717A),
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
                                            const SnackBar(
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Color(
                                                0xFF18181B,
                                              ),
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .check_circle_outline_rounded,
                                                    color: Color(0xFF22C55E),
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Aula homologada e presenças consolidadas com sucesso no sistema acadêmico!',
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
                                      label: const Text(
                                        'Salvar e Homologar Aula',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF18181B,
                                        ),
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
