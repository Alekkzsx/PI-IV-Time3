// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção que exibe os alertas urgentes da Secretaria e avisos de fechamento de período.
class AdminSecretariatAlertsSection extends StatelessWidget {
  const AdminSecretariatAlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Alertas da Secretaria',
              style: jakarta(
                size: 24,
                weight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'HOJE, 20 SET',
              style: jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: const Color(0xFF737373),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: const Color(0xFF1A1A1A)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 22,
                        right: 22,
                        bottom: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE4E4E7),
                                  ),
                                ),
                                child: Text(
                                  'Mesa de Análise',
                                  style: jakarta(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4E4E7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '• 2 PENDENTES',
                                  style: jakarta(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Requerimentos Discentes',
                            style: jakarta(
                              size: 18,
                              weight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.article_outlined,
                                size: 16,
                                color: Color(0xFFA3A3A3),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Atestados médicos, 2ª chamada e horas',
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 13.5,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF737373),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 22,
                      color: Color(0xFF737373),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fechamento do Período',
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Trava regimental de diários e atas em 12 dias',
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
