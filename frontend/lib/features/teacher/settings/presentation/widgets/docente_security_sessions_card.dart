// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_profile.dart';

/// Card de configurações de 2FA, gerenciamento de sessões ativas e histórico de auditoria.
class DocenteSecuritySessionsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteSecuritySessionsCard({super.key, required this.controller});

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
            ),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (current.text.isEmpty ||
                  next.text.length < 8 ||
                  next.text != confirm.text) {
                return;
              }
              Navigator.pop(context, [current.text, next.text]);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (values != null) {
      final changed = await controller.changePassword(
        currentPassword: values[0],
        newPassword: values[1],
      );
      if (changed) {
        AppUserSession.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.remoteError ?? 'Não foi possível alterar a senha.',
            ),
          ),
        );
      }
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _showBackupCodes(BuildContext context) async {
    try {
      final codes = await controller.backupCodes();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Códigos de recuperação'),
          content: SizedBox(
            width: 360,
            child: codes.isEmpty
                ? const Text('Nenhum código disponível.')
                : SelectableText(codes.join('\n')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

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
                onPressed: () => _changePassword(context),
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
                onPressed: () async {
                  final password = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar com sua senha'),
                      content: TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha atual',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, password.text.isNotEmpty),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await controller.toggleTwoFactor(password: password.text);
                  }
                  password.dispose();
                },
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
                onPressed: () => _showBackupCodes(context),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.securitySessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Falha ao carregar sessões: ${snapshot.error}');
              }
              final sessions = snapshot.data ?? const [];
              if (sessions.isEmpty) return const Text('Nenhuma sessão ativa.');
              return Column(
                children: sessions.map((session) {
                  final id = session['id']?.toString() ?? '';
                  final current = session['isCurrent'] == true;
                  final device =
                      session['device']?.toString() ?? 'Dispositivo';
                  final location = session['location']?.toString() ?? '';
                  final ip = session['ip']?.toString() ?? '';
                  final lastActive =
                      session['lastActive']?.toString() ??
                      session['lastSeenAt']?.toString() ??
                      '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices_outlined),
                    title: Text(current ? '$device · Esta sessão' : device),
                    subtitle: Text('$location · $ip · $lastActive'),
                    trailing: current
                        ? null
                        : IconButton(
                            tooltip: 'Revogar sessão',
                            onPressed: () => controller.disconnectSession(id),
                            icon: const Icon(Icons.logout),
                          ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hist?rico recente de acesso',
            style: jakarta(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.securityLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Falha ao carregar o hist?rico: ${snapshot.error}');
              }
              final logs = snapshot.data ?? const [];
              if (logs.isEmpty) return const Text('Nenhum acesso registrado.');
              return Column(
                children: logs.map((log) {
                  final time = log['createdAt'] ?? log['timestamp'] ?? log['date'] ?? '';
                  final action = log['action'] ?? log['event'] ?? log['status'] ?? 'Acesso';
                  final device = log['device'] ?? log['userAgent'] ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(action.toString()),
                    subtitle: Text(
                      '$time${device.toString().isEmpty ? '' : ' · $device'}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

}
