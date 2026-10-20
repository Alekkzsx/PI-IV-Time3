// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';
import '../widgets/docente_notification_prefs_card.dart';
import '../widgets/docente_profile_settings_card.dart';
import '../widgets/docente_security_sessions_card.dart';

/// Aba de gerenciamento de perfil, credenciais 2FA, sessões ativas, logs e conformidade LGPD.
class DocenteSettingsTab extends StatelessWidget {
  /// Controlador reativo com o estado do perfil e sessões.
  final DocenteController controller;

  const DocenteSettingsTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final subtab = controller.settingsSubtab;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSubtabsBar(subtab),
          const SizedBox(height: 24),
          _buildSubtabContent(subtab),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações Docente & Segurança Institucional',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: DocenteColors.charcoal,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gestão de perfil, credenciais de acesso, 2FA, sessões ativas e privacidade LGPD',
          style: TextStyle(
            fontSize: 14,
            color: DocenteColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtabsBar(String activeSubtab) {
    final tabs = [
      {'key': 'perfil', 'label': 'Perfil Docente'},
      {'key': 'seguranca', 'label': 'Segurança & Acessos'},
      {'key': 'notificacoes', 'label': 'Notificações'},
      {'key': 'preferencias', 'label': 'Preferências'},
      {'key': 'privacidade', 'label': 'Privacidade & LGPD'},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = activeSubtab == tab['key'];
          return InkWell(
            onTap: () => controller.setSettingsSubtab(tab['key']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? DocenteColors.charcoal : Colors.transparent,
                    width: 2.0,
                  ),
                ),
              ),
              child: Text(
                tab['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? DocenteColors.charcoal : DocenteColors.slate,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubtabContent(String subtab) {
    switch (subtab) {
      case 'perfil':
        return DocenteProfileSettingsCard(controller: controller);
      case 'seguranca':
        return DocenteSecuritySessionsCard(controller: controller);
      case 'notificacoes':
      case 'preferencias':
      case 'privacidade':
        return DocenteNotificationPrefsCard(activeSubtab: subtab);
      default:
        return DocenteSecuritySessionsCard(controller: controller);
    }
  }
}
