// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agmrm_security/security.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava/common/ava_standard_modal.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/settings_common_widgets.dart';

/// [SecuritySessionsCard]
///
/// Componente de gestão de segurança avançada, sessões ativas e autenticação multifator (2FA).
/// Permite ativar/desativar 2FA com emissão de códigos de backup de recuperação,
/// revogação individual ou global de sessões ativas em dispositivos e auditoria de logs de acesso.
class SecuritySessionsCard extends StatefulWidget {
  /// Controlador reativo do portal para manipulação de flags de segurança.
  final StudentPortalController controller;

  /// Cria uma nova instância de [SecuritySessionsCard].
  const SecuritySessionsCard({super.key, required this.controller});

  @override
  State<SecuritySessionsCard> createState() =>
      _StudentSecuritySessionsCardState();
}

class _StudentSecuritySessionsCardState
    extends State<SecuritySessionsCard> {
  final AuthProfileRemoteDataSource _remote = AuthProfileRemoteDataSource();
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _logs = [];
  List<String> _backupCodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _loading = true);
    try {
      final result = await Future.wait([
        _remote.sessions(),
        _remote.securityLogs(),
        _remote.me(),
      ]);
      if (!mounted) return;
      setState(() {
        _sessions = result[0] as List<Map<String, dynamic>>;
        _logs = result[1] as List<Map<String, dynamic>>;
        widget.controller.setTwoFactorEnabled(
          (result[2] as Map<String, dynamic>)['twoFactorRequired'] == true,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String newPasswordText = '';

    final accepted = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isEntropyValid = PasswordEntropyValidator.isEligibleForSubmission(
            newPasswordText,
          );
          final passwordsMatch =
              newPasswordText.isNotEmpty && newPasswordText == confirm.text;

          return AvaStandardModal(
            overlineTag: 'CREDENCIAIS DE ACESSO',
            title: 'Alterar Senha Institucional',
            subtitle:
                'Por segurança, a atualização encerrará a sessão ativa neste dispositivo.',
            maxWidth: 460,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: settingsOutlinedButtonStyle(),
                child: Text(
                  'Cancelar',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isEntropyValid && passwordsMatch
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                style: settingsPrimaryButtonStyle(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Salvar Nova Senha',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: isEntropyValid && passwordsMatch
                        ? Colors.white
                        : const Color(0xFF71717A),
                  ),
                ),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: buildSettingsInputDecoration(
                    labelText: 'Senha atual',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: next,
                  obscureText: true,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  onChanged: (val) {
                    setDialogState(() {
                      newPasswordText = val;
                    });
                  },
                  decoration: buildSettingsInputDecoration(
                    labelText: 'Nova senha',
                  ),
                ),
                const SizedBox(height: 12),
                StudentPasswordEntropyMeter(password: newPasswordText),
                const SizedBox(height: 14),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: buildSettingsInputDecoration(
                    labelText: 'Confirmar nova senha',
                    errorText: confirm.text.isNotEmpty && !passwordsMatch
                        ? 'As senhas não coincidem'
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (accepted != true) {
      current.dispose();
      next.dispose();
      confirm.dispose();
      return;
    }

    if (!StudentActionRateLimiter.instance.canExecute(
      StudentActionType.changePassword,
    )) {
      final cooldown = StudentActionRateLimiter.instance
          .getRemainingCooldownSeconds(StudentActionType.changePassword);
      _showMessage('Limite de trocas de senha atingido. Aguarde $cooldown s.');
      current.dispose();
      next.dispose();
      confirm.dispose();
      return;
    }

    try {
      final sanitizedCurrent = InputSanitizer.sanitizePassword(current.text);
      final sanitizedNext = InputSanitizer.sanitizePassword(next.text);

      await _remote.changePassword(
        currentPassword: sanitizedCurrent,
        newPassword: sanitizedNext,
      );
      StudentActionRateLimiter.instance.recordAction(
        StudentActionType.changePassword,
      );
      _showMessage('Senha alterada com sucesso.');
    } catch (error) {
      _showMessage(GenericFeedbackPolicy.sanitizeErrorMessage(error));
    } finally {
      current.dispose();
      next.dispose();
      confirm.dispose();
    }
  }

  Future<void> _toggleTwoFactor(bool enabled) async {
    final password = TextEditingController();
    final accepted = await AvaStandardModal.show<bool>(
      context: context,
      overlineTag: 'VERIFICAÇÃO EM DUAS ETAPAS',
      title: enabled
          ? 'Ativar autenticação em duas etapas'
          : 'Desativar autenticação em duas etapas',
      subtitle:
          'Informe sua senha atual para confirmar a alteração desta proteção.',
      maxWidth: 440,
      builder: (dialogContext) => TextField(
        controller: password,
        obscureText: true,
        style: jakarta(size: 13, color: const Color(0xFF18181B)),
        decoration: buildSettingsInputDecoration(
          labelText: 'Confirme sua senha',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: settingsOutlinedButtonStyle(),
          child: Text(
            'Cancelar',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: settingsPrimaryButtonStyle(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: Text(
            'Confirmar',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );

    if (accepted == true) {
      try {
        await _remote.toggleTwoFactor(
          password: password.text,
          enabled: enabled,
        );
        widget.controller.setTwoFactorEnabled(enabled);
      } catch (error) {
        _showMessage(error.toString());
      }
    }
    password.dispose();
  }

  Future<void> _generateBackupCodes() async {
    try {
      final codes = await _remote.backupCodes();
      if (!mounted) return;
      setState(() => _backupCodes = codes);
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _revokeSession(String id) async {
    try {
      await _remote.revokeSession(id);
      await _loadSecurityData();
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _logoutOthers() async {
    try {
      await _remote.logoutOthers();
      await _loadSecurityData();
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.controller.isTwoFactorEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionCard(
          icon: Icons.shield_outlined,
          title: 'Segurança da conta',
          subtitle:
              'Gerencie sua senha institucional e a proteção adicional de acesso por código em duas etapas.',
          child: Column(
            children: [
              SettingsRowTile(
                icon: Icons.password_outlined,
                title: 'Senha de acesso',
                subtitle: 'A alteração encerra esta sessão.',
                trailing: OutlinedButton.icon(
                  onPressed: _changePassword,
                  style: settingsOutlinedButtonStyle(),
                  icon: const Icon(
                    Icons.lock_reset_rounded,
                    size: 15,
                    color: Color(0xFF18181B),
                  ),
                  label: Text(
                    'Alterar senha',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SettingsRowTile(
                icon: Icons.verified_user_outlined,
                darkIconBadge: enabled,
                title: 'Autenticação em duas etapas',
                subtitle: enabled
                    ? 'Solicita código de verificação adicional a cada novo login.'
                    : 'Adicione uma camada extra de proteção com código temporário por e-mail.',
                titleBadge: SettingsStatusPill(
                  label: enabled ? 'Ativa' : 'Desativada',
                  variant: enabled
                      ? SettingsPillVariant.success
                      : SettingsPillVariant.neutral,
                ),
                trailing: Switch(
                  value: enabled,
                  onChanged: _loading ? null : _toggleTwoFactor,
                  activeTrackColor: const Color(0xFF16A34A),
                  activeThumbColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          icon: Icons.key_outlined,
          title: 'Códigos de backup',
          subtitle:
              'Chaves descartáveis de emergência para recuperar o acesso caso não consiga receber o código por e-mail.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsRowTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Códigos de recuperação',
                subtitle: 'Gerados pelo serviço de autenticação.',
                trailing: OutlinedButton(
                  onPressed: _generateBackupCodes,
                  style: settingsOutlinedButtonStyle(),
                  child: Text(
                    'Gerar',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
              if (_backupCodes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _backupCodes.map((code) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE4E4E7)),
                            ),
                            child: SelectableText(
                              code,
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _backupCodes.join('\n')),
                          );
                          _showMessage('Códigos copiados.');
                        },
                        style: settingsOutlinedButtonStyle(),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Color(0xFF18181B),
                        ),
                        label: Text(
                          'Copiar códigos',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          icon: Icons.devices_outlined,
          title: 'Sessões ativas',
          subtitle:
              'Dispositivos atualmente conectados à sua conta institucional.',
          headerTrailing: OutlinedButton.icon(
            onPressed: _loading ? null : _logoutOthers,
            style: settingsDangerOutlinedButtonStyle(),
            icon: const Icon(
              Icons.logout_rounded,
              size: 14,
              color: Color(0xFFB91C1C),
            ),
            label: Text(
              'Encerrar outras',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w600,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consultando sessões ativas no servidor...',
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_sessions.isEmpty)
                _emptyStateBox(
                  icon: Icons.devices_fold_outlined,
                  text: 'Nenhuma sessão ativa retornada.',
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < _sessions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _buildSessionTile(_sessions[i]),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          icon: Icons.history_rounded,
          title: 'Registros de segurança',
          subtitle:
              'Histórico recente de autenticações e eventos críticos da sua conta.',
          child: _logs.isEmpty
              ? _emptyStateBox(
                  icon: Icons.history_toggle_off_rounded,
                  text: 'Nenhum registro disponível.',
                )
              : Column(
                  children: [
                    for (int i = 0; i < _logs.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 24, color: Color(0xFFF4F4F5)),
                      _buildAuditLogRow(_logs[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session) {
    final rawDevice = session['device']?.toString() ?? 'Dispositivo';
    final friendlyDevice = _formatDeviceLabel(rawDevice);
    final subtitle = _formatSessionMeta(
      session['ipAddress']?.toString(),
      session['createdAt']?.toString(),
    );
    final isCurrent = session['current'] == true;

    return SettingsRowTile(
      icon: _resolveDeviceIcon(rawDevice),
      darkIconBadge: isCurrent,
      title: friendlyDevice,
      subtitle: subtitle,
      tooltip: rawDevice != friendlyDevice ? rawDevice : null,
      trailing: isCurrent
          ? const SettingsStatusPill(
              label: 'Sessão atual',
              variant: SettingsPillVariant.success,
              icon: Icons.circle,
            )
          : OutlinedButton.icon(
              onPressed: () => _revokeSession(session['id'].toString()),
              style: settingsDangerOutlinedButtonStyle(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 13.5,
                color: Color(0xFFB91C1C),
              ),
              label: Text(
                'Encerrar',
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ),
    );
  }

  Widget _buildAuditLogRow(Map<String, dynamic> log) {
    final rawAction = log['action']?.toString() ?? 'Atividade';
    final visual = _describeAuditAction(rawAction);
    final subtitle = _formatAuditMeta(
      log['createdAt']?.toString(),
      log['ipAddress']?.toString(),
    );

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: visual.bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: visual.borderColor),
          ),
          child: Icon(visual.icon, size: 16, color: visual.iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                visual.label,
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyStateBox({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFA1A1AA)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolveDeviceIcon(String rawDevice) {
    final lower = rawDevice.toLowerCase();
    if (lower.contains('android') ||
        lower.contains('iphone') ||
        lower.contains('mobile')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('ipad') || lower.contains('tablet')) {
      return Icons.tablet_mac_rounded;
    }
    if (lower.contains('mozilla') ||
        lower.contains('chrome') ||
        lower.contains('firefox') ||
        lower.contains('safari') ||
        lower.contains('edg')) {
      return Icons.laptop_mac_outlined;
    }
    return Icons.devices_outlined;
  }

  String _formatDeviceLabel(String rawDevice) {
    final trimmed = rawDevice.trim();
    if (trimmed.isEmpty) return 'Dispositivo desconhecido';
    if (!trimmed.contains('Mozilla/') && !trimmed.contains('AppleWebKit')) {
      return trimmed;
    }

    final lower = trimmed.toLowerCase();
    final browser = lower.contains('edg/')
        ? 'Microsoft Edge'
        : lower.contains('opr/') || lower.contains('opera')
        ? 'Opera'
        : lower.contains('firefox/')
        ? 'Mozilla Firefox'
        : lower.contains('chrome/') || lower.contains('chromium')
        ? 'Google Chrome'
        : lower.contains('safari/')
        ? 'Safari'
        : 'Navegador Web';

    final os = lower.contains('android')
        ? 'Android'
        : lower.contains('iphone') || lower.contains('ipad')
        ? 'iOS'
        : lower.contains('windows')
        ? 'Windows'
        : lower.contains('mac os x') || lower.contains('macintosh')
        ? 'macOS'
        : lower.contains('linux')
        ? 'Linux'
        : 'Desktop';

    return '$browser • $os';
  }

  String _formatIp(String? ip) {
    final clean = (ip ?? '').trim();
    if (clean.isEmpty || clean.toLowerCase() == 'unknown') {
      return 'Origem não informada';
    }
    if (clean == '127.0.0.1' || clean == '::1') {
      return 'Acesso local ($clean)';
    }
    return clean;
  }

  String _formatIsoDate(String? rawIso) {
    final clean = (rawIso ?? '').trim();
    if (clean.isEmpty) return '';
    final parsed = DateTime.tryParse(clean);
    if (parsed == null) return clean;
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  String _formatSessionMeta(String? ip, String? createdAt) {
    final formattedIp = _formatIp(ip);
    final formattedDate = _formatIsoDate(createdAt);
    if (formattedDate.isEmpty) return formattedIp;
    return '$formattedIp • Conectado em $formattedDate';
  }

  String _formatAuditMeta(String? createdAt, String? ip) {
    final formattedDate = _formatIsoDate(createdAt);
    final formattedIp = _formatIp(ip);
    if (formattedDate.isEmpty) return formattedIp;
    return '$formattedDate • $formattedIp';
  }

  _AuditActionVisual _describeAuditAction(String rawAction) {
    switch (rawAction.trim().toLowerCase()) {
      case 'login_succeeded':
        return const _AuditActionVisual(
          label: 'Login realizado com sucesso',
          icon: Icons.check_rounded,
          iconColor: Color(0xFF16A34A),
          bgColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
        );
      case 'logout':
        return const _AuditActionVisual(
          label: 'Sessão encerrada',
          icon: Icons.logout_rounded,
          iconColor: Color(0xFF52525B),
          bgColor: Color(0xFFF4F4F5),
          borderColor: Color(0xFFE4E4E7),
        );
      case 'login_failed':
      case 'account_locked':
        return const _AuditActionVisual(
          label: 'Tentativa de acesso rejeitada',
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFB45309),
          bgColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
        );
      case 'password_changed':
      case 'password_reset':
        return const _AuditActionVisual(
          label: 'Senha institucional atualizada',
          icon: Icons.password_outlined,
          iconColor: Color(0xFF18181B),
          bgColor: Color(0xFFF4F4F5),
          borderColor: Color(0xFFE4E4E7),
        );
      case 'two_factor_enabled':
        return const _AuditActionVisual(
          label: 'Autenticação em duas etapas ativada',
          icon: Icons.verified_user_outlined,
          iconColor: Color(0xFF16A34A),
          bgColor: Color(0xFFF0FDF4),
          borderColor: Color(0xFFBBF7D0),
        );
      case 'two_factor_disabled':
        return const _AuditActionVisual(
          label: 'Autenticação em duas etapas desativada',
          icon: Icons.shield_outlined,
          iconColor: Color(0xFFB45309),
          bgColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
        );
      case 'session_revoked':
      case 'sessions_revoked_others':
        return const _AuditActionVisual(
          label: 'Sessão remota revogada',
          icon: Icons.devices_outlined,
          iconColor: Color(0xFFB91C1C),
          bgColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
        );
      default:
        return _AuditActionVisual(
          label: rawAction.replaceAll('_', ' '),
          icon: Icons.history_rounded,
          iconColor: const Color(0xFF52525B),
          bgColor: const Color(0xFFF4F4F5),
          borderColor: const Color(0xFFE4E4E7),
        );
    }
  }
}

class _AuditActionVisual {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;

  const _AuditActionVisual({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
  });
}

typedef StudentSecuritySessionsCard = SecuritySessionsCard;
