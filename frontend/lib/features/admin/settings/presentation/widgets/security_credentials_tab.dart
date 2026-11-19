// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import '../../../../../core/network/authenticated_api_client.dart';
import '../../../../../core/network/auth_profile_remote_data_source.dart';
import '../../../../../core/state/app_user_session.dart';

/// Configuration tab for Administrator Security & Credentials.
///
/// Consulta a conta real e permite alterar a senha e o segundo fator por e-mail.
class SecurityCredentialsTab extends StatefulWidget {
  final AuthProfileRemoteDataSource? profileRemote;

  const SecurityCredentialsTab({super.key, this.profileRemote});

  @override
  State<SecurityCredentialsTab> createState() => _SecurityCredentialsTabState();
}

class _SecurityCredentialsTabState extends State<SecurityCredentialsTab> {
  late final AuthProfileRemoteDataSource _profileRemote =
      widget.profileRemote ?? AuthProfileRemoteDataSource();
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
    String? modalError;
    final values = await AcademicModalDialog.show<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AcademicModalDialog(
          title: 'Alterar senha',
          subtitle:
              'Informe a senha atual e defina uma nova credencial com ao menos 8 caracteres.',
          icon: Icons.vpn_key_outlined,
          maxWidth: 460,
          confirmLabel: 'Salvar',
          onConfirm: () {
            if (current.text.isEmpty) {
              setModalState(() => modalError = 'Informe sua senha atual.');
              return;
            }
            if (next.text.length < 8) {
              setModalState(
                () => modalError = 'A nova senha deve ter ao menos 8 caracteres.',
              );
              return;
            }
            if (next.text != confirm.text) {
              setModalState(() => modalError = 'As novas senhas não coincidem.');
              return;
            }
            Navigator.pop(dialogContext, [current.text, next.text]);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                style: jakarta(size: 13.5, color: InstColors.ink),
                decoration: InstText.inputDecoration(labelText: 'Senha atual'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                style: jakarta(size: 13.5, color: InstColors.ink),
                decoration: InstText.inputDecoration(labelText: 'Nova senha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                obscureText: true,
                style: jakarta(size: 13.5, color: InstColors.ink),
                decoration: InstText.inputDecoration(
                  labelText: 'Confirmar senha',
                ),
              ),
              if (modalError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: InstColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    modalError!,
                    style: jakarta(size: 12.5, color: InstColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final entered = await AcademicModalDialog.show<String>(
      context: context,
      builder: (dialogContext) => AcademicModalDialog(
        title: 'Confirme sua senha',
        subtitle: _twoFactor == true
            ? 'Informe sua senha atual para desativar o segundo fator por e-mail.'
            : 'Informe sua senha atual para ativar o segundo fator por e-mail.',
        icon: Icons.verified_user_outlined,
        maxWidth: 440,
        confirmLabel: 'Confirmar',
        onConfirm: () => Navigator.pop(dialogContext, password.text),
        child: TextField(
          controller: password,
          obscureText: true,
          style: jakarta(size: 13.5, color: InstColors.ink),
          decoration: InstText.inputDecoration(labelText: 'Senha atual'),
        ),
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
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _showBackupCodes() async {
    try {
      final codes = await _profileRemote.backupCodes();
      if (!mounted) return;
      await AcademicModalDialog.show<void>(
        context: context,
        builder: (_) => AcademicModalDialog(
          title: 'Códigos de recuperação',
          subtitle: 'Guarde estes códigos em local seguro para acesso emergencial.',
          icon: Icons.key_outlined,
          maxWidth: 460,
          cancelLabel: 'Fechar',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.border),
            ),
            child: codes.isEmpty
                ? Text(
                    'Nenhum código disponível.',
                    style: jakarta(size: 13, color: InstColors.muted),
                  )
                : SelectableText(
                    codes.join('\n'),
                    style: jakarta(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: InstColors.ink,
                      height: 1.6,
                    ),
                  ),
          ),
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

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_error != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: InstColors.dangerBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: InstColors.danger.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            _error!,
            style: jakarta(size: 13, color: InstColors.danger),
          ),
        ),
      _buildSecurityCard(
        icon: Icons.vpn_key_rounded,
        title: 'Credencial de Acesso (Senha)',
        badgeText: 'Hash bcrypt',
        badgeBg: InstColors.successBg,
        badgeBorder: InstColors.success.withValues(alpha: 0.3),
        badgeTextColor: InstColors.success,
        subtitle: 'Altere sua senha usando a credencial atual.',
        actionButton: ElevatedButton(
          onPressed: _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: InstColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Alterar Senha',
            style: jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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
        badgeBg: InstColors.stoneActive,
        badgeBorder: InstColors.border,
        badgeTextColor: InstColors.ink,
        subtitle: 'Consulte os códigos de recuperação emitidos para sua conta.',
        actionButton: OutlinedButton(
          onPressed: _showBackupCodes,
          style: OutlinedButton.styleFrom(
            foregroundColor: InstColors.ink,
            side: const BorderSide(color: InstColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Consultar códigos',
            style: jakarta(size: 13, weight: FontWeight.w600),
          ),
        ),
        child: Text(
          'Os códigos devem ser armazenados em local seguro.',
          style: jakarta(size: 12.5, color: InstColors.body),
        ),
      ),
      const SizedBox(height: 20),
      _buildSecurityCard(
        icon: Icons.devices_outlined,
        title: 'Sessões e acessos recentes',
        badgeText: 'Gerenciar',
        badgeBg: InstColors.subtle,
        badgeBorder: InstColors.border,
        badgeTextColor: InstColors.body,
        subtitle: 'Revogue sessões que você não reconhece.',
        actionButton: OutlinedButton(
          onPressed: _logoutOthers,
          style: OutlinedButton.styleFrom(
            foregroundColor: InstColors.ink,
            side: const BorderSide(color: InstColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Encerrar outras sessões',
            style: jakarta(size: 13, weight: FontWeight.w600),
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profileRemote.sessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text(
                'Falha ao carregar sessões: ${snapshot.error}',
                style: jakarta(size: 12.5, color: InstColors.danger),
              );
            }
            final sessions = snapshot.data ?? const [];
            if (sessions.isEmpty) {
              return Text(
                'Nenhuma sessão ativa.',
                style: jakarta(size: 12.5, color: InstColors.muted),
              );
            }
            return Column(
              children: sessions.map((session) {
                final id = session['id']?.toString() ?? '';
                final current =
                    session['current'] == true || session['isCurrent'] == true;
                final device = session['device']?.toString().trim();
                final ip = (session['ipAddress'] ?? session['location'])
                    ?.toString()
                    .trim();
                final created = (session['createdAt'] ?? session['lastActive'])
                    ?.toString()
                    .trim();
                final expires = session['expiresAt']?.toString().trim();
                final subtitleParts = <String>[
                  if (ip != null && ip.isNotEmpty) ip,
                  if (created != null && created.isNotEmpty) 'Início: $created',
                  if (expires != null && expires.isNotEmpty) 'Expira: $expires',
                ];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${(device != null && device.isNotEmpty) ? device : 'Dispositivo autenticado'}${current ? ' · Esta sessão' : ''}',
                    style: jakarta(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: InstColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    subtitleParts.isEmpty
                        ? 'Sessão ativa'
                        : subtitleParts.join(' · '),
                    style: jakarta(size: 12, color: InstColors.muted),
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
                              if (mounted) {
                                setState(() => _error = error.message);
                              }
                            }
                          },
                          icon: const Icon(Icons.logout, color: InstColors.ink),
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
        badgeBg: InstColors.subtle,
        badgeBorder: InstColors.border,
        badgeTextColor: InstColors.body,
        subtitle: 'Atividades de segurança recentes da sua conta.',
        actionButton: const SizedBox.shrink(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _profileRemote.securityLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text(
                'Falha ao carregar os registros: ${snapshot.error}',
                style: jakarta(size: 12.5, color: InstColors.danger),
              );
            }
            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) {
              return Text(
                'Nenhum registro disponível.',
                style: jakarta(size: 12.5, color: InstColors.muted),
              );
            }
            return Column(
              children: logs
                  .map(
                    (log) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${log['action'] ?? log['event'] ?? 'Atividade de segurança'}',
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: InstColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        '${log['createdAt'] ?? log['timestamp'] ?? ''}',
                        style: jakarta(size: 12, color: InstColors.muted),
                      ),
                    ),
                  )
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
        badgeBg: _twoFactor == true ? InstColors.successBg : InstColors.stoneActive,
        badgeBorder: _twoFactor == true
            ? InstColors.success.withValues(alpha: 0.3)
            : InstColors.border,
        badgeTextColor: _twoFactor == true ? InstColors.success : InstColors.ink,
        subtitle:
            'Código de acesso enviado ao e-mail cadastrado, após validar a senha.',
        actionButton: OutlinedButton(
          onPressed: _twoFactor == null ? null : _toggleTwoFactor,
          style: OutlinedButton.styleFrom(
            foregroundColor: InstColors.ink,
            side: const BorderSide(color: InstColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _twoFactor == true ? 'Desativar' : 'Ativar',
            style: jakarta(size: 13, weight: FontWeight.w600),
          ),
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
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
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
                  color: InstColors.ink,
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
                          style: jakarta(
                            size: 15.5,
                            weight: FontWeight.w700,
                            color: InstColors.ink,
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
                            style: jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: jakarta(size: 12, color: InstColors.muted),
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
          style: jakarta(
            size: 12.5,
            weight: FontWeight.w700,
            color: isHighlightGreen ? InstColors.success : InstColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: jakarta(size: 11, color: InstColors.muted),
        ),
      ],
    );
  }
}
