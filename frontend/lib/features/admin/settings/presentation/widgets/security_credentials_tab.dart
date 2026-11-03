// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import '../../../../../core/network/auth_profile_remote_data_source.dart';
import '../../../../../core/state/app_user_session.dart';

/// Configuration tab for Administrator Security & Credentials.
///
/// Consulta a conta real e permite alterar a senha e o segundo fator por e-mail.
class SecurityCredentialsTab extends StatefulWidget {
  const SecurityCredentialsTab({super.key});

  @override
  State<SecurityCredentialsTab> createState() => _SecurityCredentialsTabState();
}

class _SecurityCredentialsTabState extends State<SecurityCredentialsTab> {
  final _profileRemote = AuthProfileRemoteDataSource();
  bool? _twoFactor;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    if (AppUserSession.instance.accessToken == null) return;
    try {
      final user = await _profileRemote.me();
      if (mounted) {
        setState(
          () => _twoFactor =
              user['twoFactorEnabled'] == true ||
              user['twoFactorRequired'] == true,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _changePassword() async {
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
            TextField(controller: current, obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual')),
            TextField(controller: next, obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha')),
            TextField(controller: confirm, obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (next.text.length < 8 || next.text != confirm.text) return;
              Navigator.pop(context, [current.text, next.text]);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (values != null) {
      try {
        await _profileRemote.changePassword(
          currentPassword: values[0],
          newPassword: values[1],
        );
        AppUserSession.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } on ApiException catch (error) {
        if (mounted) setState(() => _error = error.message);
      }
    }
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _toggleTwoFactor() async {
    final password = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirme sua senha'),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, password.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    password.dispose();
    if (entered == null || !mounted) return;
    try {
      await _profileRemote.toggleTwoFactor(
        password: entered,
        enabled: _twoFactor != true,
      );
      AppUserSession.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

      Future<void> _showBackupCodes() async {
        try {
          final codes = await _profileRemote.backupCodes();
          if (!mounted) return;
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
        } on ApiException catch (error) {
          if (mounted) setState(() => _error = error.message);
        }
      }

      Future<void> _logoutOthers() async {
        try {
          await _profileRemote.logoutOthers();
          if (mounted) setState(() {});
        } on ApiException catch (error) {
          if (mounted) setState(() => _error = error.message);
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      _buildSecurityCard(
        icon: Icons.vpn_key_rounded,
        title: 'Credencial de Acesso (Senha)',
        badgeText: 'Hash bcrypt',
        badgeBg: const Color(0xFFECFDF5),
        badgeBorder: const Color(0xFFA7F3D0),
        badgeTextColor: const Color(0xFF059669),
        subtitle: 'Altere sua senha usando a credencial atual.',
        actionButton: FilledButton(
          onPressed: _changePassword,
          child: const Text('Alterar Senha'),
        ),
        child: _buildInfoColumn(
          'Senhas protegidas com bcrypt',
          'A troca da senha encerra as sessões anteriores.',
        ),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.key_outlined,
        title: 'Códigos de recuperação',
        badgeText: 'Protegidos',
        badgeBg: const Color(0xFFEFF6FF),
        badgeBorder: const Color(0xFFBFDBFE),
        badgeTextColor: const Color(0xFF1D4ED8),
        subtitle: 'Consulte os códigos de recuperação emitidos para sua conta.',
        actionButton: OutlinedButton(
          onPressed: _showBackupCodes,
          child: const Text('Consultar códigos'),
        ),
        child: const Text('Os códigos devem ser armazenados em local seguro.'),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.devices_outlined,
        title: 'Sessões e acessos recentes',
        badgeText: 'Gerenciar',
        badgeBg: const Color(0xFFF1F5F9),
        badgeBorder: const Color(0xFFE2E8F0),
        badgeTextColor: const Color(0xFF334155),
        subtitle: 'Revogue sessões que você não reconhece.',
        actionButton: OutlinedButton(
          onPressed: _logoutOthers,
          child: const Text('Encerrar outras sessões'),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profileRemote.sessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
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
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${session['device'] ?? 'Dispositivo'}${current ? ' · Esta sessão' : ''}',
                  ),
                  subtitle: Text(
                    '${session['location'] ?? ''} · ${session['lastActive'] ?? ''}',
                  ),
                  trailing: current
                      ? null
                      : IconButton(
                          tooltip: 'Revogar sessão',
                          onPressed: () async {
                            try {
                              await _profileRemote.revokeSession(id);
                              if (mounted) setState(() {});
                            } on ApiException catch (error) {
                              if (mounted) setState(() => _error = error.message);
                            }
                          },
                          icon: const Icon(Icons.logout),
                        ),
                );
              }).toList(),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.history,
        title: 'Registros de segurança',
        badgeText: 'Auditoria',
        badgeBg: const Color(0xFFF1F5F9),
        badgeBorder: const Color(0xFFE2E8F0),
        badgeTextColor: const Color(0xFF334155),
        subtitle: 'Atividades de segurança recentes da sua conta.',
        actionButton: const SizedBox.shrink(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profileRemote.securityLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Falha ao carregar os registros: ${snapshot.error}');
            }
            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) return const Text('Nenhum registro disponível.');
            return Column(
              children: logs
                  .map((log) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${log['action'] ?? log['event'] ?? 'Atividade de segurança'}',
                        ),
                        subtitle: Text(
                          '${log['createdAt'] ?? log['timestamp'] ?? ''}',
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.verified_user_outlined,
        title: 'Autenticação em Duas Etapas (2FA)',
        badgeText: _twoFactor == null
            ? 'Consultar conta'
            : _twoFactor!
            ? 'Ativada'
            : 'Desativada',
        badgeBg: const Color(0xFFEFF6FF),
        badgeBorder: const Color(0xFFBFDBFE),
        badgeTextColor: const Color(0xFF1D4ED8),
        subtitle:
            'Código de acesso enviado ao e-mail cadastrado, após validar a senha.',
        actionButton: OutlinedButton(
          onPressed: _twoFactor == null ? null : _toggleTwoFactor,
          child: Text(_twoFactor == true ? 'Desativar' : 'Ativar'),
        ),
        child: _buildInfoColumn(
          'Código temporário de seis dígitos',
          'Validade de cinco minutos e três tentativas. Requer envio de e-mail configurado.',
        ),
      ),
    ],
  );

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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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

  Widget _buildInfoColumn(
    String title,
    String subtitle, {
    bool isHighlightGreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isHighlightGreen
                ? const Color(0xFF059669)
                : const Color(0xFF0F172A),
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
