// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card com o Quadro Semanal de Horários & Laboratórios (Ensalamento Físico)
class StudentScheduleCard extends StatelessWidget {
  final void Function(String code, [int tab])? onSelectDisciplineByCode;

  const StudentScheduleCard({
    super.key,
    this.onSelectDisciplineByCode,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleItems = [
      {
        'dia': 'Segunda-feira',
        'hora': '19:00 - 22:30',
        'disciplina': 'Análise e Projeto de Sistemas II',
        'codigo': 'APS-II',
        'local': 'Lab 04 - Bloco C • Profa. Helena Bittencourt',
        'tipo': 'Laboratório Prático',
      },
      {
        'dia': 'Terça-feira',
        'hora': '19:00 - 22:30',
        'disciplina': 'Estudos de Banco de Dados II',
        'codigo': 'BD-II',
        'local': 'Lab 02 - Bloco B • Profa. Helena Bittencourt',
        'tipo': 'Laboratório Prático',
      },
      {
        'dia': 'Quarta-feira',
        'hora': '19:00 - 21:00',
        'disciplina': 'Filosofia, Informação e Sociedade',
        'codigo': 'FIS',
        'local': 'Sala 204 - Bloco A • Prof. Marcos Vinícius',
        'tipo': 'Teórica & Debates',
      },
      {
        'dia': 'Quinta-feira',
        'hora': '19:00 - 22:30',
        'disciplina': 'Fundamentos de Sistemas Operacionais',
        'codigo': 'FSO',
        'local': 'Anfiteatro 101 - Bloco Central • Prof. André Luiz Silveira',
        'tipo': 'Teórica & Demonstração',
      },
      {
        'dia': 'Sexta-feira',
        'hora': '18:30 - 20:30',
        'disciplina': 'Plantão Orientado de Dúvidas & Monitoria',
        'codigo': 'MONITORIA',
        'local': 'Lab 04 & Microsoft Teams • Monitores Discentes',
        'tipo': 'Atendimento Orientado',
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
                      'Grade de encontros presenciais das 4 disciplinas no Bloco Central e Labs.',
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
                  'Semestre 2026/2',
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
                  Navigator.of(context).pushNamed('/video-call');
                } else if (onSelectDisciplineByCode != null) {
                  onSelectDisciplineByCode!(code, 0);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
