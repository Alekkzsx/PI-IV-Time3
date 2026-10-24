// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/widgets/secretary_review_modal.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Tabela responsiva de protocolos da Secretaria Geral
class SecretaryProtocolsTable extends StatelessWidget {
  final List<AdminProtocolModel> protocols;
  final AdminPortalController controller;

  const SecretaryProtocolsTable({
    super.key,
    required this.protocols,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 1100.0;
          final tableWidth =
              constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(),
                  for (int i = 0; i < protocols.length; i++)
                    _buildTableRow(context, protocols[i]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    final headerStyle = jakarta(
      size: 11,
      weight: FontWeight.w700,
      color: const Color(0xFF737373),
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 16,
            child: Text('PROTOCOLO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 22,
            child: Text('DISCENTE / R.A.', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: Text('TIPO DE REQUERIMENTO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 26,
            child: Text('OBJETO / COMPONENTE', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 14,
            child: Text('STATUS', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('AÇÃO', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AdminProtocolModel p) {
    final isDeferido = p.status == 'Deferido';
    final isAguardando =
        p.status == 'Aguardando' || p.status == 'Aguardando Parecer';

    Color statusBg;
    Color statusBorder;
    Color statusText;

    if (isDeferido) {
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
    } else if (isAguardando) {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusText = const Color(0xFFD97706);
    } else {
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusText = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Protocolo
          Expanded(
            flex: 16,
            child: Text(
              p.id,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Discente / R.A.
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.studentName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.studentRa,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Tipo de Requerimento
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  p.requestType,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF52525B),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Objeto / Componente
          Expanded(
            flex: 26,
            child: Text(
              p.targetComponent,
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF525252),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  p.status,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: statusText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ação
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => SecretaryReviewModal.show(
                  context,
                  protocol: p,
                  controller: controller,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    'Analisar Requerimento',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
