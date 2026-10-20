// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Card de configurações de perfil docente e identificação acadêmica.
class DocenteProfileSettingsCard extends StatefulWidget {
  final DocenteController controller;

  const DocenteProfileSettingsCard({
    super.key,
    required this.controller,
  });

  @override
  State<DocenteProfileSettingsCard> createState() =>
      _DocenteProfileSettingsCardState();
}

class _DocenteProfileSettingsCardState
    extends State<DocenteProfileSettingsCard> {
  late TextEditingController _socialNameController;
  late TextEditingController _personalEmailController;

  @override
  void initState() {
    super.initState();
    _socialNameController =
        TextEditingController(text: widget.controller.profile.socialName);
    _personalEmailController =
        TextEditingController(text: widget.controller.profile.personalEmail);
  }

  @override
  void dispose() {
    _socialNameController.dispose();
    _personalEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: DocenteColors.charcoal,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'HB',
                  style: TextStyle(
                    color: DocenteColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DocenteColors.charcoal,
                    ),
                  ),
                  Text(
                    '${profile.title} • Matrícula: ${profile.registrationNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: DocenteColors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: DocenteColors.border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  'Nome Completo Institucional',
                  profile.fullName,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField(
                  'E-mail Institucional (@universidade.edu.br)',
                  profile.institutionalEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  'Nome Social (Opcional)',
                  _socialNameController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditableField(
                  'E-mail Pessoal para Recuperação',
                  _personalEmailController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  'Regime de Trabalho',
                  profile.workRegime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField(
                  'Currículo Lattes',
                  profile.lattesUrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.controller.updateProfile(
                  socialName: _socialNameController.text.trim(),
                  personalEmail: _personalEmailController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Dados do perfil docente atualizados com sucesso!',
                    ),
                    backgroundColor: DocenteColors.emerald,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Salvar Informações do Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DocenteColors.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: DocenteColors.slate),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: DocenteColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

