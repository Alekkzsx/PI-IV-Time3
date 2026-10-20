// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Card de plano de aula, data e preenchimento de conteúdo programático (exigência MEC).
class DocenteDiaryLessonPlanCard extends StatefulWidget {
  final DocenteController controller;
  final ClassSession session;

  const DocenteDiaryLessonPlanCard({
    super.key,
    required this.controller,
    required this.session,
  });

  @override
  State<DocenteDiaryLessonPlanCard> createState() =>
      _DocenteDiaryLessonPlanCardState();
}

class _DocenteDiaryLessonPlanCardState
    extends State<DocenteDiaryLessonPlanCard> {
  late TextEditingController _contentController;
  late TextEditingController _methodologyController;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.session.contentProgram);
    _methodologyController =
        TextEditingController(text: widget.session.methodology);
  }

  @override
  void didUpdateWidget(covariant DocenteDiaryLessonPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _contentController.text = widget.session.contentProgram;
      _methodologyController.text = widget.session.methodology;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _methodologyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AULA Nº ${session.sessionNumber} • CARGA: ${session.hours}H/AULA',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: session.isHomologated
                      ? DocenteColors.successLight
                      : DocenteColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.isHomologated
                      ? 'Homologado no Sistema'
                      : 'Aguardando Homologação',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: session.isHomologated
                        ? DocenteColors.success
                        : DocenteColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.dateFormatted,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Conteúdo Programático Específico Ministrado (Exigência Regimental MEC)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            maxLines: 2,
            onChanged: (val) {
              widget.controller.updateSessionContent(
                val,
                _methodologyController.text,
              );
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Metodologia e Recursos Aplicados',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _methodologyController,
            maxLines: 2,
            onChanged: (val) {
              widget.controller.updateSessionContent(
                _contentController.text,
                val,
              );
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
