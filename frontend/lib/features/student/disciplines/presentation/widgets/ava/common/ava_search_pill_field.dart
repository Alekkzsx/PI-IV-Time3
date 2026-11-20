// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaSearchPillField]
///
/// Campo de busca em formato pílula canônico do Cockpit AVA (`#FFFFFF`,
/// borda `1px #E5E7EB`, raio `20px`, altura `36px`), idêntico às telas de
/// referência de Fóruns e Repositório de Arquivos.
class AvaSearchPillField extends StatelessWidget {
  /// Controlador opcional do texto de busca.
  final TextEditingController? controller;

  /// Texto de dica exibido quando o campo está vazio.
  final String hintText;

  /// Callback disparado a cada alteração do termo pesquisado.
  final ValueChanged<String>? onChanged;

  /// Largura máxima opcional para cabeçalhos desktop (ex.: `240`).
  final double? width;

  /// Cria uma nova instância de [AvaSearchPillField].
  const AvaSearchPillField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: jakarta(
          size: 12.5,
          weight: FontWeight.w500,
          color: const Color(0xFF18181B),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: jakarta(
            size: 12.5,
            weight: FontWeight.w400,
            color: const Color(0xFFA1A1AA),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 16,
            color: Color(0xFF71717A),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 36,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
        ),
      ),
    );

    if (width == null) return field;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width!),
      child: field,
    );
  }
}

