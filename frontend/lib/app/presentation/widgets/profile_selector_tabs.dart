// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum UserProfile { aluno, docente, admin }

class ProfileSelectorTabs extends StatelessWidget {
  final UserProfile selectedProfile;
  final ValueChanged<UserProfile> onProfileChanged;

  const ProfileSelectorTabs({
    super.key,
    required this.selectedProfile,
    required this.onProfileChanged,
  });

  Widget _buildTabItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required UserProfile profile,
  }) {
    final isSelected = selectedProfile == profile;

    return Expanded(
      child: GestureDetector(
        onTap: () => onProfileChanged(profile),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.tabSelectedBackground
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.tabSelectedText
                    : AppColors.tabUnselectedText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.tabSelectedText
                      : AppColors.tabUnselectedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rótulo da seção
        Text(
          'SELECIONE SEU PERFIL',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 8),
        // Container das 3 Abas
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.tabBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildTabItem(
                context: context,
                label: 'Aluno',
                icon: Icons.school_outlined,
                profile: UserProfile.aluno,
              ),
              _buildTabItem(
                context: context,
                label: 'Docente',
                icon: Icons.badge_outlined,
                profile: UserProfile.docente,
              ),
              _buildTabItem(
                context: context,
                label: 'Admin',
                icon: Icons.shield_outlined,
                profile: UserProfile.admin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

