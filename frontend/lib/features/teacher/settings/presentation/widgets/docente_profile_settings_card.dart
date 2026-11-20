// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'components/profile_avatar_header.dart';
import 'components/profile_personal_data_form.dart';

/// Card modular de configurações de perfil docente e identificação acadêmica.
class DocenteProfileSettingsCard extends StatefulWidget {
  final DocenteController controller;

  const DocenteProfileSettingsCard({super.key, required this.controller});

  @override
  State<DocenteProfileSettingsCard> createState() =>
      _DocenteProfileSettingsCardState();
}

class _DocenteProfileSettingsCardState
    extends State<DocenteProfileSettingsCard> {
  late TextEditingController _civilNameController;
  late TextEditingController _socialNameController;
  late TextEditingController _personalEmailController;
  late TextEditingController _institutionalEmailController;
  final FocusNode _personalEmailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _civilNameController = TextEditingController(text: profile.fullName);
    _socialNameController = TextEditingController(
      text: profile.socialName,
    );
    _institutionalEmailController = TextEditingController(
      text: profile.institutionalEmail,
    );
    _personalEmailController = TextEditingController(
      text: profile.personalEmail,
    );
  }

  @override
  void dispose() {
    _civilNameController.dispose();
    _socialNameController.dispose();
    _institutionalEmailController.dispose();
    _personalEmailController.dispose();
    _personalEmailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final saved = await widget.controller.updateProfile(
      socialName: _socialNameController.text.trim(),
      personalEmail: _personalEmailController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Alterações de perfil salvas com sucesso!'
            : widget.controller.remoteError ?? 'Não foi possível salvar.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: saved ? const Color(0xFF16A34A) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Identidade Visual & Foto
        ProfileAvatarHeader(profile: profile),
        const SizedBox(height: 20),

        // 2. Formulário de Dados Pessoais & Cadastrais
        ProfilePersonalDataForm(
          profile: profile,
          civilNameController: _civilNameController,
          socialNameController: _socialNameController,
          institutionalEmailController: _institutionalEmailController,
          personalEmailController: _personalEmailController,
          personalEmailFocusNode: _personalEmailFocusNode,
          onSave: _handleSave,
        ),
      ],
    );
  }
}
