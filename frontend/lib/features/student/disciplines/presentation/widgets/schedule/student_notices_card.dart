// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card do Mural de Avisos & Comunicados Docentes
class StudentNoticesCard extends StatelessWidget {
  const StudentNoticesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = [
      {
        'tag': 'APS-II',
        'author': 'Profa. Dra. Helena Bittencourt',
        'time': 'Há 2 horas',
        'title': 'Orientações para o Sprint 1 e Modelagem de Domínio',
        'body':
            'Lembrem-se de que os diagramas de classes devem contemplar todas as multiplicidades e a rastreabilidade com os casos de uso do Projeto Integrador. Gabarito conceitual disponível na aba de arquivos.',
      },
      {
        'tag': 'BD-II',
        'author': 'Profa. Dra. Helena Bittencourt',
        'time': 'Ontem',
        'title': 'Scripts de Carga e EXPLAIN ANALYZE no PostgreSQL',
        'body':
            'Os scripts de povoamento da base de testes para a prática de planos de execução já estão disponíveis no repositório da disciplina. Usem o ambiente Docker homologado.',
      },
      {
        'tag': 'FSO',
        'author': 'Prof. Esp. André Luiz Silveira',
        'time': '2 dias atrás',
        'title': 'Instalação das Máquinas Virtuais para Prática de Semáforos',
        'body':
            'Todos os alunos devem conferir o acesso à imagem Linux do laboratório para o exercício de sincronização entre processos na próxima quinta-feira.',
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
                      'Mural de Avisos & Comunicados Docentes',
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orientações recentes publicadas pelos professores das suas disciplinas.',
                      style: jakarta(
                        size: 11.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '3 avisos',
                style: jakarta(
                  size: 11,
                  color: const Color(0xFF71717A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          for (int i = 0; i < notices.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                notices[i]['tag']!,
                                style: jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notices[i]['author']!,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(
                                  size: 11.5,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notices[i]['time']!,
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notices[i]['title']!,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notices[i]['body']!,
                    style: jakarta(
                      size: 11.5,
                      color: const Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (i < notices.length - 1)
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
          ],
        ],
      ),
    );
  }
}
