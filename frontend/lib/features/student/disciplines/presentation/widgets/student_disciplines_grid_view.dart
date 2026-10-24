// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'student_disciplines_modals.dart';

typedef DisciplineSelectCallback = void Function(StudentDisciplineModel discipline, [int targetTab]);

/// Grade institucional de cards detalhados das disciplinas ativas do estudante.
/// Atua como portal de entrada direto no AVA de cada matéria, com suporte a
/// clique em todo o cartão, atalhos para tarefas e fóruns, e sala virtual síncrona.
class StudentDisciplinesGridView extends StatelessWidget {
  final List<StudentDisciplineModel> disciplines;
  final DisciplineSelectCallback onSelectDiscipline;

  const StudentDisciplinesGridView({
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 900;
        final cardWidth = isSingleColumn ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: disciplines.map((d) {
            return SizedBox(
              width: cardWidth,
              child: _buildDisciplineCard(context, d),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDisciplineCard(BuildContext context, StudentDisciplineModel d) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectDiscipline(d, 0),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Chip + Status Badges
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
                        d.fullCode ?? '218131 - ${d.code}',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFF52525B),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (d.hasPendingTask) ...[
                          InkWell(
                            onTap: () => onSelectDiscipline(d, 1),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.assignment_outlined, size: 12, color: Color(0xFFB45309)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1 tarefa pendente',
                                    style: jakarta(
                                      size: 10.5,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Freq. ${d.attendancePercentage.toStringAsFixed(1)}%',
                            style: jakarta(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title & Docente
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 17,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  d.professor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 8),

                // Location Pin & Schedule
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${d.location} • ${d.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11.5,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Row & Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progresso dos Módulos',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    Text(
                      '${d.completedHours}h de ${d.totalHours}h (${(d.progress * 100).toInt()}%)',
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
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: d.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFFF4F4F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
                  ),
                ),
                const SizedBox(height: 16),

                // Grades Box (N1, N2, Média Parcial)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Avaliação N1',
                              style: jakarta(size: 10.5, color: const Color(0xFF71717A)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              d.n1.toStringAsFixed(1),
                              style: jakarta(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Avaliação N2',
                              style: jakarta(size: 10.5, color: const Color(0xFF71717A)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              d.n2.toStringAsFixed(1),
                              style: jakarta(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Média Parcial',
                              style: jakarta(size: 10.5, color: const Color(0xFF71717A)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              d.partialAverage.toStringAsFixed(1),
                              style: jakarta(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons: Entrar na Disciplina (AVA) + Sala Virtual
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: Key('btn_entrar_disciplina_${d.code}'),
                        onTap: () => onSelectDiscipline(d, 0),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_outlined,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Entrar na Disciplina (AVA)',
                                    style: jakarta(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      key: Key('btn_sala_virtual_${d.code}'),
                      onPressed: () => Navigator.of(context).pushNamed('/video-call'),
                      icon: const Icon(
                        Icons.videocam_outlined,
                        size: 15,
                        color: Color(0xFF16A34A),
                      ),
                      label: Text(
                        'Sala Virtual',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick tabs shortcuts row (Tarefas, Fórum, Conteúdos)
                Row(
                  children: [
                    _buildQuickTabChip(
                      icon: Icons.assignment_outlined,
                      label: 'Tarefas',
                      onTap: () => onSelectDiscipline(d, 1),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickTabChip(
                      icon: Icons.forum_outlined,
                      label: 'Fórum',
                      onTap: () => onSelectDiscipline(d, 3),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickTabChip(
                      icon: Icons.folder_open_outlined,
                      label: 'Materiais',
                      onTap: () => onSelectDiscipline(d, 6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer: Ver Plano de Ensino & Ementa + Faltas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                        key: Key('btn_plano_ensino_${d.code}'),
                        onTap: () => StudentDisciplinesModals.showPlanoEnsinoModal(context),
                        child: Text(
                          'Ver Plano de Ensino & Ementa',
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w500,
                            color: const Color(0xFF71717A),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${d.absences} faltas (limite: ${d.maxAbsenceHours}h)',
                      style: jakarta(
                        size: 11.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTabChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF52525B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: jakarta(
                size: 10.5,
                weight: FontWeight.w600,
                color: const Color(0xFF52525B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
