// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Badge visual institucional que atesta a validação de integridade criptográfica SHA-256 de um recibo.
class StudentIntegrityBadge extends StatelessWidget {
  final String sha256;
  final bool isVerified;

  const StudentIntegrityBadge({
    super.key,
    required this.sha256,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayHash = sha256.length > 16
        ? '${sha256.substring(0, 8)}...${sha256.substring(sha256.length - 8)}'
        : sha256;

    final badgeColor = isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bgColor = isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final borderColor = isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_user_outlined : Icons.gpp_bad_outlined,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'SHA-256 Verificado: $displayHash' : 'Falha de Integridade: $displayHash',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
