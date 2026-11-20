// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção atômica para seleção de tema da interface institucional.
class SystemThemeSettingsSection extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onThemeSelected;

  const SystemThemeSettingsSection({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  Widget _buildThemeOptionCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = selectedTheme == id;

    return InkWell(
      onTap: () => onThemeSelected(id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF71717A),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF18181B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: jakarta(
                size: 13,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: jakarta(size: 11, color: const Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aparência & Tema',
            style: jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Defina o modo de exibição da interface em seus dispositivos.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildThemeOptionCard(
                  id: 'claro',
                  title: 'Claro (Padrão)',
                  description:
                      'Visual padrão com alto contraste e tons neutros de cinza e branco.',
                  icon: Icons.light_mode_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildThemeOptionCard(
                  id: 'escuro',
                  title: 'Modo Escuro',
                  description:
                      'Reduz o cansaço visual em ambientes de baixa luminosidade.',
                  icon: Icons.dark_mode_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildThemeOptionCard(
                  id: 'sistema',
                  title: 'Sincronizar com SO',
                  description:
                      'Alterna automaticamente conforme o tema do seu sistema operacional.',
                  icon: Icons.brightness_auto_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
