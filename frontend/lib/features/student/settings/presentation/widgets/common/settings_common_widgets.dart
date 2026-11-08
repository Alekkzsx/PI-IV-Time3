// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [SettingsSectionCard]
///
/// Cartão de seção padronizado para a área de Configurações do estudante.
class SettingsSectionCard extends StatelessWidget {
  /// Conteúdo interno do cartão.
  final Widget child;

  /// Espaçamento interno (padrão: `EdgeInsets.all(24)`).
  final EdgeInsetsGeometry padding;

  /// Cria uma nova instância de [SettingsSectionCard].
  const SettingsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

/// [SettingsFieldLabel]
///
/// Rótulo padronizado para campos de formulário em Configurações,
/// exibindo tag lateral de permissão de edição ou bloqueio regimental.
class SettingsFieldLabel extends StatelessWidget {
  /// Rótulo principal do campo.
  final String label;

  /// Texto auxiliar de status/permissão.
  final String? tagText;

  /// Define se o campo é editável pelo discente.
  final bool isEditable;

  /// Cria uma nova instância de [SettingsFieldLabel].
  const SettingsFieldLabel({
    super.key,
    required this.label,
    this.tagText,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w600,
                color: const Color(0xFF3F3F46),
              ),
            ),
          ),
          if (tagText != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEditable
                      ? Icons.edit_outlined
                      : Icons.lock_outline_rounded,
                  size: 12,
                  color: const Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Text(
                  tagText!,
                  style: jakarta(
                    size: 10.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// [SettingsKpiTile]
///
/// Bloco visual de indicador acadêmico (RA, Curso, Semestre, CR) no perfil discente.
class SettingsKpiTile extends StatelessWidget {
  /// Rótulo em caixa alta do indicador.
  final String label;

  /// Valor exibido em destaque.
  final String value;

  /// Ícone representativo do indicador.
  final IconData icon;

  /// Destaca o bloco com borda escura quando `true`.
  final bool highlight;

  /// Cria uma nova instância de [SettingsKpiTile].
  const SettingsKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFAFAFA) : const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight
                  ? const Color(0xFF18181B)
                  : const Color(0xFFF4F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: highlight ? Colors.white : const Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Constrói a decoração padronizada de campos de entrada na tela de Configurações.
InputDecoration buildSettingsInputDecoration({
  String? hintText,
  Widget? suffix,
  bool readOnly = false,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: jakarta(
      size: 13,
      weight: FontWeight.w400,
      color: const Color(0xFFA1A1AA),
    ),
    filled: true,
    fillColor: readOnly ? const Color(0xFFFAFAFA) : Colors.white,
    suffix: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
    ),
  );
}
