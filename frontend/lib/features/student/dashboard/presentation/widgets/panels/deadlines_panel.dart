// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/navigation/portal_sidebar.dart';

/// [StudentDeadlineItemData]
///
/// Objeto imutável que encapsula os metadados de exibição de um prazo iminente de atividade.
class StudentDeadlineItemData {
  /// Título da atividade avaliativa ou entrega.
  final String title;

  /// Nome ou sigla da disciplina associada.
  final String discipline;

  /// Data e horário estipulados para a entrega.
  final String due;

  /// Flag que destaca o prazo como urgente quando restam poucas horas.
  final bool isUrgent;

  /// Cria uma nova instância de [StudentDeadlineItemData].
  const StudentDeadlineItemData(
    this.title,
    this.discipline,
    this.due, {
    this.isUrgent = false,
  });
}

/// [DeadlinesPanel]
///
/// Painel lateral de "Prazos Iminentes" que lista as entregas acadêmicas mais próximas,
/// com atalho de redirecionamento direto para a visualização completa do Calendário.
class DeadlinesPanel extends StatelessWidget {
  /// Controlador do portal para roteamento de navegação.
  final StudentPortalController controller;

  /// Lista de prazos formatados para apresentação visual.
  final List<StudentDeadlineItemData> deadlines;

  /// Cria uma nova instância de [DeadlinesPanel].
  const DeadlinesPanel({
    super.key,
    required this.controller,
    required this.deadlines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prazos Pendentes',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${deadlines.length}',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),
          for (final d in deadlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 52,
                    decoration: BoxDecoration(
                      color: d.isUrgent
                          ? const Color(0xFF18181B)
                          : const Color(0xFFE4E4E7),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
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
                          d.discipline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFFA1A1AA),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              d.due,
                              style: jakarta(
                                size: 10.5,
                                color: const Color(0xFF71717A),
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
          const SizedBox(height: 4),
          OutlinedButton(
            key: const Key('btn_abrir_calendario'),
            onPressed: () => controller.setNavItem(StudentNavItem.calendario),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFAFAFA),
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                'Abrir Calendário',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


typedef StudentDeadlinesPanel = DeadlinesPanel;
