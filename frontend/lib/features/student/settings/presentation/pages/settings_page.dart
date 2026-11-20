// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../widgets/widgets.dart';

/// [SettingsPage]
///
/// Página principal de Configurações da Conta do Estudante.
/// Apresenta navegação por categorias em menu lateral ou abas superiores (Perfil, Segurança & 2FA,
/// Notificações, Preferências do Sistema e Privacidade LGPD), orquestrando os 5 cards modulares de configuração.
class SettingsPage extends StatefulWidget {
  /// Cria uma nova instância de [SettingsPage].
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<SettingsPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final subtab = _controller.settingsSubtab;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: _buildSettingsSidebar(subtab),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSubtabContent(subtab)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactTabStrip(subtab),
                  const SizedBox(height: 20),
                  _buildSubtabContent(subtab),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações da Conta Discente',
          style: jakarta(
            size: 22,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gerencie sua identidade estudantil, camadas de proteção de acesso, preferências de alerta e direitos de privacidade.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<_SettingsNavMeta> _buildNavItems() {
    return [
      const _SettingsNavMeta(
        key: 'perfil',
        title: 'Perfil & Identidade',
        subtitle: 'Foto, curso e dados acadêmicos oficiais',
        icon: Icons.person_outline_rounded,
      ),
      _SettingsNavMeta(
        key: 'seguranca',
        title: 'Segurança & Acessos',
        subtitle: 'Senha, 2FA e sessões ativas',
        icon: Icons.shield_outlined,
        statusLabel: _controller.isTwoFactorEnabled
            ? '2FA Ativo'
            : '2FA Desativado',
        statusVariant: _controller.isTwoFactorEnabled
            ? SettingsPillVariant.success
            : SettingsPillVariant.warning,
      ),
      const _SettingsNavMeta(
        key: 'notificacoes',
        title: 'Central de Notificações',
        subtitle: 'Alertas no portal, e-mails e SMS',
        icon: Icons.notifications_none_rounded,
      ),
      const _SettingsNavMeta(
        key: 'preferencias',
        title: 'Preferências do Sistema',
        subtitle: 'Tema, densidade e acessibilidade',
        icon: Icons.tune_rounded,
      ),
      const _SettingsNavMeta(
        key: 'privacidade',
        title: 'Privacidade & LGPD',
        subtitle: 'Visibilidade para turmas e termos',
        icon: Icons.lock_outline_rounded,
      ),
    ];
  }

  Widget _buildSettingsSidebar(String activeSubtab) {
    final navItems = _buildNavItems();

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
          final isSelected = activeSubtab == item.key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _controller.setSettingsSubtab(item.key),
                hoverColor: InstColors.stone,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? InstColors.stoneActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE4E4E7)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF18181B)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF52525B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: jakarta(
                                size: 13,
                                weight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: jakarta(
                                size: 11,
                                color: isSelected
                                    ? const Color(0xFF52525B)
                                    : const Color(0xFF71717A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.statusLabel != null) ...[
                              const SizedBox(height: 6),
                              SettingsStatusPill(
                                label: item.statusLabel!,
                                variant: item.statusVariant,
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildCompactTabStrip(String activeSubtab) {
    final navItems = _buildNavItems();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: navItems.map((item) {
            final isSelected = activeSubtab == item.key;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => _controller.setSettingsSubtab(item.key),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? InstColors.stoneActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE4E4E7)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFF18181B)
                            : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.title,
                        style: jakarta(
                          size: 12.5,
                          weight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF18181B)
                              : const Color(0xFF52525B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubtabContent(String activeSubtab) {
    switch (activeSubtab) {
      case 'perfil':
        return StudentProfileSettingsCard(controller: _controller);
      case 'seguranca':
        return StudentSecuritySessionsCard(controller: _controller);
      case 'notificacoes':
        return StudentNotificationPrefsCard(controller: _controller);
      case 'preferencias':
        return const StudentSystemPreferencesCard();
      case 'privacidade':
        return const StudentPrivacyLgpdCard();
      default:
        return StudentProfileSettingsCard(controller: _controller);
    }
  }
}

class _SettingsNavMeta {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? statusLabel;
  final SettingsPillVariant statusVariant;

  const _SettingsNavMeta({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.statusLabel,
    this.statusVariant = SettingsPillVariant.neutral,
  });
}

typedef StudentSettingsPage = SettingsPage;
