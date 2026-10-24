// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../domain/entities/academic_record_summary.dart';

/// Cartão de resumo do Prontuário Acadêmico Regular na Secretaria Virtual.
class AcademicRecordCard extends StatelessWidget {
  /// Dados do prontuário acadêmico do estudante.
  final AcademicRecordSummary record;

  /// Cria uma instância de [AcademicRecordCard].
  const AcademicRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Prontuário: Título e Selo de Matrícula Vigente
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prontuário Acadêmico Regular',
                    style: jakarta(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFA7F3D0),
                    width: 1,
                  ),
                ),
                child: Text(
                  record.activeEnrollmentBadge,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF4F4F5),
          ),
          const SizedBox(height: 16),
          // Grade de Indicadores Acadêmicos (4 colunas)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 680) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Registro Acadêmico (R.A.)',
                        value: record.ra,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Curso de Graduação',
                        value: record.course,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Coeficiente de Rendimento (CR)',
                        value: record.academicIndex,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        label: 'Carga Horária Integralizada',
                        value: record.completedWorkload,
                      ),
                    ),
                  ],
                );
              }

              return Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 210,
                    child: _buildMetricItem(
                      label: 'Registro Acadêmico (R.A.)',
                      value: record.ra,
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: _buildMetricItem(
                      label: 'Curso de Graduação',
                      value: record.course,
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: _buildMetricItem(
                      label: 'Coeficiente de Rendimento (CR)',
                      value: record.academicIndex,
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: _buildMetricItem(
                      label: 'Carga Horária Integralizada',
                      value: record.completedWorkload,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: jakarta(
            size: 11.5,
            color: const Color(0xFF71717A),
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: jakarta(
            size: 13,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
      ],
    );
  }
}
