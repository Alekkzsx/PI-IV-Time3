// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import '../../../shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

class AdminRecentProtocolItemData {
  final String studentName;
  final String dateText;
  final String protocolTitle;
  final String description;

  const AdminRecentProtocolItemData({
    required this.studentName,
    required this.dateText,
    required this.protocolTitle,
    required this.description,
  });
}

/// Painel lateral de últimos requerimentos e protocolos protocolados pelos discentes.
class AdminRecentProtocolsPanel extends StatelessWidget {
  final VoidCallback? onSeeAll;
  final ValueChanged<AdminRecentProtocolItemData>? onItemTap;

  const AdminRecentProtocolsPanel({super.key, this.onSeeAll, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final portal = AdminPortalController.instance;
    final protocols = portal.protocols
        .take(3)
        .map(
          (item) => AdminRecentProtocolItemData(
            studentName: item.studentName,
            dateText: item.date,
            protocolTitle: item.requestType,
            description: item.justification,
          ),
        )
        .toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos Requerimentos',
                style: jakarta(
                  size: 18,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                child: Text(
                  'Ver todos',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (protocols.isEmpty) const Text('Nenhum protocolo cadastrado.'),
          for (int i = 0; i < protocols.length; i++) ...[
            if (i > 0) const SizedBox(height: 22),
            _buildProtocolItem(protocols[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildProtocolItem(AdminRecentProtocolItemData item) {
    return InkWell(
      onTap: () => onItemTap?.call(item),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.studentName,
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                item.dateText,
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFFA3A3A3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.protocolTitle,
            style: jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 13,
              weight: FontWeight.w400,
              color: const Color(0xFF737373),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
