// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/state/app_user_session.dart';

Future<bool?> showPasswordChangeDialog(
  BuildContext context, {
  bool requiredChange = false,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: !requiredChange,
  builder: (_) => _ChangePasswordDialog(requiredChange: requiredChange),
);

class _ChangePasswordDialog extends StatefulWidget {
  final bool requiredChange;
  const _ChangePasswordDialog({required this.requiredChange});
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_next.text.length < 8 || _next.text != _confirmation.text) {
      setState(
        () => _error = 'Use pelo menos 8 caracteres e confirme a nova senha.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthenticatedApiClient().request(
        'POST',
        '/api/auth/change-password',
        body: {'currentPassword': _current.text, 'newPassword': _next.text},
      );
      AppUserSession.instance.signOut();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.requiredChange
            ? 'Altere sua senha para continuar'
            : 'Alterar senha',
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
            ),
            TextField(
              controller: _confirmation,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  if (widget.requiredChange) AppUserSession.instance.signOut();
                  Navigator.pop(context, false);
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Salvando...' : 'Salvar e entrar novamente'),
        ),
      ],
    ),
  );
}
