// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Campo de formulário composto para inserção do identificador de recuperação.
///
/// Apresenta um cabeçalho horizontal com rótulo descritivo duplo (título à esquerda
/// e formato de exemplo à direita), ícone de crachá institucional prefixado e
/// bordas estilizadas conforme o estado de foco e erro de validação.
class RecoveryInputField extends StatelessWidget {
  /// Notificador acionado a cada modificação no texto digitado.
  final ValueChanged<String> onChanged;

  /// Ação disparada quando o usuário pressiona a tecla de submissão do teclado virtual.
  final VoidCallback? onSubmitted;

  /// Mensagem de erro de validação para renderização abaixo do campo, ou `null` se válido.
  final String? errorMessage;

  /// Título contextual do campo (ex: R.A. do Aluno, Matrícula do Docente).
  final String inputTitle;

  /// Exemplo textual da sintaxe esperada (ex: `ex: 2024.1.00892`).
  final String example;

  /// Texto temporário exibido no interior do campo antes da digitação (placeholder).
  final String placeholder;

  /// Cria uma instância do campo de entrada de recuperação [RecoveryInputField].
  ///
  /// Parâmetros:
  /// - [onChanged]: Callback obrigatório de alteração de texto.
  /// - [onSubmitted]: Callback opcional de confirmação no teclado.
  /// - [errorMessage]: Mensagem de erro descritiva.
  /// - [inputTitle]: Título posicionado no cabeçalho superior esquerdo.
  /// - [example]: Exemplo ilustrativo posicionado no cabeçalho superior direito.
  /// - [placeholder]: Texto indicativo interno do campo.
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
