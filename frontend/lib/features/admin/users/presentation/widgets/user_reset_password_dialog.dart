// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

/// Diálogo modal de confirmação para envio de link de redefinição segura de credenciais.
class UserResetPasswordDialog extends StatefulWidget {
  final AdminUserModel user;
  final Future<void> Function() onConfirm;

  const UserResetPasswordDialog({
    super.key,
    required this.user,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required AdminUserModel user,
    required Future<void> Function() onConfirm,
  }) {
    return AcademicModalDialog.show<void>(
      context: context,
      builder: (ctx) =>
          UserResetPasswordDialog(user: user, onConfirm: onConfirm),
    );
  }

  @override
  State<UserResetPasswordDialog> createState() =>
      _UserResetPasswordDialogState();
}

class _UserResetPasswordDialogState extends State<UserResetPasswordDialog> {
  bool _sending = false;

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await widget.onConfirm();
    } catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Código de recuperação enviado para ${widget.user.email}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AcademicModalDialog(
      title: 'Redefinição Segura de Credenciais',
      subtitle: 'Emissão de código temporário de recuperação de senha.',
      icon: Icons.lock_reset_rounded,
      cancelLabel: 'Cancelar',
      confirmLabel: 'Confirmar Envio',
      isLoading: _sending,
      onConfirm: _submit,
      child: Text(
        'Deseja enviar um código de recuperação com validade de cinco minutos para o e-mail:\n\n${widget.user.email}?',
        style: jakarta(size: 13.5, color: InstColors.body, height: 1.45),
      ),
    );
  }
}
