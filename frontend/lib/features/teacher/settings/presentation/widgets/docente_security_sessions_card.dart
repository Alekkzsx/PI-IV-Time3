// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'components/active_sessions_list_view.dart';
import 'components/change_password_dialog.dart';
import 'components/security_2fa_section.dart';
import 'components/security_audit_logs_viewer.dart';
import 'components/security_backup_codes_card.dart';
import 'components/security_password_card.dart';

/// Card modular de configurações de 2FA, gerenciamento de sessões ativas e histórico de auditoria.
class DocenteSecuritySessionsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteSecuritySessionsCard({super.key, required this.controller});

  Future<void> _changePassword(BuildContext context) async {
    final values = await ChangePasswordDialog.show(context);
    if (values != null && context.mounted) {
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

  Future<void> _toggle2fa(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Credencial de Acesso (Senha)
        SecurityPasswordCard(
          onChangePassword: () => _changePassword(context),
        ),
        const SizedBox(height: 20),

        // 2. Autenticação em Duas Etapas (2FA)
        Security2faSection(
          profile: profile,
          onToggle2fa: () => _toggle2fa(context),
        ),
        const SizedBox(height: 20),

        // 3. Códigos de Recuperação (Backup)
        SecurityBackupCodesCard(
          onManageCodes: () => _showBackupCodes(context),
        ),
        const SizedBox(height: 20),

        // 4. Sessões Ativas & Dispositivos Conectados
        ActiveSessionsListView(
          controller: controller,
          profile: profile,
        ),
        const SizedBox(height: 20),

        // 5. Histórico Recente de Acesso (Auditoria de Segurança)
        SecurityAuditLogsViewer(
          controller: controller,
        ),
      ],
    );
  }
}
