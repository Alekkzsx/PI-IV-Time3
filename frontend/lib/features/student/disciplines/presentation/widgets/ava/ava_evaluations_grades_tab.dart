// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'common/ava_common.dart';

/// [AvaEvaluationsGradesTab]
///
/// Aba 4 do Cockpit AVA: Boletim de Avaliações Contínuas (PPC).
/// Apresenta a tabela regimental de avaliações (P1, TRAB, P2) e a média parcial
/// consolidada utilizando [AvaOpenSectionHeader], [AvaSurfaceCard] e [AvaStatusBadge].
class AvaEvaluationsGradesTab extends StatelessWidget {
  /// Disciplina da qual as notas serão renderizadas.
  final StudentDisciplineModel discipline;

  /// Cria uma nova instância de [AvaEvaluationsGradesTab].
  const AvaEvaluationsGradesTab({super.key, required this.discipline});

  @override
  Widget build(BuildContext context) {
    if (!AppUserSession.instance.hasPermission('view_own_grades')) {
      return const AccessDeniedView(
        message: 'Este boletim está disponível apenas para o perfil de aluno.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AvaOpenSectionHeader(
          title: 'Boletim de Avaliações Contínuas (PPC)',
          subtitle:
              'Fórmula de Homologação: Média = (N1 x 0.4) + (N2 x 0.6) • Presença Mínima: 75%',
        ),
        const SizedBox(height: 20),

        AvaSurfaceCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 620),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _buildHeaderCell('AVALIAÇÃO'),
                        _buildHeaderCell('PESO REGIMENTAL'),
                        _buildHeaderCell('NOTA LANÇADA'),
                        _buildHeaderCell('STATUS'),
                      ],
                    ),
                    _buildGradeRow(
                      'Prova Teórica N1 (P1)',
                      'Componente N1',
                      '${discipline.p1.toStringAsFixed(1)} / 10.0',
                      'Consolidado',
                    ),
                    _buildGradeRow(
                      'Trabalho Prático N1 (TRAB)',
                      'Componente N1',
                      '${discipline.trab.toStringAsFixed(1)} / 10.0',
                      'Consolidado',
                    ),
                    _buildGradeRow(
                      'Prova Teórica N2 (P2)',
                      'Componente N2',
                      '${discipline.p2.toStringAsFixed(1)} / 10.0',
                      'Consolidado',
                    ),
                    _buildGradeRow(
                      'Média consolidada de N1 e N2',
                      'Parcial',
                      '${discipline.partialAverage.toStringAsFixed(1)} / 10.0',
                      'Consolidado',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        AvaSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final result = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${discipline.partialAverage.toStringAsFixed(2)} / 10.0 (resultado parcial)',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              );

              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Média Parcial Consolidada:',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    result,
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Média Parcial Consolidada:',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  result,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: jakarta(
          size: 11.5,
          weight: FontWeight.w700,
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }

  TableRow _buildGradeRow(
    String name,
    String weight,
    String score,
    String status,
  ) {
    final isConsolidated = status == 'Consolidado';
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            name,
            style: jakarta(size: 13, color: const Color(0xFF18181B)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            weight,
            style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            score,
            style: jakarta(
              size: 13,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AvaStatusBadge(
              label: status,
              variant: isConsolidated
                  ? AvaBadgeVariant.success
                  : AvaBadgeVariant.warning,
              isPill: false,
            ),
          ),
        ),
      ],
    );
  }
}
