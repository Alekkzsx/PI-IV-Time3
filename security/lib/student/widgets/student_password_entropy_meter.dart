// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../validators/password_entropy_validator.dart';

/// Widget institucional defensivo que exibe em tempo real o medidor de força e entropia de senha.
///
/// Avalia os 4 vetores da política AGMRM:
/// 1. Mínimo de 8 caracteres.
/// 2. Letras maiúsculas e minúsculas misturadas.
/// 3. Pelo menos um dígito numérico (0-9).
/// 4. Pelo menos um caractere especial ou símbolo.
class StudentPasswordEntropyMeter extends StatelessWidget {
  final String password;

  const StudentPasswordEntropyMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final score = PasswordEntropyValidator.calculateScore(password);


    final hasMinLength = password.length >= PasswordEntropyValidator.minLength;
    final hasMixedCase = RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]]').hasMatch(password);

    Color meterColor;
    String statusLabel;

    if (password.isEmpty) {
      meterColor = const Color(0xFF94A3B8);
      statusLabel = 'Digite a nova senha';
    } else if (score < 2) {
      meterColor = const Color(0xFFEF4444); // Vermelho / Fraca
      statusLabel = 'Senha Muito Fraca (Insegura)';
    } else if (score == 2) {
      meterColor = const Color(0xFFF59E0B); // Amarelo / Moderada
      statusLabel = 'Senha Moderada (Requer mais requisitos)';
    } else if (score == 3) {
      meterColor = const Color(0xFF10B981); // Verde / Forte
      statusLabel = 'Senha Forte (Aceita para cadastro)';
    } else {
      meterColor = const Color(0xFF059669); // Verde Escuro / Excelente
      statusLabel = 'Senha Excelente (Altamente Segura)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Segurança da Senha: $score / 4',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: meterColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progresso segmentada em 4 níveis
          Row(
            children: List.generate(4, (index) {
              final active = index < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active ? meterColor : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Indicadores de requisitos
          _buildRequirementItem('Mínimo de 8 caracteres', hasMinLength),
          _buildRequirementItem('Letras maiúsculas e minúsculas', hasMixedCase),
          _buildRequirementItem('Pelo menos um número (0-9)', hasDigit),
          _buildRequirementItem('Pelo menos um caractere especial (!@#\$...)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? const Color(0xFF334155) : const Color(0xFF64748B),
              decoration: met ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
