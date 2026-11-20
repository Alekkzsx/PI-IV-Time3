// Desenvolvido por Murillo Caravita - RA: 25014012

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'components/lgpd_data_export_card.dart';
import 'components/privacy_visibility_section.dart';

/// Card modular para gerenciamento de privacidade, visibilidade de dados funcionais e direitos LGPD.
class DocentePrivacyLgpdCard extends StatefulWidget {
  const DocentePrivacyLgpdCard({super.key});

  @override
  State<DocentePrivacyLgpdCard> createState() => _DocentePrivacyLgpdCardState();
}

class _DocentePrivacyLgpdCardState extends State<DocentePrivacyLgpdCard> {
  final _profileRemote = AuthProfileRemoteDataSource();
  bool _exibirEmailTurma = true;
  bool _mostrarStatusPresenca = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final profile = await _profileRemote.me();
      final preferences = profile['preferences'];
      if (!mounted || preferences is! Map) return;
      setState(() {
        _exibirEmailTurma = preferences['showInstitutionalEmail'] != false;
        _mostrarStatusPresenca = preferences['showPresenceStatus'] != false;
      });
    } catch (_) {
      // As preferências permanecem em seus valores padrão neutros quando indisponíveis.
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _profileRemote.updateProfile({
        'preferences': {
          'showInstitutionalEmail': _exibirEmailTurma,
          'showPresenceStatus': _mostrarStatusPresenca,
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferências de privacidade salvas.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
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
                  ? 'Não foi possível salvar a exportação.'
                  : 'Exportação salva: $saved',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Visibilidade de Perfil & Dados entre Colegas
        PrivacyVisibilitySection(
          exibirEmailTurma: _exibirEmailTurma,
          mostrarStatusPresenca: _mostrarStatusPresenca,
          onExibirEmailChanged: (v) =>
              setState(() => _exibirEmailTurma = v ?? false),
          onMostrarStatusChanged: (v) =>
              setState(() => _mostrarStatusPresenca = v ?? false),
        ),
        const SizedBox(height: 20),

        // 2. Privacidade & Direitos do Titular (LGPD)
        LgpdDataExportCard(
          onExportData: _exportData,
        ),
        const SizedBox(height: 20),

        // Botão Salvar Preferências
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _savePreferences,
            icon: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Salvar Preferências de Privacidade',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
