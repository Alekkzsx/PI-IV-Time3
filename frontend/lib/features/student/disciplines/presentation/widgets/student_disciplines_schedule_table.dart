// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/student_academic_support_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/student_notices_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/student_schedule_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/student_upcoming_deliveries_card.dart';

/// Painéis inferiores da tela de Minhas Disciplinas:
/// - Quadro Semanal de Horários & Laboratórios (Ensalamento Físico)
/// - Próximas Avaliações & Entregas
/// - Mural de Avisos & Comunicados Docentes
/// - Apoio Acadêmico & Recursos Oficiais
class StudentDisciplinesScheduleTable extends StatelessWidget {
  final void Function(String code, [int tab])? onSelectDisciplineByCode;

  const StudentDisciplinesScheduleTable({
    super.key,
    this.onSelectDisciplineByCode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: StudentScheduleCard(
                      onSelectDisciplineByCode: onSelectDisciplineByCode,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: StudentUpcomingDeliveriesCard(
                      onSelectDisciplineByCode: onSelectDisciplineByCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    flex: 6,
                    child: StudentNoticesCard(),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: StudentAcademicSupportCard(),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            StudentScheduleCard(
              onSelectDisciplineByCode: onSelectDisciplineByCode,
            ),
            const SizedBox(height: 20),
            StudentUpcomingDeliveriesCard(
              onSelectDisciplineByCode: onSelectDisciplineByCode,
            ),
            const SizedBox(height: 20),
            const StudentNoticesCard(),
            const SizedBox(height: 20),
            const StudentAcademicSupportCard(),
          ],
        );
      },
    );
  }
}
