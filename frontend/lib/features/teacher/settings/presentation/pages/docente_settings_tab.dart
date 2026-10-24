// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/docente_notification_prefs_card.dart';
import '../widgets/docente_privacy_lgpd_card.dart';
import '../widgets/docente_profile_settings_card.dart';
import '../widgets/docente_security_sessions_card.dart';
import '../widgets/docente_system_preferences_card.dart';

/// Aba principal de Configurações da Conta Docente com navegação lateral por categorias.
class DocenteSettingsTab extends StatelessWidget {
  /// Controlador reativo com o estado do perfil e sessões.
  final DocenteController controller;

  const DocenteSettingsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final subtab = controller.settingsSubtab;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideLayout = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideLayout ? 40 : 20,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),
                          if (isWideLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: _buildSettingsSidebar(subtab),
                                ),
                                const SizedBox(width: 28),
                                Expanded(child: _buildSubtabContent(subtab)),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSettingsSidebar(subtab),
                                const SizedBox(height: 20),
                                _buildSubtabContent(subtab),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const DocenteFooter(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações da Conta Docente',
          style: jakarta(
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gerencie suas credenciais de acesso institucional, autenticação em duas etapas e preferências pedagógicas.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSidebar(String activeSubtab) {
    final navItems = [
      {
        'key': 'perfil',
        'title': 'Perfil Docente',
        'subtitle': 'Nome, departamento, titulação e identificação',
        'icon': Icons.person_outline_rounded,
      },
      {
        'key': 'seguranca',
        'title': 'Segurança & Acessos',
        'subtitle': 'Senha, verificação em 2 etapas e sessões ativas',
        'icon': Icons.shield_outlined,
      },
      {
        'key': 'notificacoes',
        'title': 'Notificações Institucionais',
        'subtitle': 'Alertas de entregas, diários e prazos',
        'icon': Icons.notifications_none_rounded,
      },
      {
        'key': 'preferencias',
        'title': 'Preferências do Sistema',
        'subtitle': 'Tema, contraste e idioma da interface',
        'icon': Icons.tune_rounded,
      },
      {
        'key': 'privacidade',
        'title': 'Privacidade & LGPD',
        'subtitle': 'Visibilidade acadêmica e termos de uso',
        'icon': Icons.lock_outline_rounded,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: navItems.map((item) {
          final isSelected = activeSubtab == item['key'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    controller.setSettingsSubtab(item['key'] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF18181B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: jakarta(
                                size: 12.5,
                                weight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                size: 10.5,
                                weight: FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFA1A1AA)
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                    ],
                  ),
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
        return const DocenteNotificationPrefsCard();
      case 'preferencias':
        return const DocenteSystemPreferencesCard();
      case 'privacidade':
        return const DocentePrivacyLgpdCard();
      default:
        return DocenteProfileSettingsCard(controller: controller);
    }
  }
}
