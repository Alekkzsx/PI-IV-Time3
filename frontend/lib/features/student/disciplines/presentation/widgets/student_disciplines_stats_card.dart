// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Card consolidado de métricas institucionais do estudante (Carga Horária, Média, Frequência e Situação).
class StudentDisciplinesStatsCard extends StatelessWidget {
  const StudentDisciplinesStatsCard({super.key});

  StudentPortalController get _controller => StudentPortalController.instance;

  int get _completedHours => _controller.disciplines.fold(
    0,
    (total, discipline) => total + discipline.completedHours,
  );

  int get _totalHours => _controller.disciplines.fold(
    0,
    (total, discipline) => total + discipline.totalHours,
  );

  double? get _average => _controller.disciplines.isEmpty
      ? null
      : _controller.disciplines.fold<double>(
              0,
              (total, discipline) => total + discipline.partialAverage,
            ) /
            _controller.disciplines.length;

  double? get _attendance => _controller.disciplines.isEmpty
      ? null
      : _controller.disciplines.fold<double>(
              0,
              (total, discipline) => total + discipline.attendancePercentage,
            ) /
            _controller.disciplines.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          if (isSmall) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCargaHoraria()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMediaPonderada()),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFrequencia()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSituacao()),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCargaHoraria()),
              _buildDivider(),
              Expanded(child: _buildMediaPonderada()),
              _buildDivider(),
              Expanded(child: _buildFrequencia()),
              _buildDivider(),
              Expanded(child: _buildSituacao()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildCargaHoraria() {
    final totalHours = _totalHours;
    final completedHours = _completedHours;
    final progress = totalHours == 0 ? 0.0 : completedHours / totalHours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARGA HORÁRIA TOTAL',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              totalHours == 0 ? '—' : '${completedHours}h',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                totalHours == 0
                    ? 'de —'
                    : 'de ${totalHours}h (${(progress * 100).round()}%)',
                overflow: TextOverflow.ellipsis,
                style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 3.5,
            backgroundColor: const Color(0xFFF4F4F5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPonderada() {
    final average = _average;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÉDIA PONDERADA PARCIAL',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              average?.toStringAsFixed(2) ?? '—',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            if (average != null)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: average >= 6
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    average >= 6 ? 'Média parcial ≥ 6' : 'Média parcial < 6',
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(
                      size: 10,
                      weight: FontWeight.w600,
                      color: average >= 6
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Média das disciplinas com dados disponíveis',
          style: jakarta(size: 11, color: const Color(0xFF71717A)),
        ),
      ],
    );
  }

  Widget _buildFrequencia() {
    final attendance = _attendance;
    final absences = _controller.disciplines.fold<int>(
      0,
      (total, discipline) => total + discipline.absences,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUÊNCIA GLOBAL CONSOLIDADA',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              attendance == null ? '—' : '${attendance.toStringAsFixed(1)}%',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '($absences faltas)',
                overflow: TextOverflow.ellipsis,
                style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Frequência média das disciplinas',
          style: jakarta(
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildSituacao() {
    final summary = _controller.recordSummary;
    final enrollmentStatus =
        summary['activeEnrollmentBadge']?.toString().trim().isNotEmpty == true
        ? summary['activeEnrollmentBadge'].toString()
        : _controller.studentInfo['enrollmentStatus']?.toString() ?? '—';
    final semester =
        _controller.studentInfo['semester']?.toString() ??
        (_controller.disciplines.isEmpty
            ? '—'
            : _controller.disciplines.first.semester);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SITUAÇÃO CURRICULAR $semester',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              enrollmentStatus,
              style: jakarta(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_controller.disciplines.length} disciplinas em andamento',
          style: jakarta(size: 11, color: const Color(0xFF71717A)),
        ),
      ],
    );
  }
}
