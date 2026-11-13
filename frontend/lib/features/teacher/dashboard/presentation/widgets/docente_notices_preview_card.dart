// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Card "Mensagens e Avisos" do Painel Geral - Padrão estético fiel às referências
// Dados 100% tratados no backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_dashboard_overview.dart';

/// Card de exibição das últimas mensagens e comunicados acadêmicos na coluna direita.
/// Segue exatamente o design limpo das referências (sem avatares circulares).
class DocenteNoticesPreviewCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteNoticesPreviewCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final notices = controller.dashboard.recentNotices;

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
                'Mensagens e Avisos',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      controller.navigateToTab(DocenteNavTab.comunicados),
                  child: Text(
                    'Ver todos',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),
          if (notices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhuma mensagem ou aviso no momento.',
                  style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                ),
              ),
            )
          else
            for (int i = 0; i < notices.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF4F4F5)),
                ),
              _buildNoticeItem(notices[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildNoticeItem(TeacherNoticePreviewItem notice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                notice.authorLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              notice.timeLabel,
              style: jakarta(
                size: 11,
                weight: FontWeight.w400,
                color: const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          notice.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(
            size: 12.5,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notice.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(
            size: 11.5,
            color: const Color(0xFF71717A),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
