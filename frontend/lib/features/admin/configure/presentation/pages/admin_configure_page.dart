// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import '../widgets/academic_guidelines_tab.dart';
import '../widgets/admin_profile_tab.dart';
import '../widgets/campus_alerts_tab.dart';
import '../widgets/governance_lgpd_tab.dart';
import '../widgets/security_credentials_tab.dart';
import '../widgets/system_preferences_tab.dart';

/// Main Administration Account Configuration page.
///
/// Coordinates the 6 managerial navigation tabs with responsive desktop layout
/// supporting academic guidelines, profile, security, campus alerts, preferences, and LGPD.
class AdminConfigurePage extends StatefulWidget {
  const AdminConfigurePage({super.key});

  @override
  State<AdminConfigurePage> createState() => _AdminConfigurePageState();
}

class _AdminConfigurePageState extends State<AdminConfigurePage> {
  int _activeTabIndex = 0;

  final List<_NavTabItem> _navItems = const [
    _NavTabItem(
      icon: Icons.school_outlined,
      title: 'Diretrizes Acadêmicas (Metas)',
      subtitle: 'Metas regimentais de notas, frequência e corte',
    ),
    _NavTabItem(
      icon: Icons.person_outline_rounded,
      title: 'Perfil Administrativo',
      subtitle: 'Identificação, cargo e dados corporativos',
    ),
    _NavTabItem(
      icon: Icons.verified_user_outlined,
      title: 'Segurança & Credenciais',
      subtitle: 'Senha, verificação em 2 etapas e sessões',
    ),
    _NavTabItem(
      icon: Icons.notifications_none_rounded,
      title: 'Alertas do Campus',
      subtitle: 'Protocolos de secretaria e travas regimentais',
    ),
    _NavTabItem(
      icon: Icons.tune_rounded,
      title: 'Preferências do Sistema',
      subtitle: 'Parâmetros de interface e temas',
    ),
    _NavTabItem(
      icon: Icons.lock_outline_rounded,
      title: 'Governança & LGPD',
      subtitle: 'Políticas institucionais de privacidade',
    ),
  ];

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return const AcademicGuidelinesTab();
      case 1:
        return const AdminProfileTab();
      case 2:
        return const SecurityCredentialsTab();
      case 3:
        return const CampusAlertsTab();
      case 4:
        return const SystemPreferencesTab();
      case 5:
        return const GovernanceLgpdTab();
      default:
        return const AcademicGuidelinesTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Main Section Header
            const Text(
              'Configurações da Conta de Administração',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestão de credenciais com permissões elevadas, autenticação multifator e parâmetros corporativos.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),

            // 2. Two-Column Layout (Sidebar Navigation + Active Tab Content)
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 980;
                return isStacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNavigationMenu(),
                          const SizedBox(height: 24),
                          _buildActiveTabContent(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 320,
                            child: _buildNavigationMenu(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildActiveTabContent(),
                          ),
                        ],
                      );
              },
            ),

            const SizedBox(height: 48),

            // 3. Institutional Footer
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Text(
                  '© 2026 AGMRM  |  Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Ajuda',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Privacidade',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _activeTabIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isSelected ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavTabItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NavTabItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
