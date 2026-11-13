// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Modal institucional de visualização e decisão de requerimentos discentes no backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_protocol.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Modal para exibição detalhada e decisão de um requerimento acadêmico protocolado por discente.
class DocenteProtocolDetailsModal extends StatelessWidget {
  final TeacherProtocol protocol;
  final DocenteController? controller;

  const DocenteProtocolDetailsModal({
    super.key,
    required this.protocol,
    this.controller,
  });

  static Future<void> show(
    BuildContext context,
    TeacherProtocol protocol, {
    DocenteController? controller,
  }) {
    return AcademicModalDialog.show<void>(
      context: context,
      builder: (_) => DocenteProtocolDetailsModal(
        protocol: protocol,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusType = switch (protocol.status) {
      TeacherProtocolStatus.deferido => AcademicStatusType.deferido,
      TeacherProtocolStatus.indeferido => AcademicStatusType.indeferido,
      TeacherProtocolStatus.pendente => AcademicStatusType.pendente,
    };

    return AcademicModalDialog(
      title: 'Protocolo de Requerimento Discente',
      subtitle: '${protocol.code} • Análise e Parecer do Docente',
      icon: Icons.description_outlined,
      maxWidth: 620,
      confirmLabel: protocol.status == TeacherProtocolStatus.pendente &&
              controller != null
          ? 'Deferir Requerimento'
          : 'Concluído',
      cancelLabel: 'Fechar',
      onConfirm: () async {
        if (protocol.status == TeacherProtocolStatus.pendente &&
            controller != null) {
          await controller!.decideProtocol(
            protocolId: protocol.id,
            decision: TeacherProtocolStatus.deferido,
          );
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol.studentName,
                        style: jakarta(
                          size: 15,
                          weight: FontWeight.w700,
                          color: InstColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Matrícula/RA: ${protocol.studentRa} • Componente: ${protocol.targetComponent}',
                        style: jakarta(
                          size: 12,
                          color: InstColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                AcademicStatusBadge(
                  label: protocol.status.name.toUpperCase(),
                  type: statusType,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  'TIPO DE REQUERIMENTO',
                  protocol.requestType,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetaItem('DATA DE PROTOCOLO', protocol.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Objeto e Justificativa Apresentada',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.border),
            ),
            child: Text(
              protocol.description.isNotEmpty
                  ? protocol.description
                  : 'Requerimento acadêmico formal protocolado perante a Secretaria e encaminhado ao docente responsável.',
              style: jakarta(
                size: 12.5,
                color: const Color(0xFF3F3F46),
                height: 1.4,
              ),
            ),
          ),
          if (protocol.officialResponse != null &&
              protocol.officialResponse!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Despacho da Secretaria Acadêmica',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: InstColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: InstColors.stoneActive,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: InstColors.border),
              ),
              child: Text(
                protocol.officialResponse!,
                style: jakarta(
                  size: 12,
                  color: InstColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: InstColors.faint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: jakarta(
            size: 13,
            weight: FontWeight.w600,
            color: InstColors.ink,
          ),
        ),
      ],
    );
  }
}
