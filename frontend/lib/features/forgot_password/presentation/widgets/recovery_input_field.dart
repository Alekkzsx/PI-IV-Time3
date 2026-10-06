// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecoveryInputField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final String? errorMessage;
  final String inputTitle;
  final String example;
  final String placeholder;

  const RecoveryInputField({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.errorMessage,
    this.inputTitle = 'R.A., Matrícula ou E-mail Institucional',
    this.example = 'ex: 2024.1.00092',
    this.placeholder = 'Digite seu R.A., matrícula ou e-mail institucional',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rótulo Duplo (Título à esquerda, Exemplo à direita)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                inputTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              example,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Campo de Texto com Ícone de Crachá
        TextFormField(
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.badge_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorText: errorMessage,
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.borderFocused,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
