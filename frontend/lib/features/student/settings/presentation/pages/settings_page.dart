// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
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
        final isDesktop = constraints.maxWidth >= 860;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coluna Esquerda: Menu lateral de categorias (280px)
                  SizedBox(
                    width: 280,
                    child: _buildSettingsSidebar(subtab),
                  ),
                  const SizedBox(width: 24),
                  // Coluna Direita: Conteúdo dinâmico da subaba selecionada
                  Expanded(
                    child: _buildSubtabContent(subtab),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSettingsSidebar(subtab, isCompact: true),
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
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gerencie sua identidade estudantil, camadas de proteção de acesso, preferências de alerta e direitos de privacidade.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSidebar(String activeSubtab, {bool isCompact = false}) {
    final navItems = [
      {
        'key': 'perfil',
        'title': 'Perfil & Identidade',
        'subtitle': 'Foto, curso e dados acadêmicos oficiais',
        'icon': Icons.person_outline_rounded,
      },
      {
        'key': 'seguranca',
        'title': 'Segurança & Acessos',
        'subtitle': 'Senha, 2FA e sessões ativas',
        'icon': Icons.shield_outlined,
        'badge': _controller.isTwoFactorEnabled ? '2FA ATIVO' : 'DESATIVADO',
      },
      {
        'key': 'notificacoes',
        'title': 'Central de Notificações',
        'subtitle': 'Alertas no portal, e-mails e SMS',
        'icon': Icons.notifications_none_rounded,
      },
      {
        'key': 'preferencias',
        'title': 'Preferências do Sistema',
        'subtitle': 'Tema, densidade e acessibilidade',
        'icon': Icons.tune_rounded,
      },
      {
        'key': 'privacidade',
        'title': 'Privacidade & LGPD',
        'subtitle': 'Visibilidade para turmas e termos',
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
          final badgeText = item['badge'] as String?;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _controller.setSettingsSubtab(item['key'] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    item['title'] as String,
                                    style: jakarta(
                                      size: 13,
                                      weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF18181B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badgeText != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (_controller.isTwoFactorEnabled
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB91C1C))
                                          : (_controller.isTwoFactorEnabled
                                              ? const Color(0xFFF0FDF4)
                                              : const Color(0xFFFEF2F2)),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : (_controller.isTwoFactorEnabled
                                                ? const Color(0xFFBBF7D0)
                                                : const Color(0xFFFECACA)),
                                      ),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: jakarta(
                                        size: 9,
                                        weight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (_controller.isTwoFactorEnabled
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: jakarta(
                                size: 10.5,
                                color: isSelected ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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


typedef StudentSettingsPage = SettingsPage;
