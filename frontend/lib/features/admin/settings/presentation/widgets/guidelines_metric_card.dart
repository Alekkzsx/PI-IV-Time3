// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card de métrica e parâmetro regimental com controles de incremento e badge explicativa.
class GuidelinesMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String badgeText;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeTextColor;
  final String subtitle;
  final TextEditingController controller;
  final String? suffixText;
  final String footerText;

  const GuidelinesMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeTextColor,
    required this.subtitle,
    required this.controller,
    this.suffixText,
    required this.footerText,
  });

  void _step(int delta) {
    final val = double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
    final next = (val + delta).clamp(0, 100);
    controller.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: InstColors.body,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  badgeText,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: jakarta(size: 11.5, color: InstColors.muted, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: InstColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.borderStrong),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: jakarta(
                      size: 15,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (suffixText != null) ...[
                  Text(
                    suffixText!,
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: InstColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => _step(1),
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: InstColors.muted,
                      ),
                    ),
                    InkWell(
                      onTap: () => _step(-1),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: InstColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            footerText,
            style: jakarta(size: 11, color: InstColors.faint),
          ),
        ],
      ),
    );
  }
}
