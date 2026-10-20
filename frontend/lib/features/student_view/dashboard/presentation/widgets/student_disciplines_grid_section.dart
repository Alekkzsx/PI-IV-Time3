// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _border = Color(0xFFE5E5E5);
const _track = Color(0xFFEFEDE8);

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
              style: jakarta(size: 18, weight: FontWeight.w500),
            ),
            InkWell(
              key: const Key('btn_ver_grade'),
              onTap: () => controller.setNavItem(StudentNavItem.disciplinas),
              child: Row(
                children: [
                  Text(
                    'Ver grade',
                    style: jakarta(size: 13, weight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: _ink),
                ],
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
      builder: (context, c) {
        final single = c.maxWidth < 560;
        final w = single ? c.maxWidth : (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
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
      height: 144,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeChip(d.code),
          const SizedBox(height: 14),
          Text(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(d.professor, style: jakarta(size: 10, color: _muted)),
          const Spacer(),
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
            decoration: _cardDecoration(),
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
                        style: jakarta(size: 13, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(d.professor, style: jakarta(size: 10, color: _muted)),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(code, style: jakarta(size: 10.5, weight: FontWeight.w500)),
    );
  }

  Widget _progressRow(double p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso',
              style: jakarta(size: 10, weight: FontWeight.w600, color: _muted),
            ),
            Text(
              '${(p * 100).round()}%',
              style: jakarta(size: 10.5, weight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: p.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: _track,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8C6C0)),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      );
}

