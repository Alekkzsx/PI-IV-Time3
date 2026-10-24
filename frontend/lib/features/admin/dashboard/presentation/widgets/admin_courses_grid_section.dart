// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

class AdminCourseCardData {
  final String code;
  final String modality;
  final String name;
  final String enrolledText;
  final String workload;

  const AdminCourseCardData({
    required this.code,
    required this.modality,
    required this.name,
    required this.enrolledText,
    required this.workload,
  });
}

/// Seção que exibe os cursos e matrizes ativas em formato de grade 2x2.
class AdminCoursesGridSection extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const AdminCoursesGridSection({super.key, this.onSeeAll});

  static const List<AdminCourseCardData> defaultCourses = [
    AdminCourseCardData(
      code: 'ENG-SOFT-2024',
      modality: 'Graduação',
      name: 'Bacharelado em Engenharia de Software',
      enrolledText: '420 discentes matriculados',
      workload: '3200h',
    ),
    AdminCourseCardData(
      code: 'SIS-INFO-2023',
      modality: 'Graduação',
      name: 'Bacharelado em Sistemas de Informação',
      enrolledText: '380 discentes matriculados',
      workload: '3000h',
    ),
    AdminCourseCardData(
      code: 'CIEN-COMP-2022',
      modality: 'Graduação',
      name: 'Bacharelado em Ciência da Computação',
      enrolledText: '310 discentes matriculados',
      workload: '3400h',
    ),
    AdminCourseCardData(
      code: 'TEC-ADS-2025',
      modality: 'Tecnólogo',
      name: 'Tecnologia em Análise e Desenvolvimento de Sistemas',
      enrolledText: '130 discentes matriculados',
      workload: '2400h',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Cursos & Matrizes Ativas',
              style: jakarta(
                size: 22,
                weight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.4,
              ),
            ),
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Ver todos os cursos',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _buildCourseCard(defaultCourses[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildCourseCard(defaultCourses[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCourseCard(defaultCourses[2])),
            const SizedBox(width: 16),
            Expanded(child: _buildCourseCard(defaultCourses[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseCard(AdminCourseCardData course) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Text(
                course.modality,
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w500,
                  color: const Color(0xFF737373),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            course.name,
            style: jakarta(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.enrolledText,
            style: jakarta(
              size: 13.5,
              weight: FontWeight.w500,
              color: const Color(0xFF737373),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carga Horária Total',
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: const Color(0xFF737373),
                ),
              ),
              Text(
                course.workload,
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 4,
              backgroundColor: Color(0xFFF2F0EB),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

