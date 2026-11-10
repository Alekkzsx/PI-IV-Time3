// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Card "Mensagens e Avisos" da coluna direita do Painel Geral do Docente

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

/// Card de exibição das últimas mensagens e comunicados acadêmicos.
class DocenteNoticesPreviewCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteNoticesPreviewCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com Título e "Ver todos"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mensagens e Avisos',
                style: jakarta(
                  size: 16.5,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => controller.navigateToTab(DocenteNavTab.comunicados),
                  child: Text(
                    'Ver todos',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: InstColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Mensagem Helena Bittencourt
          _buildNoticeItem(
            author: 'Você (Helena Bittencourt - APS-II)',
            time: 'Hoje, 14:10',
            title: 'Feedback da Sprint 1 e Orientações para o Diagrama UML',
            body:
                'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
          ),
          const Divider(height: 28, thickness: 1, color: Color(0xFFF4F4F5)),

          // 2. Mensagem Coordenação de Curso
          _buildNoticeItem(
            author: 'Coordenação de Curso (Sistemas de Informação)',
            time: 'Ontem, 17:45',
            title: 'Homologação de Diários de Classe - Fechamento 1º Bimestre',
            body:
                'Lembramos aos docentes que a consolidação das notas parciais e faltas deve ser realizada até sexta-feira.',
          ),
          const Divider(height: 28, thickness: 1, color: Color(0xFFF4F4F5)),

          // 3. Mensagem Secretaria Acadêmica
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
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: InstColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: jakarta(
                size: 11,
                color: InstColors.faint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: jakarta(
            size: 13,
            weight: FontWeight.w700,
            color: InstColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: jakarta(
            size: 12,
            color: const Color(0xFF52525B),
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
