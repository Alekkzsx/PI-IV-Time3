// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Painel lateral que lista os prazos regimentais e marcos acadêmicos do campus.
class AdminRegimentalDeadlinesPanel extends StatelessWidget {
  final ValueChanged<String>? onNavigateTarget;

  const AdminRegimentalDeadlinesPanel({super.key, this.onNavigateTarget});

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  '03',
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
          _buildPrazoItem(
            title: 'Fechamento de Prazos N1',
            subtitle: 'Prazo final para digitação de notas e frequências',
            dateInfo: '30/10 às 23:59',
            barColor: const Color(0xFF1A1A1A),
            onTap: () => onNavigateTarget?.call('calendario'),
          ),
          const SizedBox(height: 24),
          _buildPrazoItem(
            title: 'Validação de Horas Complementares',
            subtitle: 'Período para submissão de certificados externos',
            dateInfo: 'Até 15/11/2026',
            barColor: const Color(0xFF1A1A1A),
            onTap: () => onNavigateTarget?.call('secretaria'),
          ),
          const SizedBox(height: 24),
          _buildPrazoItem(
            title: 'Renovação de Matrículas 2027/1',
            subtitle: 'Abertura da grade horária e pré-matrícula',
            dateInfo: 'Início em 01/12/2026',
            barColor: const Color(0xFFE5E5E5),
            onTap: () => onNavigateTarget?.call('turmas'),
          ),
        ],
      ),
    );
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
