// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';
import '../../../shared/controllers/admin_portal_controller.dart';
import '../../../shared/data/admin_mock_data.dart';

Future<bool?> showUserEditDialog(BuildContext context, AdminUserModel user) =>
    showDialog<bool>(
      context: context,
      builder: (_) => _UserEditDialog(user: user),
    );

class _UserEditDialog extends StatefulWidget {
  final AdminUserModel user;
  const _UserEditDialog({required this.user});
  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _identity = TextEditingController(text: widget.user.identity);
  late final _email = TextEditingController(text: widget.user.email);
  late final _department = TextEditingController(
    text: widget.user.departmentOrCourse,
  );
  late String _profile = widget.user.profile;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _identity.dispose();
    _email.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final portal = AdminPortalController.instance;
    final ok = await portal.persist(
      () => portal.remote.request('PATCH', '/users/${widget.user.id}', {
        'identity': _identity.text.trim(),
        'displayName': _name.text.trim(),
        'email': _email.text.trim(),
        'profile': _profile,
        'departmentOrCourse': _department.text.trim(),
      }),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = portal.remoteError;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar usuário'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _identity,
              decoration: const InputDecoration(
                labelText: 'Identidade institucional',
              ),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: _department,
              decoration: const InputDecoration(labelText: 'Curso / lotação'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _profile,
              items: ['aluno', 'docente', 'admin']
                  .map(
                    (role) => DropdownMenuItem(value: role, child: Text(role)),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _profile = value!),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Salvando...' : 'Salvar'),
      ),
    ],
  );
}
