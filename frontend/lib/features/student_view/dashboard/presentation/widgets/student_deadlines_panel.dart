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
                'Prazos Pendentes',
                style: jakarta(size: 15, weight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F0),
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${deadlines.length}',
                  style: jakarta(size: 10, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
          const SizedBox(height: 16),
          for (final d in deadlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 2, color: _ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(size: 11.5, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.discipline,
                            style: jakarta(size: 9.5, color: _muted),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 10,
                                color: _faint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d.due,
                                style: jakarta(size: 9.5, color: _muted),
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
          const SizedBox(height: 2),
          Material(
            color: _stone,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: _border),
            ),
            child: InkWell(
              key: const Key('btn_abrir_calendario'),
              borderRadius: BorderRadius.circular(4),
              onTap: () => controller.setNavItem(StudentNavItem.calendario),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text(
                    'Abrir Calendário',
                    style: jakarta(size: 11, weight: FontWeight.w500),
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

