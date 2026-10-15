// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../policies/generic_feedback_policy.dart';

/// Presentation widget displaying an interactive lockout countdown banner.
/// Visualizes the 30-second cooldown period when the user triggers brute-force rate limiting.
class LockoutCountdownBanner extends StatelessWidget {
  /// Remaining lockout duration in seconds.
  final int remainingSeconds;

  /// Optional custom message override.
  final String? customMessage;

  const LockoutCountdownBanner({
    super.key,
    required this.remainingSeconds,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds <= 0) {
      return const SizedBox.shrink();
    }

    final displayText = customMessage ??
        GenericFeedbackPolicy.lockoutCountdownMessage(remainingSeconds);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // red-50
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFCA5A5), // red-300
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            size: 20,
            color: Color(0xFFDC2626), // red-600
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B), // red-800
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
