// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _faint = Color(0xFFA3A3A3);
const _border = Color(0xFFE5E5E5);

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 2,
            offset: Offset(0, 1),
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
                style: jakarta(size: 18, weight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
              ),
              Text(
                'NÃO LIDOS',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF737373),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF2F0EB)),
          const SizedBox(height: 18),
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
            Row(
              children: [
                Text(
                  n.author,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: n.unread ? const Color(0xFF1A1A1A) : const Color(0xFF525252),
                  ),
                ),
                if (n.unread) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            Text(n.time, style: jakarta(size: 12, color: const Color(0xFFA3A3A3), weight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          n.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(size: 14, weight: FontWeight.w600, color: const Color(0xFF1A1A1A), height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(
          n.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(size: 13, color: const Color(0xFF737373), height: 1.4),
        ),
      ],
    );
  }
}

