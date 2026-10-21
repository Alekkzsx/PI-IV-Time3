// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _faint = Color(0xFFA3A3A3);
const _border = Color(0xFFE5E5E5);
const _stone = Color(0xFFFAF9F6);

class StudentDeadlineItemData {
  final String title;
  final String discipline;
  final String due;

  const StudentDeadlineItemData(this.title, this.discipline, this.due);
}

/// Painel lateral de "Prazos Pendentes" com acesso rápido ao Calendário Acadêmico.
class StudentDeadlinesPanel extends StatelessWidget {
  final StudentPortalController controller;
  final List<StudentDeadlineItemData> deadlines;

  const StudentDeadlinesPanel({
    super.key,
    required this.controller,
    required this.deadlines,
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
                'Prazos Pendentes',
                style: jakarta(size: 18, weight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${deadlines.length}',
                  style: jakarta(size: 13, weight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF2F0EB)),
          const SizedBox(height: 18),
          for (final d in deadlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(size: 14.5, weight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.discipline,
                            style: jakarta(size: 13, color: const Color(0xFF737373)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFFA3A3A3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                d.due,
                                style: jakarta(size: 12, color: const Color(0xFF737373), weight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Material(
            color: const Color(0xFFFAF9F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            child: InkWell(
              key: const Key('btn_abrir_calendario'),
              borderRadius: BorderRadius.circular(6),
              onTap: () => controller.setNavItem(StudentNavItem.calendario),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Abrir Calendário',
                    style: jakarta(size: 14, weight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

