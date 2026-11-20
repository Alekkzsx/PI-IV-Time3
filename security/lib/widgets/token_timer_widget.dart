// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Widget de apresentação que exibe um temporizador de contagem regressiva sincronizado para tokens efêmeros de recuperação.
/// Visualiza o tempo de vida (TTL) de 5 minutos (300 segundos) no formato MM:SS com estados de alerta.
class TokenTimerWidget extends StatelessWidget {
  /// Tempo restante em segundos antes que o token de recuperação expire.
  final int remainingSeconds;

  const TokenTimerWidget({
    super.key,
    required this.remainingSeconds,
  });

  /// Formata os segundos na representação MM:SS.
  String _formatDuration(int seconds) {
    final clamped = seconds > 0 ? seconds : 0;
    final minutes = clamped ~/ 60;
    final secs = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = remainingSeconds <= 60 && remainingSeconds > 0;
    final isExpired = remainingSeconds <= 0;

    final Color badgeColor;
    final Color textColor;
    final Color iconColor;

    if (isExpired) {
      badgeColor = const Color(0xFFFEF2F2); // red-50
      textColor = const Color(0xFFDC2626);  // red-600
      iconColor = const Color(0xFFDC2626);
    } else if (isExpiringSoon) {
      badgeColor = const Color(0xFFFFFBEB); // amber-50
      textColor = const Color(0xFFD97706);  // amber-600
      iconColor = const Color(0xFFD97706);
    } else {
      badgeColor = const Color(0xFFF0FDF4); // green-50
      textColor = const Color(0xFF16A34A);  // green-600
      iconColor = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.error_outline_rounded : Icons.timer_outlined,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            isExpired ? 'Expirado' : 'Expira em ${_formatDuration(remainingSeconds)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
