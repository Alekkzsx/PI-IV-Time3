// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import '../widgets/academic_guidelines_tab.dart';
import '../widgets/admin_profile_tab.dart';
import '../widgets/campus_alerts_tab.dart';
import '../widgets/governance_lgpd_tab.dart';
import '../widgets/rbac_matrix_tab.dart';
import '../widgets/security_credentials_tab.dart';
import '../widgets/system_preferences_tab.dart';

/// Página principal de Configurações da Conta de Administração.
///
/// Coordena as 7 abas gerenciais de navegação com layout desktop responsivo
/// oferecendo suporte a diretrizes acadêmicas, perfil, segurança, alertas do campus, preferências, LGPD e matriz RBAC.
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
      icon: Icons.security_outlined,
      title: 'Matriz de Permissões (RBAC)',
      subtitle: 'Controle de privilégios entre discentes, docentes e TI',
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
        return const RbacMatrixTab();
      case 2:
        return const AdminProfileTab();
      case 3:
        return const SecurityCredentialsTab();
      case 4:
        return const CampusAlertsTab();
      case 5:
        return const SystemPreferencesTab();
      case 6:
        return const GovernanceLgpdTab();
      default:
        return const AcademicGuidelinesTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InstColors.stone,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cabeçalho da Seção Principal
                  Text(
                    'Configurações da Conta de Administração',
                    style: jakarta(
                      size: 22,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestão de credenciais com permissões elevadas, autenticação multifator e parâmetros corporativos.',
                    style: jakarta(size: 13, color: InstColors.muted),
                  ),
                  const SizedBox(height: 28),

                  // 2. Layout em Duas Colunas (Menu Lateral de Navegação + Conteúdo da Aba Ativa)
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
                                Expanded(child: _buildActiveTabContent()),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
          AdminFooter(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            onHelpTap: () => _showInformationDialog(
              title: 'Central de ajuda',
              message:
                  'Para suporte administrativo, entre em contato com a DTI pelo canal institucional.',
            ),
            onPrivacyTap: () => _showInformationDialog(
              title: 'Privacidade',
              message:
                  'O tratamento de dados segue as políticas institucionais de Governança e LGPD.',
            ),
          ),
        ],
      ),
    );
  }

  void _showInformationDialog({
    required String title,
    required String message,
  }) {
    AcademicModalDialog.show<void>(
      context: context,
      builder: (_) => AcademicModalDialog(
        title: title,
        icon: Icons.info_outline_rounded,
        maxWidth: 460,
        cancelLabel: 'Entendi',
        child: Text(
          message,
          style: jakarta(size: 13.5, color: InstColors.body, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Container(
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? InstColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? Colors.white : InstColors.toggleIcon,
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
                              weight: FontWeight.w700,
                              color: isSelected ? Colors.white : InstColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: jakarta(
                              size: 10.5,
                              color: isSelected
                                  ? InstColors.faint
                                  : InstColors.muted,
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
