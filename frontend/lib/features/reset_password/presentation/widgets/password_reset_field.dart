// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Campo de formulário customizado para digitação e confirmação de senhas.
///
/// Apresenta um rótulo superior estilizado em caixa alta com espaçamento entre letras,
/// ícone temático inicial configurável, alternância visual entre texto ofuscado e visível
/// por meio do botão sufixo de olho, e bordas arredondadas institucionais.
class PasswordResetField extends StatelessWidget {
  /// Controlador de texto vinculado ao campo de senha.
  final TextEditingController controller;

  /// Rótulo superior exibido acima do campo de entrada (ex: 'NOVA SENHA').
  final String label;

  /// Texto indicativo exibido quando o campo estiver desprovido de texto (hint).
  final String hintText;

  /// Ícone decorativo posicionado à esquerda do campo de entrada.
  final IconData prefixIcon;

  /// Determina se o texto do campo deve ser ocultado com caracteres de ofuscação.
  final bool isObscured;

  /// Ação disparada quando o usuário toca no botão de alternância de visibilidade.
  final VoidCallback onToggleVisibility;

  /// Cria uma nova instância de [PasswordResetField].
  ///
  /// Parâmetros:
  /// - [controller]: Controlador do [TextField].
  /// - [label]: Título superior do campo.
  /// - [hintText]: Texto sugestivo de preenchimento.
  /// - [prefixIcon]: Ícone exibido no início do campo.
  /// - [isObscured]: Se a senha deve ser ofuscada.
  /// - [onToggleVisibility]: Callback para alternar a exibição da senha.
  const PasswordResetField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.isObscured,
    required this.onToggleVisibility,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

