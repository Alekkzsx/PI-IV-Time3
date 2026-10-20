// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';

/// Painel lateral que lista os prazos regimentais e marcos acadêmicos do campus.
class AdminRegimentalDeadlinesPanel extends StatelessWidget {
  const AdminRegimentalDeadlinesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Prazos Regimentais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  '03',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _buildPrazoItem(
            'Fechamento de Prazos N1',
            'Prazo final para digitação de notas e frequências',
            '30/10 às 23:59',
            Icons.access_time,
          ),
          const Divider(height: 1),
          _buildPrazoItem(
            'Validação de Horas Complementares',
            'Período para submissão de certificados externos',
            'Até 15/11/2026',
            Icons.access_time,
          ),
          const Divider(height: 1),
          _buildPrazoItem(
            'Renovação de Matrículas 2027/1',
            'Abertura da grade horária e pré-matrícula',
            'Início em 01/12/2026',
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildPrazoItem(
    String title,
    String subtitle,
    String dateInfo,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                dateInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

