// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';
import '../widgets/docente_diary_attendance_table.dart';
import '../widgets/docente_diary_lesson_plan_card.dart';

/// Aba do diário de classe eletrônico, registro de frequência e homologação MEC.
class DocenteDiaryTab extends StatelessWidget {
  final DocenteController controller;

  const DocenteDiaryTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final session = controller.currentSession;
    final selectedCourse = controller.selectedCourse;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Diário de Classe Eletrônico & Registro de Chamada',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Registro documental de presença, conteúdo ministrado e controle do teto regimental de faltas.',
                style: TextStyle(
                  fontSize: 14,
                  color: DocenteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Course Selector Dropdown
              Row(
                children: [
                  const Text(
                    'Turma: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: DocenteColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DocenteColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCourse.id,
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onChanged: (newId) {
                          if (newId != null) {
                            controller.selectCourse(newId);
                          }
                        },
                        items: controller.courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course.id,
                            child: Text(
                              '${course.code} - ${course.title}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DocenteColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Session Card (MEC requirements)
              DocenteDiaryLessonPlanCard(
                controller: controller,
                session: session,
              ),
              const SizedBox(height: 28),

              // Attendance List Table
              DocenteDiaryAttendanceTable(
                controller: controller,
                session: session,
              ),
              const SizedBox(height: 24),

              // Bottom Actions and Save
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ao homologar o diário, a frequência é consolidada nos servidores acadêmicos e atualizada no portal do discente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: DocenteColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.homologateSession();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: DocenteColors.success,
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Aula homologada e presenças consolidadas com sucesso!',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Salvar e Homologar Aula'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocenteColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
