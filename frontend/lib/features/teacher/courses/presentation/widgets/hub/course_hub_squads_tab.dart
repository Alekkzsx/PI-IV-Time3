// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

/// Aba de Equipes de Projeto & Squads Integradores do curso no Portal Docente.
class CourseHubSquadsTab extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onNewSquad;

  const CourseHubSquadsTab({
    super.key,
    required this.controller,
    this.onNewSquad,
  });

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
              onPressed: onNewSquad,
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

        if (controller.selectedCourse.squads.isEmpty)
          const Text('Ainda não há equipes cadastradas.')
        else
          for (final squad in controller.selectedCourse.squads) ...[
            _buildSquadCard(squad),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  static Widget _buildSquadCard(Map<String, dynamic> squad) {
    final squadName = squad['name']?.toString() ??
        squad['title']?.toString() ??
        'Equipe';
    final rawMembers = squad['members'];
    final members = rawMembers is List
        ? rawMembers.map((member) => member.toString()).join(', ')
        : rawMembers?.toString() ?? '';
    final status = squad['status']?.toString() ?? '';
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
