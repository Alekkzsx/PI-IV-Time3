// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Card de destaque "Continuar de Onde Parou" (Fast-Resume do AVA).
/// Permite ao discente retomar imediatamente o último módulo acessado,
/// visualizar a pendência iminente e acessar a sala virtual síncrona.
class StudentDisciplinesFastResumeCard extends StatelessWidget {
  final StudentDisciplineModel discipline;
  final void Function(StudentDisciplineModel discipline, [int targetTab])
  onResume;

  const StudentDisciplinesFastResumeCard({
    super.key,
    required this.discipline,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 850;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top tag row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SESSÃO ATIVA NO AVA • CONTINUAR DE ONDE PAROU',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFFA1A1AA),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Último acesso há 45 min',
                      style: jakarta(
                        size: 10.5,
                        color: const Color(0xFFD4D4D8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title and Subject Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discipline.name,
                          style: jakarta(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${discipline.professor} • ${discipline.location} • ${discipline.time}',
                          style: jakarta(
                            size: 12,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Topic details box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Módulo 3: Padrões de Projeto Estruturais (GoF)',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFFF4F4F5),
                          ),
                        ),
                        Text(
                          'Slide 14 de 28 (50%)',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w600,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aula 14: Padrão Adapter — Integração de interfaces legadas com Wrapper e contratos.',
                      style: jakarta(size: 12, color: const Color(0xFFD4D4D8)),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.50,
                        minHeight: 4,
                        backgroundColor: Color(0xFF27272A),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF22C55E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action buttons row
              if (isCompact) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryResumeBtn(context),
                    const SizedBox(height: 10),
                    _buildPendingTaskBtn(context),
                    const SizedBox(height: 10),
                    _buildLiveClassBtn(context),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    _buildPrimaryResumeBtn(context),
                    const SizedBox(width: 12),
                    _buildPendingTaskBtn(context),
                    const Spacer(),
                    _buildLiveClassBtn(context),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryResumeBtn(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('btn_retomar_aula_ava'),
      onPressed: () => onResume(discipline, 0),
      icon: const Icon(
        Icons.play_arrow_rounded,
        size: 18,
        color: Color(0xFF18181B),
      ),
      label: Text(
        'Retomar Aula no AVA',
        style: jakarta(
          size: 12.5,
          weight: FontWeight.w700,
          color: const Color(0xFF18181B),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18181B),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPendingTaskBtn(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('btn_tarefa_pendente_ava'),
      onPressed: () => onResume(discipline, 1),
      icon: const Icon(
        Icons.assignment_outlined,
        size: 16,
        color: Color(0xFFFDE68A),
      ),
      label: Text(
        'Sprint 1: Diagramas (Hoje 23:59)',
        style: jakarta(
          size: 12,
          weight: FontWeight.w600,
          color: const Color(0xFFFDE68A),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF78350F).withValues(alpha: 0.3),
        side: const BorderSide(color: Color(0xFFB45309)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLiveClassBtn(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final isOpen = AcademicBridgeService.instance.isSessionOpen(
          discipline.code,
        );
        return OutlinedButton.icon(
          key: const Key('btn_sala_virtual_resume'),
          onPressed: isOpen
              ? () => Navigator.of(context).pushNamed(
                  '/video-call',
                  arguments: {
                    'name': StudentMockData.studentName,
                    'ra': StudentMockData.studentRa,
                    'roomCode': discipline.code,
                    'role': 'aluno',
                  },
                )
              : null,
          icon: Icon(
            isOpen ? Icons.videocam_outlined : Icons.lock_clock_outlined,
            size: 16,
            color: const Color(0xFF86EFAC),
          ),
          label: Text(
            isOpen ? 'Sala Virtual (Ao Vivo)' : 'Sala aguardando docente',
            style: jakarta(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF86EFAC),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFF14532D).withValues(alpha: 0.3),
            side: const BorderSide(color: Color(0xFF16A34A)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
