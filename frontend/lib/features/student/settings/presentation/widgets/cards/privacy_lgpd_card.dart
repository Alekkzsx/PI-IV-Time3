// Desenvolvido por Murillo Caravita - RA: 25014012

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import '../common/settings_common_widgets.dart';

/// [PrivacyLgpdCard]
///
/// Componente de gestão de privacidade, visibilidade de dados pessoais e direitos LGPD (Lei 13.709/2018).
/// Permite controlar o compartilhamento de e-mail e telefone com colegas de turma,
/// além de oferecer exportação dos dados cadastrais (portabilidade) e canal formal para a DPO institucional.
class PrivacyLgpdCard extends StatefulWidget {
  /// Cria uma nova instância de [PrivacyLgpdCard].
  const PrivacyLgpdCard({super.key});

  @override
  State<PrivacyLgpdCard> createState() => _StudentPrivacyLgpdCardState();
}

class _StudentPrivacyLgpdCardState extends State<PrivacyLgpdCard> {
  final AuthProfileRemoteDataSource _remote = AuthProfileRemoteDataSource();
  bool _exibirEmailColegas = false;
  bool _exibirTelefoneGrupos = false;
  bool _mostrarStatusPresenca = false;

  @override
  void initState() {
    super.initState();
    final saved = AppUserSession.instance.preferences['privacy'];
    if (saved is Map) {
      _exibirEmailColegas = saved['showEmailToClassmates'] == true;
      _exibirTelefoneGrupos = saved['showPhoneToGroups'] == true;
      _mostrarStatusPresenca = saved['showAttendanceStatus'] == true;
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final preferences = Map<String, dynamic>.from(
      AppUserSession.instance.preferences,
    );
    final privacy = Map<String, dynamic>.from(
      preferences['privacy'] is Map
          ? preferences['privacy'] as Map
          : const <String, dynamic>{},
    )..[key] = value;
    preferences['privacy'] = privacy;
    try {
      await _remote.updateProfile({'preferences': preferences});
      if (!mounted) return;
      setState(() {
        switch (key) {
          case 'showEmailToClassmates':
            _exibirEmailColegas = value;
            break;
          case 'showPhoneToGroups':
            _exibirTelefoneGrupos = value;
            break;
          case 'showAttendanceStatus':
            _mostrarStatusPresenca = value;
            break;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _exportLgpdDossier() async {
    try {
      final export = await _remote.lgpdExport();
      final path = await PlatformFileHelper.saveOrDownloadFile(
        fileName: 'exportacao_lgpd.json',
        bytes: utf8.encode(const JsonEncoder.withIndent('  ').convert(export)),
        mimeType: 'application/json',
      );
      if (!mounted) return;
      if (path == null) {
        throw Exception('Não foi possível salvar a exportação.');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exportação LGPD salva em $path'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Visibilidade de Perfil & Dados entre Colegas
        SettingsSectionCard(
          icon: Icons.visibility_outlined,
          title: 'Visibilidade de Perfil & Dados entre Colegas',
          subtitle:
              'Controle quais informações ficam visíveis para outros estudantes matriculados nas mesmas turmas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Exibir e-mail nas turmas
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _exibirEmailColegas,
                      onChanged: (v) =>
                          _savePreference('showEmailToClassmates', v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exibir meu e-mail nas listagens de participantes da turma',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permite que colegas vejam seu contato institucional na lista do AVA para formação de grupos.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Compartilhar WhatsApp com membros de equipe
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _exibirTelefoneGrupos,
                      onChanged: (v) =>
                          _savePreference('showPhoneToGroups', v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compartilhar número de WhatsApp com membros de equipes de trabalho',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Facilita a comunicação ágil com integrantes de atividades em grupo vinculadas pelo professor.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Status de Presença e Disponibilidade
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _mostrarStatusPresenca,
                      onChanged: (v) =>
                          _savePreference('showAttendanceStatus', v ?? false),
                      activeColor: const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exibir indicador de status online/estudo no AVA',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mostra um ponto verde discreto aos colegas e professores quando você estiver com o portal aberto.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Governança de Dados Pessoais & Direitos LGPD
        SettingsSectionCard(
          icon: Icons.shield_outlined,
          title: 'Direitos do Titular & Governança LGPD (Lei 13.709/2018)',
          subtitle:
              'Em conformidade com a Lei Geral de Proteção de Dados, seus registros acadêmicos, históricos de notas, frequências em sala e interações no AVA são custodiados exclusivamente para fins pedagógicos e cumprimento de dever legal perante o MEC.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Exportação de Dados
              SettingsRowTile(
                darkIconBadge: true,
                icon: Icons.download_rounded,
                title: 'Exportar Dossiê Completo do Titular (LGPD)',
                subtitle:
                    'Baixe um arquivo compactado (JSON e PDF) com todos os seus dados pessoais, histórico de acesso e registros pedagógicos custodiados.',
                trailing: ElevatedButton.icon(
                  onPressed: _exportLgpdDossier,
                  icon: const Icon(
                    Icons.file_download_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Exportar Dossiê',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: settingsPrimaryButtonStyle(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Termo de Imagem e Voz
              SettingsRowTile(
                icon: Icons.assignment_turned_in_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFF0FDF4),
                title:
                    'Termo de Consentimento de Uso de Imagem e Voz em Aulas Gravadas',
                subtitle:
                    'Assinado digitalmente via token no ato de homologação de matrícula em 10/02/2024.',
                trailing: const SettingsStatusPill(
                  label: 'Válido',
                  variant: SettingsPillVariant.success,
                ),
              ),
              const SizedBox(height: 18),

              // Contato do DPO
              Row(
                children: [
                  const Icon(
                    Icons.contact_mail_outlined,
                    size: 14,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Encarregado de Proteção de Dados (DPO): dpo@universidade.edu.br • Ouvidoria Geral DTI',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
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


typedef StudentPrivacyLgpdCard = PrivacyLgpdCard;
