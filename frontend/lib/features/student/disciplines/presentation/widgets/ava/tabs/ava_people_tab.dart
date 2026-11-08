// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaPeopleTab]
///
/// Aba 5 do Cockpit AVA: Pessoas e Corpo Docente da Disciplina.
/// Apresenta o docente responsável e o discente autenticado utilizando
/// os componentes visuais desacoplados [AvaOpenSectionHeader] e [AvaSurfaceCard].
class AvaPeopleTab extends StatelessWidget {
  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaPeopleTab].
  const AvaPeopleTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final discipline = controller.selectedDiscipline;
    final professor = discipline?.professor ?? 'Docente Titular';
    final user = AppUserSession.instance.effectiveName;
    final ra = AppUserSession.instance.identity ?? '218131';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AvaOpenSectionHeader(
          title: 'Pessoas e Docentes da Disciplina',
          subtitle:
              'Corpo docente responsável e colegas regularmente matriculados nesta turma.',
        ),
        const SizedBox(height: 20),

        // Card Docente Responsável
        AvaSurfaceCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF18181B),
                child: Text(
                  professor.isNotEmpty ? professor[0] : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professor,
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Docente Responsável • Corpo Docente Institucional',
                      style: jakarta(size: 12, color: const Color(0xFF71717A)),
                    ),
                  ],
                ),
              ),
              const AvaStatusBadge(
                label: 'Professor',
                variant: AvaBadgeVariant.neutral,
                isPill: false,
              ),
            ],
          ),
        ),

        // Card Discente Autenticado
        AvaSurfaceCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(
                  user.isNotEmpty ? user[0] : 'A',
                  style: const TextStyle(
                    color: Color(0xFF18181B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user,
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discente Autenticado • RA: $ra',
                      style: jakarta(size: 12, color: const Color(0xFF71717A)),
                    ),
                  ],
                ),
              ),
              const AvaStatusBadge(
                label: 'Matriculado',
                variant: AvaBadgeVariant.success,
                isPill: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
