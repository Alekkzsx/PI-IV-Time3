// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agmrm_security/security.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String newPasswordText = '';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isEntropyValid = PasswordEntropyValidator.isEligibleForSubmission(newPasswordText);
          final passwordsMatch = newPasswordText.isNotEmpty && newPasswordText == confirm.text;

          return AlertDialog(
            title: const Text('Alterar Senha Institucional'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: current,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha atual'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: next,
                      obscureText: true,
                      onChanged: (val) {
                        setDialogState(() {
                          newPasswordText = val;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Nova senha'),
                    ),
                    const SizedBox(height: 12),
                    // Medidor institucional de entropia em tempo real
                    StudentPasswordEntropyMeter(password: newPasswordText),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirm,
                      obscureText: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirmar nova senha',
                        errorText: confirm.text.isNotEmpty && !passwordsMatch
                            ? 'As senhas não coincidem'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isEntropyValid && passwordsMatch
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar Nova Senha'),
              ),
            ],
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

    // Rate limiting para troca de senha
    if (!StudentActionRateLimiter.instance.canExecute(StudentActionType.changePassword)) {
      final cooldown = StudentActionRateLimiter.instance.getRemainingCooldownSeconds(
        StudentActionType.changePassword,
      );
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
      StudentActionRateLimiter.instance.recordAction(StudentActionType.changePassword);
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
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          enabled
              ? 'Ativar autenticação em duas etapas'
              : 'Desativar autenticação em duas etapas',
        ),
        content: TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirme sua senha'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
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
        _section(
          title: 'Segurança da conta',
          children: [
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('Senha de acesso'),
              subtitle: const Text('A alteração encerra esta sessão.'),
              trailing: OutlinedButton(
                onPressed: _changePassword,
                child: const Text('Alterar senha'),
              ),
            ),
            SwitchListTile(
              value: enabled,
              onChanged: _loading ? null : _toggleTwoFactor,
              title: const Text('Autenticação em duas etapas'),
              subtitle: Text(enabled ? 'Ativa' : 'Desativada'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Códigos de backup',
          children: [
            ListTile(
              title: const Text('Códigos de recuperação'),
              subtitle: const Text('Gerados pelo serviço de autenticação.'),
              trailing: OutlinedButton(
                onPressed: _generateBackupCodes,
                child: const Text('Gerar'),
              ),
            ),
            if (_backupCodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(_backupCodes.join('\n')),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _backupCodes.join('\n')),
                        );
                        _showMessage('Códigos copiados.');
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar códigos'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Sessões ativas',
          trailing: TextButton(
            onPressed: _loading ? null : _logoutOthers,
            child: const Text('Encerrar outras'),
          ),
          children: [
            if (_loading)
              const LinearProgressIndicator()
            else if (_sessions.isEmpty)
              const ListTile(title: Text('Nenhuma sessão ativa retornada.'))
            else
              for (final session in _sessions)
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: Text(session['device']?.toString() ?? 'Dispositivo'),
                  subtitle: Text(
                    '${session['ipAddress'] ?? ''} • ${session['createdAt'] ?? ''}',
                  ),
                  trailing: session['current'] == true
                      ? const Chip(label: Text('Sessão atual'))
                      : IconButton(
                          tooltip: 'Encerrar sessão',
                          onPressed: () =>
                              _revokeSession(session['id'].toString()),
                          icon: const Icon(Icons.logout),
                        ),
                ),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Registros de segurança',
          children: [
            if (_logs.isEmpty)
              const ListTile(title: Text('Nenhum registro disponível.'))
            else
              for (final log in _logs)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(log['action']?.toString() ?? 'Atividade'),
                  subtitle: Text(
                    '${log['createdAt'] ?? ''} • ${log['ipAddress'] ?? ''}',
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}


typedef StudentSecuritySessionsCard = SecuritySessionsCard;
