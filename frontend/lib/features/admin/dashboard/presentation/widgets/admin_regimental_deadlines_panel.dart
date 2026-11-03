// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Painel lateral que lista os prazos regimentais e marcos acadêmicos do campus.
class AdminRegimentalDeadlinesPanel extends StatelessWidget {
  final ValueChanged<String>? onNavigateTarget;

  const AdminRegimentalDeadlinesPanel({super.key, this.onNavigateTarget});

  @override
  Widget build(BuildContext context) {
    final events = AdminPortalController.instance.calendarEvents;
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
                'Prazos Regimentais',
                style: jakarta(
                  size: 18,
                  weight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  events.length.toString().padLeft(2, '0'),
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (events.isEmpty)
            const Text('Nenhum prazo cadastrado.')
          else
            for (final event in events.take(3)) ...[
              _buildPrazoItem(
                title: event.title,
                subtitle: event.description,
                dateInfo: _formatDate(event.startsAt),
                barColor: const Color(0xFF1A1A1A),
                onTap: () => onNavigateTarget?.call('calendario'),
              ),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPrazoItem({
    required String title,
    required String subtitle,
    required String dateInfo,
    required Color barColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 62,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jakarta(
                    size: 15,
                    weight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: Color(0xFFA3A3A3),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateInfo,
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: const Color(0xFFA3A3A3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
