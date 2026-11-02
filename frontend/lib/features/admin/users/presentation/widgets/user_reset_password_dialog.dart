// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Diálogo modal de confirmação para envio de link de redefinição segura de credenciais.
class UserResetPasswordDialog extends StatelessWidget {
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
    return showDialog<void>(
      context: context,
      builder: (ctx) =>
          UserResetPasswordDialog(user: user, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Redefinição Segura de Credenciais',
        style: jakarta(
          size: 18,
          weight: FontWeight.w700,
          color: const Color(0xFF18181B),
        ),
      ),
      content: Text(
        'Deseja enviar um código de recuperação com validade de cinco minutos para o e-mail:\n\n${user.email}?',
        style: jakarta(size: 13.5, color: const Color(0xFF525252), height: 1.4),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E5E5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancelar',
            style: jakarta(
              size: 13,
              weight: FontWeight.w500,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await onConfirm();
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
              return;
            }
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Código de recuperação enviado para ${user.email}.',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Confirmar Envio',
            style: jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
