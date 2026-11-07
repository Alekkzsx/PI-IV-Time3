// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Banner visual institucional com temporizador regressivo para ações temporariamente bloqueadas por rate limit.
class StudentRateLimitCooldownBanner extends StatelessWidget {
  final int remainingSeconds;
  final String actionDescription;

  const StudentRateLimitCooldownBanner({
    super.key,
    required this.remainingSeconds,
    this.actionDescription = 'esta ação',
  });

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Limite temporário de requisições atingido para $actionDescription. '
              'Por segurança institucional, aguarde $remainingSeconds s.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
