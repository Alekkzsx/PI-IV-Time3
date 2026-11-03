// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

/// Aba de Fórum de Discussões & Dúvidas Técnicas do curso no Portal Docente.
class CourseHubForumTab extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onNewTopic;

  const CourseHubForumTab({
    super.key,
    required this.controller,
    this.onNewTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fórum de Discussões & Dúvidas Técnicas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Espaço colaborativo para tirar dúvidas e promover debates síncronos e assíncronos.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: onNewTopic,
              icon: const Icon(
                Icons.add_comment_outlined,
                size: 14,
                color: Colors.white,
              ),
              label: const Text(
                'Novo Tópico',
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

        if (controller.currentForumTopics.isEmpty)
          const Text('Ainda não há tópicos neste fórum.')
        else
          for (final topic in controller.currentForumTopics) ...[
            _buildForumThreadCard(
              context: context,
              title: topic['title']?.toString() ?? 'Tópico',
              author: topic['authorName']?.toString() ??
                  topic['createdByName']?.toString() ??
                  'Participante',
              details:
                  '${topic['replyCount'] ?? (topic['replies'] is List ? (topic['replies'] as List).length : 0)} respostas',
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  static Widget _buildForumThreadCard({
    required BuildContext context,
    required String title,
    required String author,
    required String details,
  }) {
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
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Autor: $author • $details',
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
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Participar',
              style: TextStyle(fontSize: 11, color: Color(0xFF09090B)),
            ),
          ),
        ],
      ),
    );
  }
}
