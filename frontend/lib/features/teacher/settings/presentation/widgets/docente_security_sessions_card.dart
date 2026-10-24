// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_profile.dart';

/// Card de configurações de 2FA, gerenciamento de sessões ativas e histórico de auditoria.
class DocenteSecuritySessionsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteSecuritySessionsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Credencial de Acesso (Senha)
        _buildPasswordCard(context),
        const SizedBox(height: 20),

        // 2. Autenticação em Duas Etapas (2FA)
        _buildTwoFactorCard(context, profile),
        const SizedBox(height: 20),

        // 3. Códigos de Recuperação (Backup)
        _buildBackupCodesCard(context),
        const SizedBox(height: 20),

        // 4. Sessões Ativas & Dispositivos Conectados
        _buildActiveSessionsCard(context, profile),
        const SizedBox(height: 20),

        // 5. Histórico Recente de Acesso (Auditoria de Segurança)
        _buildAuditLogsCard(context),
      ],
    );
  }

  Widget _buildPasswordCard(BuildContext context) {
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
                onPressed: () {},
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

  Widget _buildTwoFactorCard(BuildContext context, DocenteProfile profile) {
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
                onPressed: () => controller.toggleTwoFactor(),
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
                      'Ativado em 15 de Agosto de 2026',
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

  Widget _buildBackupCodesCard(BuildContext context) {
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
                          '8 disponíveis',
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
                onPressed: () {},
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

  Widget _buildActiveSessionsCard(
    BuildContext context,
    DocenteProfile profile,
  ) {
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
                    Icons.language_rounded,
                    size: 18,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sessões Ativas & Dispositivos Conectados',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => controller.disconnectOtherSessions(),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 12,
                  color: Color(0xFFDC2626),
                ),
                label: Text(
                  'Encerrar Outras Sessões',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
            'Dispositivos com acesso autorizado à sua conta no AVA e Portal do Aluno.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          ...profile.activeSessions.map((session) {
            final isMobile =
                session.device.toLowerCase().contains('iphone') ||
                session.device.toLowerCase().contains('android') ||
                session.device.toLowerCase().contains('mobile');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                children: [
                  Icon(
                    isMobile
                        ? Icons.smartphone_rounded
                        : Icons.laptop_mac_rounded,
                    size: 20,
                    color: const Color(0xFF52525B),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              session.device,
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            if (session.isCurrent) ...[
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
                                  'ESTA SESSÃO',
                                  style: jakarta(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.location} • IP ${session.ip} • ${session.lastActive}',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!session.isCurrent)
                    OutlinedButton(
                      onPressed: () => controller.disconnectSession(session.id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4D4D8)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Desconectar',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAuditLogsCard(BuildContext context) {
    final auditLogs = [
      {
        'data': '22/09/2026 às 08:14',
        'device': 'Chrome / Windows 11',
        'local': 'São Paulo, Brasil',
        'ip': '177.136.***.42',
        'status': 'Autorizado',
      },
      {
        'data': '21/09/2026 às 20:30',
        'device': 'Safari / iPhone 15',
        'local': 'São Paulo, Brasil',
        'ip': '189.40.***.118',
        'status': 'Autorizado',
      },
      {
        'data': '21/09/2026 às 18:45',
        'device': 'Firefox / Linux',
        'local': 'Campinas, Brasil',
        'ip': '201.82.***.93',
        'status': 'Autorizado',
      },
      {
        'data': '19/09/2026 às 23:10',
        'device': 'Desconhecido / Android',
        'local': 'Belo Horizonte, Brasil',
        'ip': '45.178.***.12',
        'status': 'Bloqueado',
      },
      {
        'data': '19/09/2026 às 14:02',
        'device': 'Chrome / Windows 11',
        'local': 'São Paulo, Brasil',
        'ip': '177.136.***.42',
        'status': 'Autorizado',
      },
    ];

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
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: Color(0xFF18181B),
              ),
              const SizedBox(width: 8),
              Text(
                'Histórico Recente de Acesso (Auditoria de Segurança)',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Registro dos últimos logins efetuados com suas credenciais para monitoramento preventivo.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          // Audit Table
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF4F4F5), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('DATA & HORA', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('DISPOSITIVO', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('LOCALIZAÇÃO ESTIMADA', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('ENDEREÇO IP', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STATUS', style: _tableHeaderStyle),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auditLogs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final log = auditLogs[index];
              final isBloqueado = log['status'] == 'Bloqueado';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        log['data']!,
                        style: jakarta(
                          size: 11.5,
                          color: const Color(0xFF52525B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        log['device']!,
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        log['local']!,
                        style: jakarta(
                          size: 11.5,
                          color: const Color(0xFF52525B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log['ip']!,
                        style: jakarta(
                          size: 11.5,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            isBloqueado
                                ? Icons.cancel_outlined
                                : Icons.check_rounded,
                            size: 14,
                            color: isBloqueado
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log['status']!,
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w600,
                              color: isBloqueado
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF71717A),
  );
}
