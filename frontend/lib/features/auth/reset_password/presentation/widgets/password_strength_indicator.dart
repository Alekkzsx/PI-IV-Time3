// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

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
  const PasswordStrengthIndicator({super.key, this.password = ''});

  /// Indica se a senha atinge o comprimento mínimo de 8 caracteres.
  bool get hasMinLength => password.length >= 8;

  /// Indica se a senha contém concomitantemente caracteres maiúsculos e minúsculos.
  bool get hasUpperAndLower =>
      password.contains(_upperCaseRegex) && password.contains(_lowerCaseRegex);

  /// Indica se a senha contém ao menos um número ou símbolo especial.
  bool get hasDigitOrSpecial =>
      password.contains(_digitRegex) || password.contains(_specialCharRegex);

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
      return const Color(0xFFE2E8F0); // bg-slate-200 inativo
    }
    return const Color(0xFF0B1325); // ativo #0B1325
  }

  /// Constrói o item de requisito da senha com texto e ícone de checkmark colorido.
  Widget _buildCheckItem(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: isSatisfied
                ? const Color(0xFF10B981) // emerald-500
                : const Color(0xFFCBD5E1), // slate-300
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSatisfied
                    ? const Color(0xFF334155) // slate-700
                    : const Color(0xFF64748B), // slate-500
                fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
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
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
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
        _buildCheckItem('Mínimo de 8 caracteres', hasMinLength),
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
