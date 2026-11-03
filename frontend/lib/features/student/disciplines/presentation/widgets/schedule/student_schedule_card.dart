// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Card com o Quadro Semanal de Horários & Laboratórios (Ensalamento Físico)
class StudentScheduleCard extends StatelessWidget {
  final void Function(String code, [int tab])? onSelectDisciplineByCode;

  const StudentScheduleCard({super.key, this.onSelectDisciplineByCode});

  @override
  Widget build(BuildContext context) {
    final scheduleItems = StudentPortalController.instance.disciplines
        .map(
          (discipline) => {
            'dia': discipline.schedule,
            'hora': discipline.time,
            'disciplina': discipline.name,
            'codigo': discipline.code,
            'local': '${discipline.location} • ${discipline.professor}',
            'tipo': discipline.isLab ? 'Laboratório' : 'Aula',
          },
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quadro Semanal de Horários & Laboratórios',
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Horários e locais das disciplinas matriculadas.',
                      style: jakarta(
                        size: 11.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${StudentPortalController.instance.studentInfo['semester'] ?? 'Semestre não informado'}',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF52525B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          for (int i = 0; i < scheduleItems.length; i++) ...[
            InkWell(
              onTap: () {
                final code = scheduleItems[i]['codigo']!;
                if (code == 'MONITORIA') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A sala de videochamada da monitoria ainda não está vinculada a uma turma.',
                      ),
                    ),
                  );
                } else if (onSelectDisciplineByCode != null) {
                  onSelectDisciplineByCode!(code, 0);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheduleItems[i]['dia']!,
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scheduleItems[i]['hora']!,
                            style: jakarta(
                              size: 11,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  scheduleItems[i]['disciplina']!,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  scheduleItems[i]['codigo']!,
                                  style: jakarta(
                                    size: 10,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            scheduleItems[i]['local']!,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(
                              size: 11.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheduleItems[i]['tipo']!,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w500,
                          color: const Color(0xFF52525B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < scheduleItems.length - 1)
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
          ],
        ],
      ),
    );
  }
}
