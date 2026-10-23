// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';

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
                  Expanded(flex: 6, child: _buildScheduleCard(context)),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildUpcomingDeliveriesCard(context)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildNoticesCard(context)),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: _buildAcademicSupportCard(context)),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildScheduleCard(context),
            const SizedBox(height: 20),
            _buildUpcomingDeliveriesCard(context),
            const SizedBox(height: 20),
            _buildNoticesCard(context),
            const SizedBox(height: 20),
            _buildAcademicSupportCard(context),
          ],
        );
      },
    );
  }

  // ==========================================
  // QUADRO SEMANAL DE HORÁRIOS & LABORATÓRIOS
  // ==========================================
  Widget _buildScheduleCard(BuildContext context) {
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

  // ==========================================
  // PRÓXIMAS AVALIAÇÕES & ENTREGAS
  // ==========================================
  Widget _buildUpcomingDeliveriesCard(BuildContext context) {
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

  // ==========================================
  // MURAL DE AVISOS & COMUNICADOS DOCENTES
  // ==========================================
  Widget _buildNoticesCard(BuildContext context) {
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

  // ==========================================
  // APOIO ACADÊMICO & RECURSOS OFICIAIS
  // ==========================================
  Widget _buildAcademicSupportCard(BuildContext context) {
    final resources = [
      {
        'icon': Icons.menu_book_outlined,
        'title': 'Biblioteca Virtual Universitária',
        'desc': 'Mais de 15.000 títulos técnicos Pearson & Minha Biblioteca',
        'isDownload': false,
      },
      {
        'icon': Icons.laptop_chromebook_rounded,
        'title': 'Laboratórios Virtuais & Docker',
        'desc': 'Ambientes conteinerizados de PostgreSQL e Linux',
        'isDownload': false,
      },
      {
        'icon': Icons.people_outline_rounded,
        'title': 'Monitoria & Nivelamento',
        'desc': 'Plantões com discentes bolsistas de Seg a Sex',
        'isDownload': false,
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Templates Oficiais ABNT & TCC',
        'desc': 'Modelos LaTeX e Word aprovados pelo Colegiado',
        'isDownload': true,
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
          Text(
            'Apoio Acadêmico & Recursos Oficiais',
            style: jakarta(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Serviços integrados de suporte ao aprendizado e pesquisa.',
            style: jakarta(
              size: 11.5,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 16),
          for (final res in resources)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      res['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res['title'] as String,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res['desc'] as String,
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    (res['isDownload'] as bool)
                        ? Icons.download_rounded
                        : Icons.open_in_new_rounded,
                    size: 16,
                    color: const Color(0xFFA1A1AA),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
