// Desenvolvido por Murillo Caravita - RA: 25014012

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import '../../../shared/controllers/admin_portal_controller.dart';

/// Aba de governança institucional e conformidade LGPD.
class GovernanceLgpdTab extends StatefulWidget {
  const GovernanceLgpdTab({super.key});

  @override
  State<GovernanceLgpdTab> createState() => _GovernanceLgpdTabState();
}

class _GovernanceLgpdTabState extends State<GovernanceLgpdTab> {
  final _profileRemote = AuthProfileRemoteDataSource();
  final _portal = AdminPortalController.instance;
  final _retentionController = TextEditingController(text: '60');
  final _dpoEmailController = TextEditingController(text: 'dpo@agmrm.edu.br');

  bool _showEmailInClassLists = false;
  bool _showPeerPresence = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrateFromSettings(_portal.institutionalSettings);
    _loadSettingsIfNeeded();
  }

  void _hydrateFromSettings(Map<String, dynamic> settings) {
    final lgpd = settings['governanceLgpd'];
    if (lgpd is Map) {
      _showEmailInClassLists = lgpd['showInstitutionalEmailInClassLists'] == true;
      _showPeerPresence = lgpd['showPeerPresenceStatus'] != false;
      final retention = lgpd['lgpdRetentionMonths'] ?? settings['lgpdRetentionMonths'];
      if (retention != null) _retentionController.text = retention.toString();
      final dpo = (lgpd['dpoEmail'] ?? settings['dpoEmail'])?.toString().trim();
      if (dpo != null && dpo.isNotEmpty) _dpoEmailController.text = dpo;
    }
  }

  Future<void> _loadSettingsIfNeeded() async {
    if (_portal.institutionalSettings.isNotEmpty ||
        AppUserSession.instance.accessToken == null) {
      return;
    }
    try {
      final settings = await _portal.remote.request('GET', '/settings') as Map;
      if (!mounted) return;
      setState(() {
        _portal.institutionalSettings = Map<String, dynamic>.from(settings);
        _hydrateFromSettings(_portal.institutionalSettings);
      });
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    final months = int.tryParse(_retentionController.text.trim()) ?? 60;
    final dpoEmail = _dpoEmailController.text.trim().isEmpty
        ? 'dpo@agmrm.edu.br'
        : _dpoEmailController.text.trim();
    final payload = <String, dynamic>{
      'showInstitutionalEmailInClassLists': _showEmailInClassLists,
      'showPeerPresenceStatus': _showPeerPresence,
      'lgpdRetentionMonths': months.clamp(6, 240),
      'dpoEmail': dpoEmail,
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await _portal.updateSettings({'governanceLgpd': payload});
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = ok ? null : _portal.remoteError;
    });
    if (ok) {
      _portal.institutionalSettings = {
        ..._portal.institutionalSettings,
        'governanceLgpd': payload,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Políticas de governança e LGPD atualizadas.'),
        ),
      );
    }
  }

  Future<void> _exportData({required bool asJson}) async {
    try {
      final data = await _profileRemote.lgpdExport();
      final content = asJson
          ? const JsonEncoder.withIndent('  ').convert(data)
          : data.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
      final saved = await PlatformFileHelper.saveOrDownloadFile(
        fileName: asJson ? 'exportacao-lgpd.json' : 'exportacao-lgpd.txt',
        bytes: utf8.encode(content),
        mimeType: asJson ? 'application/json' : 'text/plain',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved == null
                  ? 'Falha ao salvar exportação.'
                  : 'Exportação salva: $saved',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void dispose() {
    _retentionController.dispose();
    _dpoEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: InstColors.dangerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: InstColors.danger.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _error!,
              style: jakarta(size: 13, color: InstColors.danger),
            ),
          ),

        // 1. Política Institucional de Diretório & LGPD
        Container(
          decoration: BoxDecoration(
            color: InstColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: InstColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: InstColors.ink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Política Institucional de Diretório & LGPD',
                    style: jakarta(
                      size: 15.5,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Controle a exposição de dados pessoais em listas de turmas no AVA e defina os parâmetros globais de retenção e DPO.',
                style: jakarta(size: 12, color: InstColors.muted),
              ),
              const SizedBox(height: 20),

              _buildVisibilityRow(
                title: 'Exibir e-mail institucional nas listagens de turma',
                subtitle:
                    'Quando desativado (padrão LGPD), o endereço de e-mail dos discentes fica oculto para outros participantes da mesma disciplina.',
                value: _showEmailInClassLists,
                onChanged: (val) =>
                    setState(() => _showEmailInClassLists = val ?? false),
              ),

              const Divider(height: 28, color: InstColors.border),

              _buildVisibilityRow(
                title: 'Permitir indicador de presença recente ("Online recentemente")',
                subtitle:
                    'Controla globalmente a exibição de atividade recente nos diretórios de turma e atendimento.',
                value: _showPeerPresence,
                onChanged: (val) =>
                    setState(() => _showPeerPresence = val ?? true),
              ),

              const Divider(height: 28, color: InstColors.border),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 620;
                  final retentionField = TextField(
                    controller: _retentionController,
                    keyboardType: TextInputType.number,
                    style: jakarta(size: 13.5, color: InstColors.ink),
                    decoration: InstText.inputDecoration(
                      labelText: 'Retenção de Logs & Auditoria (meses)',
                      hintText: '60',
                    ),
                  );
                  final dpoField = TextField(
                    controller: _dpoEmailController,
                    style: jakarta(size: 13.5, color: InstColors.ink),
                    decoration: InstText.inputDecoration(
                      labelText: 'E-mail Oficial do Encarregado (DPO)',
                      hintText: 'dpo@agmrm.edu.br',
                    ),
                  );
                  return isNarrow
                      ? Column(
                          children: [
                            retentionField,
                            const SizedBox(height: 14),
                            dpoField,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: retentionField),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: dpoField),
                          ],
                        );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Direitos do Titular e Exportação de Conta (LGPD)
        Container(
          decoration: BoxDecoration(
            color: InstColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: InstColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 20,
                    color: InstColors.ink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Privacidade & Direitos do Titular (LGPD)',
                    style: jakarta(
                      size: 15.5,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Em conformidade com a Lei nº 13.709/2018 (LGPD), exporte o dossiê completo da conta autenticada e registros associados.',
                style: jakarta(size: 12, color: InstColors.muted, height: 1.35),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InstColors.stone,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: InstColors.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    return isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExportInfo(),
                              const SizedBox(height: 14),
                              _buildExportButtons(context),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildExportInfo()),
                              const SizedBox(width: 16),
                              _buildExportButtons(context),
                            ],
                          );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _saving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: InstColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _saving ? 'Salvando...' : 'Salvar Políticas de Governança & LGPD',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisibilityRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: jakarta(size: 11.5, color: InstColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Checkbox(
          value: value,
          activeColor: InstColors.ink,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildExportInfo() {
    return Row(
      children: [
        const Icon(
          Icons.description_outlined,
          size: 20,
          color: InstColors.body,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportar Relatório de Dados Cadastrais & Histórico',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Inclui dados cadastrais, registros de acesso e interações vinculadas à conta.',
                style: jakarta(size: 11, color: InstColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _exportData(asJson: true),
          icon: const Icon(Icons.download_rounded, size: 15),
          label: Text(
            'Arquivo JSON',
            style: jakarta(size: 11.5, weight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: InstColors.ink,
            side: const BorderSide(color: InstColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _exportData(asJson: false),
          icon: const Icon(Icons.download_rounded, size: 15),
          label: Text(
            'Relatório (.txt)',
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: InstColors.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}
