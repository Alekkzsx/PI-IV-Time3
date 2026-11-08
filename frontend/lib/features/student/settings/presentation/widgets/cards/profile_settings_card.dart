// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/settings_common_widgets.dart';
import 'components/profile_identity_header_card.dart';
import 'components/profile_academic_kpis_card.dart';

/// [ProfileSettingsCard]
///
/// Componente orquestrador de configuração de perfil cadastral e acadêmico do discente.
/// Compõe [ProfileIdentityHeaderCard], [ProfileAcademicKpisCard] e o formulário de
/// atualização cadastral sincronizado com [AppUserSession] e [AuthProfileRemoteDataSource].
class ProfileSettingsCard extends StatefulWidget {
  /// Controlador reativo que provê dados cadastrais agregados do portal.
  final StudentPortalController controller;

  /// Cria uma nova instância de [ProfileSettingsCard].
  const ProfileSettingsCard({super.key, required this.controller});

  @override
  State<ProfileSettingsCard> createState() =>
      _StudentProfileSettingsCardState();
}

class _StudentProfileSettingsCardState extends State<ProfileSettingsCard> {
  late TextEditingController _civilNameController;
  late TextEditingController _socialNameController;
  late TextEditingController _institutionalEmailController;
  late TextEditingController _recoveryEmailController;
  late TextEditingController _phoneController;
  final AuthProfileRemoteDataSource _remote = AuthProfileRemoteDataSource();

  @override
  void initState() {
    super.initState();
    final session = AppUserSession.instance;
    _civilNameController = TextEditingController(
      text: session.displayName ?? '',
    );
    _socialNameController = TextEditingController(
      text: session.socialName ?? '',
    );
    _institutionalEmailController = TextEditingController(
      text: session.email ?? '',
    );
    _recoveryEmailController = TextEditingController();
    _phoneController = TextEditingController(text: session.phone ?? '');
    _loadProfile();
  }

  @override
  void dispose() {
    _civilNameController.dispose();
    _socialNameController.dispose();
    _institutionalEmailController.dispose();
    _recoveryEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _remote.me();
      if (!mounted) return;
      _recoveryEmailController.text =
          profile['personalEmail']?.toString() ?? '';
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    try {
      await _remote.updateProfile({
        'socialName': _socialNameController.text.trim(),
        'personalEmail': _recoveryEmailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppUserSession.instance;
    final studentInfo = widget.controller.studentInfo;
    final recordSummary = widget.controller.recordSummary;
    final studentName =
        studentInfo['name']?.toString() ?? session.effectiveName;
    final studentRa = studentInfo['ra']?.toString() ?? session.identity ?? '';
    final studentCourse =
        studentInfo['courseName']?.toString() ??
        session.departmentOrCourse ??
        '';
    final semester =
        studentInfo['semester']?.toString() ?? session.semester ?? '';
    final shift = studentInfo['shift']?.toString() ?? session.shift ?? '';
    final academicIndex = recordSummary['academicIndex']?.toString() ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileIdentityHeaderCard(
          initials: session.initials,
          studentName: studentName,
          studentRa: studentRa,
          studentCourse: studentCourse,
        ),
        const SizedBox(height: 20),
        ProfileAcademicKpisCard(
          studentRa: studentRa,
          studentCourse: studentCourse,
          semester: semester,
          shift: shift,
          academicIndex: academicIndex,
        ),
        const SizedBox(height: 20),
        SettingsSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identificação & Contatos',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mantenha seus canais de contato atualizados para receber comunicados de estágio e notas.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),
              const SettingsFieldLabel(
                label: 'Nome Civil Completo',
                tagText: 'Alteração apenas via protocolo',
                isEditable: false,
              ),
              TextField(
                controller: _civilNameController,
                readOnly: true,
                style: jakarta(size: 13, color: const Color(0xFF71717A)),
                decoration: buildSettingsInputDecoration(
                  readOnly: true,
                  suffix: const Tooltip(
                    message:
                        'Para alteração de nome civil, abra um protocolo na Secretaria com certidão em anexo.',
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SettingsFieldLabel(
                label: 'Nome Social / Exibição',
                tagText: 'Editável • Exibido no AVA',
                isEditable: true,
              ),
              TextField(
                controller: _socialNameController,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: buildSettingsInputDecoration(
                  hintText: 'Como você deseja ser chamado nas turmas e fóruns',
                ),
              ),
              const SizedBox(height: 18),
              const SettingsFieldLabel(
                label: 'E-mail Institucional',
                tagText: 'Vinculado ao SSO Estudantil',
                isEditable: false,
              ),
              TextField(
                controller: _institutionalEmailController,
                readOnly: true,
                style: jakarta(size: 13, color: const Color(0xFF71717A)),
                decoration: buildSettingsInputDecoration(
                  readOnly: true,
                  suffix: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'Verificado',
                      style: jakarta(
                        size: 10,
                        weight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final emailField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsFieldLabel(
                        label: 'E-mail Pessoal / Recuperação',
                        tagText: 'Editável',
                        isEditable: true,
                      ),
                      TextField(
                        controller: _recoveryEmailController,
                        style: jakarta(
                          size: 13,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: buildSettingsInputDecoration(
                          hintText: 'exemplo@gmail.com',
                        ),
                      ),
                    ],
                  );

                  final phoneField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SettingsFieldLabel(
                        label: 'Celular / WhatsApp',
                        tagText: 'Editável',
                        isEditable: true,
                      ),
                      TextField(
                        controller: _phoneController,
                        style: jakarta(
                          size: 13,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: buildSettingsInputDecoration(
                          hintText: '(00) 00000-0000',
                        ),
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 600) {
                    return Column(
                      children: [
                        emailField,
                        const SizedBox(height: 18),
                        phoneField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: emailField),
                      const SizedBox(width: 16),
                      Expanded(child: phoneField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Salvar Alterações de Perfil',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef StudentProfileSettingsCard = ProfileSettingsCard;
