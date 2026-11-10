// Componente atômico para cabeçalho regulatório MEC do plano de aula docente

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/attendance_record.dart';

class LessonPlanMecHeader extends StatelessWidget {
  final ClassSession session;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenSessionPicker;
  final VoidCallback onOpenCalendarPicker;

  const LessonPlanMecHeader({
    super.key,
    required this.session,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenSessionPicker,
    required this.onOpenCalendarPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: 'Ver todas as aulas da turma',
                child: InkWell(
                  onTap: onOpenSessionPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AULA Nº ${session.sessionNumber} • CARGA: ${session.hours}H/AULA',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: canGoPrevious ? onPrevious : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: canGoPrevious
                                  ? const Color(0xFFF4F4F5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: canGoPrevious
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFFD4D4D8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: canGoNext ? onNext : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: canGoNext
                                  ? const Color(0xFFF4F4F5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: canGoNext
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFFD4D4D8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          session.dateFormatted,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        InkWell(
                          onTap: onOpenSessionPicker,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE4E4E7),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Trocar Aula',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF18181B),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 12,
                                  color: Color(0xFF18181B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenCalendarPicker,
              icon: const Icon(
                Icons.calendar_month,
                size: 13,
                color: Color(0xFF18181B),
              ),
              label: const Text(
                'Selecionar Data',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: session.isHomologated
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: session.isHomologated
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                session.isHomologated
                    ? 'Homologado no Sistema'
                    : 'Aguardando Homologação',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: session.isHomologated
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
