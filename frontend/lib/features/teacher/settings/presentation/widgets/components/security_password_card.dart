// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card atômico para gerenciamento da credencial de acesso institucional (senha).
class SecurityPasswordCard extends StatelessWidget {
  final VoidCallback onChangePassword;

  const SecurityPasswordCard({
    super.key,
    required this.onChangePassword,
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
                      Icons.key_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        'Credencial de Acesso (Senha)',
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
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          'Protegida',
                          style: jakarta(
                            size: 10,
                            weight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onChangePassword,
                icon: const Icon(
                  Icons.lock_reset_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(
                  'Alterar Senha',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Utilizada para entrar no AVA, Portal Acadêmico e serviços da instituição.',
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
                      'Complexidade da Senha:',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Forte (Criptografia SHA-256)',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      'Cumpre os requisitos institucionais de segurança',
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
                      'Última Atualização:',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Há 38 dias',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      'Recomendação: renovar a cada 90 dias',
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
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF71717A),
              ),
              const SizedBox(width: 6),
              Text(
                'A troca de senha exige confirmação da sua senha atual e validação em dois fatores.',
                style: jakarta(size: 11, color: const Color(0xFF71717A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
