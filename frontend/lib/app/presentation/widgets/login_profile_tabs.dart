// Desenvolvido por Murillo Caravita

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

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
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _ProfileTab(
            label: 'Aluno',
            icon: Icons.school_outlined,
            selected: selectedProfile == UserProfile.aluno,
            onTap: () => onProfileChanged(UserProfile.aluno),
          ),
          _ProfileTab(
            label: 'Docente',
            icon: Icons.badge_outlined,
            selected: selectedProfile == UserProfile.docente,
            onTap: () => onProfileChanged(UserProfile.docente),
          ),
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

class _ProfileTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.tabSelectedBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.tabSelectedText
                    : AppColors.tabUnselectedText,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.tabSelectedText
                      : AppColors.tabUnselectedText,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

