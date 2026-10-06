// Desenvolvido por Murilo (Murillo Caravita)

import 'package:flutter/material.dart';

/// Perfis de usuário aceitos no fluxo de autenticação do portal.
enum UserProfile {
  aluno,
  docente,
  admin,
}

/// Seletor de perfis de acesso em abas estilizadas (Aluno, Docente, Admin).
class LoginProfileTabs extends StatelessWidget {
  final UserProfile selectedProfile;
  final ValueChanged<UserProfile> onProfileChanged;

  const LoginProfileTabs({
    super.key,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Container externo: bg-[#F1F5F9] p-1 rounded-xl flex items-center gap-1 border border-slate-200/70
    return Container(
      padding: const EdgeInsets.all(4), // p-1 (4px)
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // bg-[#F1F5F9]
        borderRadius: BorderRadius.circular(12), // rounded-xl (12px)
        border: Border.all(
          color: const Color(0xB3E2E8F0), // border-slate-200/70
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _ProfileTab(
            label: 'Aluno',
            icon: Icons.school_outlined,
            selected: selectedProfile == UserProfile.aluno,
            onTap: () => onProfileChanged(UserProfile.aluno),
          ),
          const SizedBox(width: 4), // gap-1 (4px)
          _ProfileTab(
            label: 'Docente',
            icon: Icons.assignment_ind_outlined,
            selected: selectedProfile == UserProfile.docente,
            onTap: () => onProfileChanged(UserProfile.docente),
          ),
          const SizedBox(width: 4), // gap-1 (4px)
          _ProfileTab(
            label: 'Admin',
            icon: Icons.verified_user_outlined,
            selected: selectedProfile == UserProfile.admin,
            onTap: () => onProfileChanged(UserProfile.admin),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Paleta de cores Slate baseada na especificação Tailwind CSS
    const slate900 = Color(0xFF0F172A);
    const slate700 = Color(0xFF334155);
    const slate600 = Color(0xFF475569);
    const slate200Border80 = Color(0xCCE2E8F0); // border-slate-200/80

    final textColor = widget.selected
        ? slate900
        : (_isHovered ? slate900 : slate600);

    final iconColor = widget.selected
        ? slate700
        : (_isHovered ? slate700 : slate600);

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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // py-2 px-3
            decoration: BoxDecoration(
              color: widget.selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8), // rounded-lg (8px)
              border: Border.all(
                color: widget.selected ? slate200Border80 : Colors.transparent,
                width: 1,
              ),
              boxShadow: widget.selected
                  ? const [
                      BoxShadow(
                        color: Color(0x0D000000), // shadow-sm (0 1px 2px 0 rgb(0 0 0 / 0.05))
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: iconColor,
                  size: 16, // w-4 h-4 (16px)
                ),
                const SizedBox(width: 8), // gap-2 (8px)
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13, // text-xs sm:text-sm
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

