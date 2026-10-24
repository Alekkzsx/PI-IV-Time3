// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/widgets/course_card_item.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';

/// Tela de Cursos & Matrizes Curriculares (PPC) da Visão do Administrador.
/// Exibe a estrutura pedagógica institucional, carga horária regimental,
/// critérios de aprovação e o modal de detalhamento do ementário por período.
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = AdminMockData.courses;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 28),

                        // Grade de Cursos 2x2 ou Coluna Simples
                        if (isDesktop && courses.length >= 4) ...[
                          for (var i = 0; i < courses.length; i += 2) ...[
                            if (i > 0) const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CourseCardItem(course: courses[i]),
                                ),
                                if (i + 1 < courses.length) ...[
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: CourseCardItem(
                                      course: courses[i + 1],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ] else ...[
                          for (int i = 0; i < courses.length; i++) ...[
                            if (i > 0) const SizedBox(height: 20),
                            CourseCardItem(course: courses[i]),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cursos & Matrizes Curriculares (PPC)',
          style: jakarta(
            size: isDesktop ? 28 : 24,
            weight: FontWeight.w700,
            color: const Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Estrutura pedagógica institucional, carga horária regimental e parametrização das fórmulas de avaliação.',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );
  }
}
