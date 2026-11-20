// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card molecular para exportação de dados pessoais e conformidade LGPD.
class LgpdDataExportCard extends StatelessWidget {
  final Future<void> Function({required bool asJson}) onExportData;

  const LgpdDataExportCard({
    super.key,
    required this.onExportData,
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
          Text(
            'Privacidade & Direitos do Titular (LGPD)',
            style: jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), você pode gerenciar e auditar todos os seus dados pessoais armazenados na plataforma.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),

          // Aviso Legal LGPD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: Color(0xFF18181B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seus dados são utilizados exclusivamente para fins acadêmicos, registro funcional e cumprimento das obrigações com o Ministério da Educação (MEC). Nós não compartilhamos informações com terceiros para fins comerciais.',
                    style: jakarta(
                      size: 11.5,
                      color: const Color(0xFF52525B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Exportar Relatório de Dados Cadastrais & Histórico
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exportar Relatório de Dados Cadastrais & Histórico',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Faça o download de uma cópia completa dos seus dados funcionais, históricos de turmas e logs de atividades acadêmicas registradas em sua conta.',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onExportData(asJson: true),
                      icon: const Icon(
                        Icons.data_object_rounded,
                        size: 15,
                        color: Color(0xFF18181B),
                      ),
                      label: Text(
                        'Arquivo JSON',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE4E4E7)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => onExportData(asJson: false),
                      icon: const Icon(
                        Icons.description_outlined,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Relatório (.txt)',
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
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
