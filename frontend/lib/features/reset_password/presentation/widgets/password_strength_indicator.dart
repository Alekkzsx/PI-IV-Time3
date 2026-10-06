// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Indicador visual reativo da força e entropia da senha informada.
///
/// Avalia em tempo real a aderência aos padrões de segurança acadêmicos:
/// - Comprimento mínimo de 8 caracteres.
/// - Presença simultânea de caracteres em caixa alta e caixa baixa.
/// - Inclusão de dígitos numéricos ou caracteres especiais.
///
/// Apresenta o resultado através de 4 barras horizontais com graduação de cores
/// (vermelho, âmbar, azul e verde) e uma lista de critérios com ícones de validação.
class PasswordStrengthIndicator extends StatelessWidget {
  /// Expressões regulares cacheadas para otimização de performance durante digitação contínua.
  static final RegExp _upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Conteúdo textual atual da senha em avaliação.
  final String password;

  /// Cria um indicador de força de senha [PasswordStrengthIndicator].
  ///
  /// Parâmetros:
  /// - [password]: Texto da senha sendo avaliada (padrão: `''`).
  const PasswordStrengthIndicator({
    super.key,
    this.password = '',
  });

  /// Indica se a senha atinge o comprimento mínimo de 8 caracteres.
  bool get hasMinLength => password.length >= 8;

  /// Indica se a senha contém concomitantemente caracteres maiúsculos e minúsculos.
  bool get hasUpperAndLower =>
      password.contains(_upperCaseRegex) && password.contains(_lowerCaseRegex);

  /// Indica se a senha contém ao menos um número ou símbolo especial.
  bool get hasDigitOrSpecial =>
      password.contains(_digitRegex) ||
      password.contains(_specialCharRegex);

  /// Calcula a pontuação agregada de entropia da senha em uma escala de 0 a 4.
  int get strengthScore {
    int score = 0;
    if (password.isNotEmpty) score++;
    if (hasMinLength) score++;
    if (hasUpperAndLower) score++;
    if (hasDigitOrSpecial && hasMinLength) score++;
    return score;
  }


  /// Determina a cor visual da barra de entropia conforme o score calculado.
  Color _getBarColor(int index) {
    if (index >= strengthScore) {
      return const Color(0xFFE2E8F0); // slate-200 inativo
    }
    if (strengthScore <= 1) return const Color(0xFFEF4444); // red-500
    if (strengthScore == 2) return const Color(0xFFF59E0B); // amber-500
    if (strengthScore == 3) return const Color(0xFF3B82F6); // blue-500
    return const Color(0xFF10B981); // green-500
  }

  /// Constrói o item de requisito da senha com texto e ícone de checkmark colorido.
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

