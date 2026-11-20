// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../common/settings_common_widgets.dart';

/// [ProfileAcademicKpisCard]
///
/// Cartão com os 4 indicadores acadêmicos oficiais custodiados pela Secretaria Geral:
/// Registro Acadêmico (R.A.), Curso de Graduação, Semestre/Período e Coeficiente de Rendimento (CR).
class ProfileAcademicKpisCard extends StatelessWidget {
  /// Registro Acadêmico (R.A.).
  final String studentRa;

  /// Nome do curso de graduação.
  final String studentCourse;

  /// Semestre letivo atual.
  final String semester;

  /// Turno de matrícula.
  final String shift;

  /// Coeficiente de Rendimento (CR).
  final String academicIndex;

  /// Cria uma nova instância de [ProfileAcademicKpisCard].
  const ProfileAcademicKpisCard({
    super.key,
    required this.studentRa,
    required this.studentCourse,
    required this.semester,
    required this.shift,
    required this.academicIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 18,
                color: Color(0xFF18181B),
              ),
              const SizedBox(width: 8),
              Text(
                'Dados Acadêmicos Oficiais',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Informações vinculadas à sua matrícula discente sob custódia da Secretaria Geral.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (isNarrow) {
                return Column(
                  children: [
                    SettingsKpiTile(
                      label: 'REGISTRO ACADÊMICO (R.A.)',
                      value: studentRa,
                      icon: Icons.numbers_rounded,
                    ),
                    const SizedBox(height: 12),
                    SettingsKpiTile(
                      label: 'CURSO DE GRADUAÇÃO',
                      value: studentCourse,
                      icon: Icons.menu_book_rounded,
                    ),
                    const SizedBox(height: 12),
                    SettingsKpiTile(
                      label: 'SEMESTRE / PERÍODO',
                      value: '$semester • $shift',
                      icon: Icons.calendar_month_rounded,
                    ),
                    const SizedBox(height: 12),
                    SettingsKpiTile(
                      label: 'COEFICIENTE DE RENDIMENTO (CR)',
                      value: '$academicIndex / 10.0',
                      icon: Icons.analytics_outlined,
                      highlight: true,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SettingsKpiTile(
                          label: 'REGISTRO ACADÊMICO (R.A.)',
                          value: studentRa,
                          icon: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SettingsKpiTile(
                          label: 'CURSO DE GRADUAÇÃO',
                          value: studentCourse,
                          icon: Icons.menu_book_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SettingsKpiTile(
                          label: 'SEMESTRE / PERÍODO',
                          value: '$semester • $shift',
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SettingsKpiTile(
                          label: 'COEFICIENTE DE RENDIMENTO (CR)',
                          value: '$academicIndex / 10.0',
                          icon: Icons.analytics_outlined,
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
