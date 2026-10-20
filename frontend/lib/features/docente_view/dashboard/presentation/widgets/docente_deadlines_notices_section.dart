// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Seção dividida exibindo prazos e entregas pendentes juntamente com avisos e comunicados.
class DocenteDeadlinesNoticesSection extends StatelessWidget {
  final DocenteController controller;

  const DocenteDeadlinesNoticesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    final prazosCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Prazos e Entregas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '04 tarefas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDeadlineItem(
            title: 'Entrega: Diagrama de Classes e Sequência',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Hoje, 20/09 às 23:59',
            isUrgent: true,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Fórum Temático: Arquitetura de Software',
            course: 'Análise e Projeto de Sistemas II',
            date: 'Amanhã, 21/09 às 18:00',
            isUrgent: true,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Atividade Prática: Modelagem Relacional e Normalização',
            course: 'Estudos de Banco de Dados II',
            date: 'Quinta, 24/09 às 23:59',
            isUrgent: false,
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildDeadlineItem(
            title: 'Avaliação Parcial: Gerenciamento de Memória',
            course: 'Fundamentos de Sistemas Operacionais',
            date: 'Terça, 29/09 às 20:40',
            isUrgent: false,
          ),
        ],
      ),
    );

    final avisosCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Mensagens e Avisos',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => controller.navigateToTab(DocenteNavTab.comunicados),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoticeItem(
            author: 'Você (Profa. Helena Bittencourt)',
            time: 'Hoje, 14:10',
            title: 'Feedback da Sprint 1 e Orientações para o Diagrama UML',
            preview:
                'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildNoticeItem(
            author: 'Coordenação de Curso (Sistemas de Informação)',
            time: 'Ontem, 17:45',
            title: 'Homologação de Diários de Classe - Fechamento 1º Bimestre',
            preview:
                'Lembramos aos docentes que a consolidação das notas parciais e faltas deve ser realizada até sexta-feira.',
          ),
          const Divider(height: 24, color: DocenteColors.border),
          _buildNoticeItem(
            author: 'Secretaria Acadêmica AGMRM',
            time: '18 de set',
            title: 'Calendário de Provas Regimentais 2026/2 Homologado',
            preview:
                'O cronograma definitivo de avaliações institucionais encontra-se disponível no sistema.',
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: prazosCard),
          const SizedBox(width: 24),
          Expanded(child: avisosCard),
        ],
      );
    } else {
      return Column(
        children: [
          prazosCard,
          const SizedBox(height: 24),
          avisosCard,
        ],
      );
    }
  }

  Widget _buildDeadlineItem({
    required String title,
    required String course,
    required String date,
    required bool isUrgent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textPrimary,
                ),
              ),
            ),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DocenteColors.warningLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Urgente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.warning,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                course,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: DocenteColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUrgent ? DocenteColors.warning : DocenteColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoticeItem({
    required String author,
    required String time,
    required String title,
    required String preview,
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
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: DocenteColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DocenteColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: DocenteColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

