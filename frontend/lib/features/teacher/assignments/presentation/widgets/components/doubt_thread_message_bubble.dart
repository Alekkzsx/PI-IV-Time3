// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Bolha atômica de mensagem da thread de dúvidas pedagógicas entre docente e discente.
class DoubtThreadMessageBubble extends StatelessWidget {
  final Map<String, String> message;

  const DoubtThreadMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = message['role'] == 'teacher';

    return Align(
      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isTeacher ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isTeacher
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message['sender'] ?? '',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: isTeacher
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message['time'] ?? '',
                  style: jakarta(
                    size: 10.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message['text'] ?? '',
              style: jakarta(
                size: 12.5,
                color: const Color(0xFF1E293B),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
