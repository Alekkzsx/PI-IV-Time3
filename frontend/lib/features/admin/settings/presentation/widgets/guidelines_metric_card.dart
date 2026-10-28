// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF475569),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        final val = double.tryParse(controller.text) ?? 0;
                        controller.text = (val + 1).toInt().toString();
                      },
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final val = double.tryParse(controller.text) ?? 0;
                        if (val > 0) {
                          controller.text = (val - 1).toInt().toString();
                        }
                      },
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Color(0xFF64748B),
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
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

