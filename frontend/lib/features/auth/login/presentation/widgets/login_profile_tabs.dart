// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../shared/domain/models/recovery_session.dart';

export '../../../shared/domain/models/recovery_session.dart' show UserProfile;

/// Seletor de perfis de acesso em abas estilizadas (Aluno, Docente, Admin).
///
/// Renderiza uma barra segmentada permitindo que o usuário escolha seu perfil de acesso,
/// adaptando visualmente as dicas e validações da tela de login.
class LoginProfileTabs extends StatelessWidget {
  /// Perfil atualmente selecionado.
  final UserProfile selectedProfile;

  /// Callback disparado quando o usuário seleciona um novo perfil.
  final ValueChanged<UserProfile> onProfileChanged;

  /// Construtor de [LoginProfileTabs].
  const LoginProfileTabs({
    super.key,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Container externo: bg-[#F1F5F9] p-1 rounded-xl flex items-center gap-1 border border-slate-200/70
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          _ProfileTab(
            label: 'Aluno',
            icon: Icons.school_outlined,
            selected: selectedProfile == UserProfile.aluno,
            onTap: () => onProfileChanged(UserProfile.aluno),
          ),
          const SizedBox(width: 4),
          _ProfileTab(
            label: 'Docente',
            icon: Icons.badge_outlined,
            selected: selectedProfile == UserProfile.docente,
            onTap: () => onProfileChanged(UserProfile.docente),
          ),
          const SizedBox(width: 4),
          _ProfileTab(
            label: 'Admin',
            icon: Icons.shield_outlined,
            selected: selectedProfile == UserProfile.admin,
            onTap: () => onProfileChanged(UserProfile.admin),
          ),
        ],
      ),
    );
  }
}

/// Item individual de aba no seletor de perfis.
///
/// Suporta estados de foco, seleção e hover com animação de transição suave.
class _ProfileTab extends StatefulWidget {
  /// Texto descritivo exibido na aba.
  final String label;

  /// Ícone representativo da categoria de perfil.
  final IconData icon;

  /// Indica se esta aba está atualmente selecionada.
  final bool selected;

  /// Callback acionado no evento de clique do usuário.
  final VoidCallback onTap;

  /// Cria uma instância da aba de perfil [_ProfileTab].
  const _ProfileTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

/// Estado reativo de [_ProfileTab] responsável pelo gerenciamento de hover.
class _ProfileTabState extends State<_ProfileTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.selected
        ? AppColors.tabSelectedText
        : (_isHovered
              ? AppColors.tabSelectedText
              : AppColors.tabUnselectedText);

    final iconColor = widget.selected
        ? AppColors.slate700
        : (_isHovered ? AppColors.slate700 : AppColors.tabUnselectedText);

    final textWeight = widget.selected ? FontWeight.w600 : FontWeight.w500;

    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.tabSelectedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected
                    ? AppColors.borderLight
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: widget.selected
                  ? const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: textWeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
