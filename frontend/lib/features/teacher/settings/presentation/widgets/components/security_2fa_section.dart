// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/domain/models/docente_profile.dart';

/// Seção atômica para configuração e alternância de autenticação em duas etapas (2FA).
class Security2faSection extends StatelessWidget {
  final DocenteProfile profile;
  final Future<void> Function() onToggle2fa;

  const Security2faSection({
    super.key,
    required this.profile,
    required this.onToggle2fa,
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF18181B),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Autenticação em Duas Etapas (2FA)',
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
                          profile.twoFactorEnabled ? 'Ativado' : 'Desativado',
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
              OutlinedButton(
                onPressed: onToggle2fa,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  profile.twoFactorEnabled ? 'Desativar 2FA' : 'Ativar 2FA',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Exige um código de 6 dígitos gerado no seu celular ao realizar login.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método Configurado:',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aplicativo TOTP (Authenticator)',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      profile.twoFactorEnabled
                          ? 'Autenticação de dois fatores habilitada.'
                          : 'Autenticação de dois fatores desabilitada.',
                      style: jakarta(
                        size: 10.5,
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status de Proteção:',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conta Blindada contra Phishing',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      'Desativação exige autorização com senha e token.',
                      style: jakarta(
                        size: 10.5,
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
