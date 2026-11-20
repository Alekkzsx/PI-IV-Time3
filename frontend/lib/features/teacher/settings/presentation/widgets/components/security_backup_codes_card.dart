// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card atômico para gerenciamento seguro de códigos de recuperação (backup).
class SecurityBackupCodesCard extends StatelessWidget {
  final VoidCallback onManageCodes;

  const SecurityBackupCodesCard({
    super.key,
    required this.onManageCodes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.key_outlined,
                    size: 20,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Códigos de Recuperação (Backup)',
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Códigos protegidos',
                          style: jakarta(
                            size: 10,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: onManageCodes,
                icon: const Icon(
                  Icons.vpn_key_outlined,
                  size: 13,
                  color: Color(0xFF18181B),
                ),
                label: Text(
                  'Gerenciar Códigos',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4D4D8)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chaves de segurança descartáveis para login caso você não tenha acesso ao seu smartphone.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF4F4F5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fluxo de Proteção Zero-Trust: Para sua segurança, a visualização ou regeneração dos códigos de backup exige reautenticação imediata por senha.',
                    style: jakarta(size: 11, color: const Color(0xFF71717A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
