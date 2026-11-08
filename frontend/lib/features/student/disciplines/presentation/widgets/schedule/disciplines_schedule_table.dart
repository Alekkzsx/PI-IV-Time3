// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/academic_support_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/discipline_notices_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/schedule_card.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/schedule/upcoming_deliveries_card.dart';

/// [DisciplinesScheduleTable]
///
/// Componente orquestrador dos painéis complementares da tela de Disciplinas.
/// Agrupa de forma responsiva o quadro semanal de horários [ScheduleCard],
/// próximas entregas [UpcomingDeliveriesCard], mural de avisos [DisciplineNoticesCard]
/// e suporte acadêmico institucional [AcademicSupportCard].
class DisciplinesScheduleTable extends StatelessWidget {
  /// Callback para navegação direta ao selecionar uma disciplina nos subcomponentes.
  final void Function(String code, [int tab])? onSelectDisciplineByCode;

  /// Cria uma nova instância de [DisciplinesScheduleTable].
  const DisciplinesScheduleTable({
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


typedef StudentDisciplinesScheduleTable = DisciplinesScheduleTable;
