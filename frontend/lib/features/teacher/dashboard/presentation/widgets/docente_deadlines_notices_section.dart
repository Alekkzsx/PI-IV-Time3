// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

/// Seção da coluna direita contendo "Prazos e Entregas" e "Mensagens e Avisos".
class DocenteDeadlinesNoticesSection extends StatelessWidget {
  final DocenteController controller;

  const DocenteDeadlinesNoticesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDeadlinesCard(),
        const SizedBox(height: 24),
        _buildNoticesCard(),
      ],
    );
  }

  Widget _buildDeadlinesCard() {
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
              const Text(
                'Prazos e Entregas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '04',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDeadlineItem(
            title: 'Entrega: Diagrama de Classes e Sequência',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Hoje, 20/09 às 23:59',
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          _buildDeadlineItem(
            title: 'Fórum Temático: Arquitetura de Software',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Amanhã, 21/09 às 18:00',
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          _buildDeadlineItem(
            title: 'Atividade Prática: Modelagem Relacional e N...',
            course: 'Estudos de Banco de Dados II',
            date: 'Quinta, 24/09 às 23:59',
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          _buildDeadlineItem(
            title: 'Avaliação Parcial: Gerenciamento de Memória',
            course: 'Fundamentos de Sistemas Operacionais',
            date: 'Terça, 29/09 às 20:40',
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineItem({
    required String title,
    required String course,
    required String date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF09090B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          course,
          style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 12, color: Color(0xFF71717A)),
            const SizedBox(width: 4),
            Text(
              date,
              style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoticesCard() {
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
              const Text(
                'Mensagens e Avisos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              InkWell(
                onTap: () =>
                    controller.navigateToTab(DocenteNavTab.comunicados),
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildNoticeItem(
            author: 'Você (Helena Bittencourt - APS-II)',
            time: 'Hoje, 14:10',
            title: 'Feedback da Sprint 1 e Orientações para o Diagrama UML',
            body:
                'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          _buildNoticeItem(
            author: 'Coordenação de Curso (Sistemas de Informação)',
            time: 'Ontem, 17:45',
            title: 'Homologação de Diários de Classe - Fechamento 1º Bimestre',
            body:
                'Lembramos aos docentes que a consolidação das notas parciais e faltas deve ser realizada até sexta-feira.',
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF4F4F5)),

          _buildNoticeItem(
            author: 'Secretaria Acadêmica AGMRM',
            time: '18 de set',
            title: 'Calendário de Provas Regimentais 2026/2 Homologado',
            body:
                'O cronograma definitivo de avaliações institucionais encontra-se disponível no sistema.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem({
    required String author,
    required String time,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF09090B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF52525B),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
