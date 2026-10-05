// Desenvolvido por Rafael Henrique Inácio

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    this.password = '',
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasUpperAndLower =>
      password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'));
  bool get hasDigitOrSpecial =>
      password.contains(RegExp(r'[0-9]')) ||
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get strengthScore {
    int score = 0;
    if (password.isNotEmpty) score++;
    if (hasMinLength) score++;
    if (hasUpperAndLower) score++;
    if (hasDigitOrSpecial && hasMinLength) score++;
    return score;
  }

  Color _getBarColor(int index) {
    if (index >= strengthScore) {
      return const Color(0xFFE2E8F0); // slate-200 inativo
    }
    if (strengthScore <= 1) return const Color(0xFFEF4444); // red-500
    if (strengthScore == 2) return const Color(0xFFF59E0B); // amber-500
    if (strengthScore == 3) return const Color(0xFF3B82F6); // blue-500
    return const Color(0xFF10B981); // green-500
  }

  Widget _buildCheckItem(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 15,
            color: isSatisfied
                ? const Color(0xFF10B981)
                : const Color(0xFF94A3B8), // slate-400
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSatisfied
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Força da senha:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        // 4 Barras horizontais de força
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 3 ? 6.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: _getBarColor(index),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        // Critérios da senha
        _buildCheckItem(
          'Mínimo de 8 caracteres',
          hasMinLength,
        ),
        _buildCheckItem(
          'Pelo menos uma letra maiúscula e uma minúscula',
          hasUpperAndLower,
        ),
        _buildCheckItem(
          'Ao menos um número ou símbolo especial (!@#\$)',
          hasDigitOrSpecial,
        ),
      ],
    );
  }
}

