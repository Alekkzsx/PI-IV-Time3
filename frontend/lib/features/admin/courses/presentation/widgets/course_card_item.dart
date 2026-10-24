// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/widgets/course_matrix_syllabus_modal.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Card descritivo de um Curso com carga horária, fórmula e botão de matriz
class CourseCardItem extends StatelessWidget {
  final AdminCourseModel course;

  const CourseCardItem({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges superiores (Código e Modalidade)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  course.code,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  course.modality,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Título do Curso
          Text(
            course.name,
            style: jakarta(
              size: 18,
              weight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),

          // Lotação / Departamento
          Text(
            course.department,
            style: jakarta(
              size: 13,
              weight: FontWeight.w500,
              color: const Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 22),

          // Informações Regimentais
          _buildMetaRow('Matriz Homologada:', course.matrix),
          const SizedBox(height: 8),
          _buildMetaRow('Carga Horária Total:', course.workload),
          const SizedBox(height: 8),
          _buildMetaRow(
            'Discentes Matriculados:',
            '${course.studentsCount} alunos',
          ),
          const SizedBox(height: 18),

          // Caixa de Critério Regimental de Aprovação
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 14,
                      color: Color(0xFF737373),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CRITÉRIO REGIMENTAL DE APROVAÇÃO',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w700,
                        color: const Color(0xFF737373),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  course.formula,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Botão Consultar Matriz Curricular & Ementário
          InkWell(
            onTap: () => CourseMatrixSyllabusModal.show(context, course),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Consultar Matriz Curricular & Ementário',
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: jakarta(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF737373),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: jakarta(
              size: 13,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
      ],
    );
  }
}
