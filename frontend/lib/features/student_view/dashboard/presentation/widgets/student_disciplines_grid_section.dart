// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';

class StudentDisciplineItemData {
  final String code;
  final String name;
  final String professor;
  final double progress;

  const StudentDisciplineItemData(
    this.code,
    this.name,
    this.professor,
    this.progress,
  );
}

/// Seção com a grade ou lista de disciplinas matriculadas no semestre.
class StudentDisciplinesGridSection extends StatelessWidget {
  final StudentPortalController controller;
  final List<StudentDisciplineItemData> disciplines;

  const StudentDisciplinesGridSection({
    super.key,
    required this.controller,
    required this.disciplines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Minhas Disciplinas',
              style: jakarta(
                size: 18,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            InkWell(
              key: const Key('btn_ver_grade'),
              onTap: () => controller.setNavItem(StudentNavItem.disciplinas),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'Ver grade',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF18181B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        controller.isGridView ? _buildGrid() : _buildList(),
      ],
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final single = constraints.maxWidth < 560;
        final w = single ? constraints.maxWidth : (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final d in disciplines)
              SizedBox(width: w, child: _disciplineCard(d)),
          ],
        );
      },
    );
  }

  Widget _disciplineCard(StudentDisciplineItemData d) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeChip(d.code),
          const SizedBox(height: 14),
          Text(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.professor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 12,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 22),
          _progressRow(d.progress),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        for (final d in disciplines)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                _codeChip(d.code),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.professor,
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 160, child: _progressRow(d.progress)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _codeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: jakarta(
          size: 11,
          weight: FontWeight.w600,
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }

  Widget _progressRow(double p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w500,
                color: const Color(0xFF71717A),
              ),
            ),
            Text(
              '${(p * 100).round()}%',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p.clamp(0.0, 1.0),
            minHeight: 3.5,
            backgroundColor: const Color(0xFFF4F4F5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4D4D8)),
          ),
        ),
      ],
    );
  }
}
