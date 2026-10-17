// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Presentation widget displaying a synchronized countdown timer for ephemeral recovery tokens.
/// Visualizes the 5-minute (300 seconds) Time-To-Live in MM:SS format with warning states.
class TokenTimerWidget extends StatelessWidget {
  /// Remaining time in seconds before the recovery token expires.
  final int remainingSeconds;

  const TokenTimerWidget({
    super.key,
    required this.remainingSeconds,
  });

  /// Formats seconds into MM:SS representation.
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
