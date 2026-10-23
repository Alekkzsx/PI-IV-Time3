// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'student_disciplines_modals.dart';

/// Visualização em lista compacta e tabular das disciplinas do discente.
/// Oferece uma visão operacional com acesso rápido ao AVA, notas parciais,
/// frequência e atalhos diretos para as salas virtuais.
class StudentDisciplinesListView extends StatelessWidget {
  final List<StudentDisciplineModel> disciplines;
  final void Function(StudentDisciplineModel discipline, [int targetTab]) onSelectDiscipline;

  const StudentDisciplinesListView({
    super.key,
    required this.disciplines,
    required this.onSelectDiscipline,
  });

  @override
  Widget build(BuildContext context) {
    if (disciplines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          'Nenhuma disciplina encontrada com os filtros selecionados.',
          style: jakarta(size: 13, color: const Color(0xFF71717A)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < disciplines.length; i++) ...[
            _buildListRow(context, disciplines[i]),
            if (i < disciplines.length - 1)
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
          ],
        ],
      ),
    );
  }

  Widget _buildListRow(BuildContext context, StudentDisciplineModel d) {
    return InkWell(
      onTap: () => onSelectDiscipline(d, 0),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.code,
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFF52525B),
                          ),
                        ),
                      ),
                      _buildStatusBadges(d),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.name,
                    style: jakarta(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.professor} • ${d.location}',
                    style: jakarta(size: 12, color: const Color(0xFF71717A)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso: ${(d.progress * 100).toInt()}%',
                        style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                      ),
                      Text(
                        'Média: ${d.partialAverage.toStringAsFixed(1)} | Freq: ${d.attendancePercentage.toStringAsFixed(1)}%',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActionButtons(context, d),
                ],
              );
            }

            return Row(
              children: [
                // Icon / Code
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    d.code,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title & Professor
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              d.name,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                size: 14.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadges(d),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.professor} • ${d.location} • ${d.time}',
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11.5,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Progress Bar & Hours
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: jakarta(size: 11, color: const Color(0xFF71717A)),
                          ),
                          Text(
                            '${(d.progress * 100).toInt()}%',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: d.progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: const Color(0xFFF4F4F5),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.completedHours}h de ${d.totalHours}h',
                        style: jakarta(size: 10.5, color: const Color(0xFFA1A1AA)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Grades (N1, N2, Media)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'N1: ${d.n1.toStringAsFixed(1)} | N2: ${d.n2.toStringAsFixed(1)}',
                        style: jakarta(size: 11, color: const Color(0xFF71717A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Média: ',
                            style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                          ),
                          Text(
                            d.partialAverage.toStringAsFixed(1),
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Freq: ${d.attendancePercentage.toStringAsFixed(1)}% (${d.absences} faltas)',
                        style: jakarta(size: 10.5, color: const Color(0xFFA1A1AA)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Actions
                _buildActionButtons(context, d),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadges(StudentDisciplineModel d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d.hasPendingTask) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '1 pendente',
              style: jakarta(
                size: 10,
                weight: FontWeight.w600,
                color: const Color(0xFFB45309),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${d.attendancePercentage.toStringAsFixed(0)}% freq',
            style: jakarta(
              size: 10,
              weight: FontWeight.w700,
              color: const Color(0xFF166534),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, StudentDisciplineModel d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          key: Key('btn_entrar_disciplina_list_${d.code}'),
          onPressed: () => onSelectDiscipline(d, 0),
          icon: const Icon(Icons.menu_book_outlined, size: 14, color: Colors.white),
          label: Text(
            'Entrar no AVA',
            style: jakarta(size: 11.5, weight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          key: Key('btn_sala_virtual_list_${d.code}'),
          onPressed: () => Navigator.of(context).pushNamed('/video-call'),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF0FDF4),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Icon(Icons.videocam_outlined, size: 16, color: Color(0xFF16A34A)),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: Key('btn_plano_ensino_list_${d.code}'),
          tooltip: 'Ver Plano de Ensino & Ementa',
          onPressed: () => StudentDisciplinesModals.showPlanoEnsinoModal(context),
          icon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF71717A)),
        ),
      ],
    );
  }
}

