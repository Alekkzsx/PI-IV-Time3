// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';

/// Seção "Minhas Turmas" e "Requerimentos Acadêmicos das Turmas" na coluna esquerda do Painel Docente.
class DocenteCoursesPreviewSection extends StatelessWidget {
  final DocenteController controller;
  final void Function(String courseId)? onOpenCourseHub;

  const DocenteCoursesPreviewSection({
    super.key,
    required this.controller,
    this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho Minhas Turmas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Turmas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF09090B),
              ),
            ),
            InkWell(
              onTap: () => controller.navigateToTab(DocenteNavTab.turmas),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Ver grade',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 12, color: Color(0xFF09090B)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Grid com as Turmas do Professor
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 580;

            final card1 = _buildCourseCard(
              tag: '218131 - APS-II',
              title: 'Análise e Projeto de Sistemas II',
              subtitle: 'Noturno • 34 discentes',
              progress: 0.68,
              progressLabel: '68%',
              courseId: 'course-aps2',
            );

            final card2 = _buildCourseCard(
              tag: '218131 - BD-II',
              title: 'Estudos de Banco de Dados II',
              subtitle: 'Noturno • 31 discentes',
              progress: 0.75,
              progressLabel: '75%',
              courseId: 'course-bd2',
            );

            final card3 = _buildCourseCard(
              tag: '218131 - FSO',
              title: 'Fundamentos de Sistemas Operacionais',
              subtitle: 'Noturno • 36 discentes',
              progress: 0.55,
              progressLabel: '55%',
              courseId: 'course-fso',
            );

            if (isSmall) {
              return Column(
                children: [
                  card1,
                  const SizedBox(height: 12),
                  card2,
                  const SizedBox(height: 12),
                  card3,
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 14),
                    Expanded(child: card2),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card3),
                    const SizedBox(width: 14),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // Card: Requerimentos Acadêmicos das Turmas
        _buildAcademicRequestsCard(),
      ],
    );
  }

  Widget _buildCourseCard({
    required String tag,
    required String title,
    required String subtitle,
    required double progress,
    required String progressLabel,
    required String courseId,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F3F46),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  if (onOpenCourseHub != null) {
                    onOpenCourseHub!(courseId);
                  } else {
                    controller.navigateToTab(DocenteNavTab.turmas);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.hub_outlined, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Sala de Aula AVA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF09090B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso do Plano',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71717A),
                ),
              ),
              Text(
                progressLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Autoria & Edição habilitadas',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              InkWell(
                onTap: () {
                  if (onOpenCourseHub != null) {
                    onOpenCourseHub!(courseId);
                  } else {
                    controller.navigateToTab(DocenteNavTab.turmas);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Acessar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 11, color: Color(0xFF09090B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicRequestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF09090B)),
                  SizedBox(width: 8),
                  Text(
                    'Requerimentos Acadêmicos das Turmas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '2 solicitações',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Atestados médicos, pedidos de 2ª chamada e revisões de notas protocolados por discentes das suas disciplinas.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 14),

          // Protocolo 1: Camila Duarte Fagundes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF4F4F5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Camila Duarte Fagundes ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF09090B),
                            ),
                          ),
                          const Text(
                            '(2024.1.00902)  ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'DEFERIDO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Atestado Médico: APS-II e BD-II (Afastamento 29 a 30/09)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'PROT-2026/8841',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Protocolo 2: Rodrigo Antunes Nogueira
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF4F4F5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Rodrigo Antunes Nogueira ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF09090B),
                            ),
                          ),
                          const Text(
                            '(2024.1.00938)  ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'PENDENTE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Segunda Chamada: APS-II - Prova Substitutiva',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'PROT-2026/8850',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
