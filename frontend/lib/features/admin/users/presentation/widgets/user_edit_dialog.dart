// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import '../../../shared/controllers/admin_portal_controller.dart';
import '../../../shared/models/admin_models.dart';

Future<bool?> showUserEditDialog(BuildContext context, AdminUserModel user) =>
    AcademicModalDialog.show<bool>(
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

  static const _profileLabels = {
    'aluno': 'Discente (Aluno)',
    'docente': 'Docente (Professor)',
    'admin': 'Administrador (Secretaria)',
  };

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
  Widget build(BuildContext context) => AcademicModalDialog(
    title: 'Editar Usuário Institucional',
    subtitle: 'Atualize os dados cadastrais, lotação ou perfil de acesso.',
    icon: Icons.manage_accounts_outlined,
    cancelLabel: 'Cancelar',
    confirmLabel: 'Salvar alterações',
    isLoading: _busy,
    onConfirm: _save,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _identity,
          decoration: InstText.inputDecoration(
            labelText: 'Identidade institucional (R.A. / Matrícula)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: InstText.inputDecoration(labelText: 'Nome completo'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: InstText.inputDecoration(labelText: 'E-mail institucional'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _department,
          decoration: InstText.inputDecoration(labelText: 'Curso / Lotação'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _profileLabels.containsKey(_profile) ? _profile : 'aluno',
          decoration: InstText.inputDecoration(labelText: 'Perfil de acesso'),
          items: _profileLabels.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) setState(() => _profile = value);
                },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: InstColors.dangerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: InstColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _error!,
              style: jakarta(size: 12.5, color: InstColors.danger),
            ),
          ),
        ],
      ],
    ),
  );
}
