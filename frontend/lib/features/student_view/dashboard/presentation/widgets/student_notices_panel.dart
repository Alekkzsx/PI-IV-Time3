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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mural de Avisos',
                style: jakarta(size: 15, weight: FontWeight.w500),
              ),
              Text(
                'NÃO LIDOS',
                style: jakarta(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
          const SizedBox(height: 16),
          for (int i = 0; i < notices.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
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
          children: [
            Flexible(
              child: Text(
                n.author,
                overflow: TextOverflow.ellipsis,
                style: jakarta(size: 9.5, weight: FontWeight.w600),
              ),
            ),
            if (n.unread) ...[
              const SizedBox(width: 6),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _ink,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            const Spacer(),
            Text(n.time, style: jakarta(size: 9, color: _faint)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          n.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(size: 12, weight: FontWeight.w600, height: 1.3),
        ),
        const SizedBox(height: 5),
        Text(
          n.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(size: 10, color: _muted, height: 1.4),
        ),
      ],
    );
  }
}

