// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

class StudentNoticeItemData {
  final String author;
  final String time;
  final String title;
  final String body;
  final bool unread;

  const StudentNoticeItemData(
    this.author,
    this.time,
    this.title,
    this.body,
    this.unread,
  );
}

/// Painel lateral de "Mural de Avisos" acadêmicos e comunicados de professores.
class StudentNoticesPanel extends StatelessWidget {
  final List<StudentNoticeItemData> notices;

  const StudentNoticesPanel({
    super.key,
    required this.notices,
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
                'Mural de Avisos',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              Text(
                'NÃO LIDOS',
                style: jakarta(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF71717A),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),
          for (int i = 0; i < notices.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _noticeItem(notices[i]),
          ],
        ],
      ),
    );
  }

  Widget _noticeItem(StudentNoticeItemData n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                n.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w500,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              n.time,
              style: jakarta(
                size: 11,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          n.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(
            size: 12.5,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          n.body,
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
