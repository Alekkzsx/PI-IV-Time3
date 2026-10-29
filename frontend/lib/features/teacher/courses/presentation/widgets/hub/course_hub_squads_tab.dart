// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de Equipes de Projeto & Squads Integradores do curso no Portal Docente.
class CourseHubSquadsTab extends StatelessWidget {
  final VoidCallback? onNewSquad;

  const CourseHubSquadsTab({super.key, this.onNewSquad});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipes de Projeto & Squads Integradores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Organização dos discentes em squads de desenvolvimento prático e entregas da Sprint.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (onNewSquad != null) {
                  onNewSquad!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Abrindo assistente de criação de squad...',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.group_add, size: 14, color: Colors.white),
              label: const Text(
                'Nova Equipe',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSquadCard(
          'Squad Alpha: Sistema de Gestão Hospitalar',
          'Mariana Rios Costa (Líder), Gabriel Soares, Lucas Mendes, Camila Duarte',
          'Sprint 1 Entregue (Nota 9.5)',
        ),
        const SizedBox(height: 12),
        _buildSquadCard(
          'Squad Beta: Plataforma de E-commerce Sustentável',
          'Rodrigo Antunes (Líder), Vinicius Ferraz, Ana Paula Silva, Felipe Ramos',
          'Sprint 1 em Correção',
        ),
        const SizedBox(height: 12),
        _buildSquadCard(
          'Squad Gamma: App de Logística e Rastreamento IoT',
          'Beatriz Lima (Líder), Carlos Eduardo, Thiago Rocha, Larissa Santos',
          'Sprint 1 Entregue (Nota 8.8)',
        ),
      ],
    );
  }

  static Widget _buildSquadCard(
    String squadName,
    String members,
    String status,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  squadName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Membros: $members',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF71717A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
