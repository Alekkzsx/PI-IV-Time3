// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de configuração de Segurança & Credenciais do Administrador.
///
/// Gerencia criptografia de credenciais (SHA-256), autenticação em dois fatores (2FA TOTP),
/// chaves de recuperação descartáveis e políticas Zero-Trust.
class SecurityCredentialsTab extends StatefulWidget {
  const SecurityCredentialsTab({super.key});

  @override
  State<SecurityCredentialsTab> createState() => _SecurityCredentialsTabState();
}

class _SecurityCredentialsTabState extends State<SecurityCredentialsTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Credencial de Acesso (Senha)
        _buildSecurityCard(
          icon: Icons.vpn_key_rounded,
          title: 'Credencial de Acesso (Senha)',
          badgeText: 'Protegida',
          badgeBg: const Color(0xFFECFDF5),
          badgeBorder: const Color(0xFFA7F3D0),
          badgeTextColor: const Color(0xFF059669),
          subtitle: 'Utilizada para entrar no AVA, Portal Acadêmico e serviços da Instituição.',
          actionButton: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fluxo de alteração de senha inicializado.')),
              );
            },
            icon: const Icon(Icons.lock_reset, size: 16),
            label: const Text('Alterar Senha', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoColumn(
                                'Complexidade da Senha: Forte (Criptografia SHA-256)',
                                'Cumpre os requisitos institucionais de segurança',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoColumn(
                                'Última Atualização: Há 38 dias',
                                'Recomendação: renovar a cada 90 dias',
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildInfoColumn(
                                  'Complexidade da Senha: Forte (Criptografia SHA-256)',
                                  'Cumpre os requisitos institucionais de segurança',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildInfoColumn(
                                  'Última Atualização: Há 38 dias',
                                  'Recomendação: renovar a cada 90 dias',
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 15, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'A troca de senha exige confirmação da sua senha atual e validação em dois fatores.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Autenticação em Duas Etapas (2FA)
        _buildSecurityCard(
          icon: Icons.verified_user_rounded,
          title: 'Autenticação em Duas Etapas (2FA)',
          badgeText: 'Ativado',
          badgeBg: const Color(0xFF0F172A),
          badgeBorder: const Color(0xFF0F172A),
          badgeTextColor: Colors.white,
          subtitle: 'Exige um código de 6 dígitos gerado no seu celular ao realizar login.',
          actionButton: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Confirmação de segurança necessária para desativar 2FA.')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECACA)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Desativar 2FA', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoColumn(
                            'Método Configurado: Aplicativo TOTP (Authenticator)',
                            'Ativado em 15 de Agosto de 2026',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoColumn(
                            'Status de Proteção: Conta Blindada contra Phishing',
                            'Desativação exige autorização com senha e token.',
                            isHighlightGreen: true,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildInfoColumn(
                              'Método Configurado: Aplicativo TOTP (Authenticator)',
                              'Ativado em 15 de Agosto de 2026',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildInfoColumn(
                              'Status de Proteção: Conta Blindada contra Phishing',
                              'Desativação exige autorização com senha e token.',
                              isHighlightGreen: true,
                            ),
                          ),
                        ],
                      );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. Códigos de Recuperação (Backup)
        _buildSecurityCard(
          icon: Icons.key_outlined,
          title: 'Códigos de Recuperação (Backup)',
          badgeText: '8 disponíveis',
          badgeBg: const Color(0xFF0F172A),
          badgeBorder: const Color(0xFF0F172A),
          badgeTextColor: Colors.white,
          subtitle: 'Chaves de segurança descartáveis para login caso você não tenha acesso ao seu smartphone.',
          actionButton: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reautenticação necessária para gerenciar chaves.')),
              );
            },
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Gerenciar Códigos', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fluxo de Proteção Zero-Trust: Para sua segurança, a visualização ou regeneração dos códigos de backup exige reautenticação imediata por senha.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeTextColor,
    required String subtitle,
    required Widget actionButton,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              actionButton,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String subtitle, {bool isHighlightGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isHighlightGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
