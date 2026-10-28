// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/student_sidebar.dart';

/// Card de Próximas Avaliações & Entregas
class StudentUpcomingDeliveriesCard extends StatelessWidget {
  final void Function(String code, [int tab])? onSelectDisciplineByCode;

  const StudentUpcomingDeliveriesCard({
    super.key,
    this.onSelectDisciplineByCode,
  });

  @override
  Widget build(BuildContext context) {
    final deliveries = [
      {
        'code': 'APS-II',
        'peso': '25% da N2',
        'titulo': 'Sprint 1: Diagramas de Classes e Sequência do AVA',
        'data': 'Hoje às 23:59',
        'isUrgent': true,
      },
      {
        'code': 'BD-II',
        'peso': '20% da N2',
        'titulo': 'Lista Prática 02: Normalização Formal e BCNF',
        'data': 'Amanhã às 23:59',
        'isUrgent': false,
      },
      {
        'code': 'FIS',
        'peso': '30% da N2',
        'titulo': 'Seminário: Soberania de Dados e LGPD na IA',
        'data': '08 Out às 19:00',
        'isUrgent': false,
      },
      {
        'code': 'FSO',
        'peso': '20% da N2',
        'titulo': 'Relatório: Simulação de Escalonamento Round-Robin',
        'data': '15 Out às 23:59',
        'isUrgent': false,
      },
    ];

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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximas Avaliações & Entregas',
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prazos e entregas acadêmicas das 4 disciplinas.',
                      style: jakarta(
                        size: 11.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const Key('btn_ver_calendario_disciplinas'),
                onTap: () => StudentPortalController.instance.setNavItem(StudentNavItem.calendario),
                child: Row(
                  children: [
                    Text(
                      'Ver Calendário',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF18181B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          for (int i = 0; i < deliveries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                deliveries[i]['code'] as String,
                                style: jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              deliveries[i]['peso'] as String,
                              style: jakarta(
                                size: 10.5,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveries[i]['titulo'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          deliveries[i]['data'] as String,
                          style: jakarta(
                            size: 11,
                            weight: (deliveries[i]['isUrgent'] as bool) ? FontWeight.w700 : FontWeight.w400,
                            color: (deliveries[i]['isUrgent'] as bool)
                                ? const Color(0xFFD97706)
                                : const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (onSelectDisciplineByCode != null) {
                        onSelectDisciplineByCode!(deliveries[i]['code'] as String, 1);
                      } else {
                        StudentPortalController.instance.setNavItem(StudentNavItem.entregas);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Acessar',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < deliveries.length - 1)
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
          ],
        ],
      ),
    );
  }
}
