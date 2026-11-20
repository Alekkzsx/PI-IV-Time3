// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Variantes semânticas para pílulas de status nas Configurações do Portal.
enum SettingsPillVariant {
  /// Verde suave institucional (`#F0FDF4` / `#BBF7D0` / `#16A34A`).
  success,

  /// Âmbar suave institucional (`#FEF3C7` / `#FDE68A` / `#B45309`).
  warning,

  /// Neutro Zinc (`#F4F4F5` / `#E4E4E7` / `#52525B`).
  neutral,

  /// Vermelho suave (`#FEF2F2` / `#FECACA` / `#B91C1C`).
  danger,
}

/// Pílula semântica unificada para status de conta, sessões, 2FA e verificações.
class SettingsStatusPill extends StatelessWidget {
  final String label;
  final SettingsPillVariant variant;
  final IconData? icon;

  const SettingsStatusPill({
    super.key,
    required this.label,
    this.variant = SettingsPillVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, textColor) = switch (variant) {
      SettingsPillVariant.success => (
        const Color(0xFFF0FDF4),
        const Color(0xFFBBF7D0),
        const Color(0xFF16A34A),
      ),
      SettingsPillVariant.warning => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        const Color(0xFFB45309),
      ),
      SettingsPillVariant.neutral => (
        const Color(0xFFF4F4F5),
        const Color(0xFFE4E4E7),
        const Color(0xFF52525B),
      ),
      SettingsPillVariant.danger => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        const Color(0xFFB91C1C),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.5, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: jakarta(
              size: 10.5,
              weight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estilo padrão de botão primário nas Configurações do estudante.
ButtonStyle settingsPrimaryButtonStyle({
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  ),
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF18181B),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFE4E4E7),
    disabledForegroundColor: const Color(0xFF71717A),
    elevation: 0,
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

/// Botão de salvamento primário alinhado à direita com proteção contra overflow.
class SettingsSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SettingsSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check, size: 14, color: Colors.white),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: jakarta(
            size: 13,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: settingsPrimaryButtonStyle(),
      ),
    );
  }
}

/// Estilo padrão de botão secundário (contorno discreto) nas Configurações.
ButtonStyle settingsOutlinedButtonStyle({
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
  ),
}) {
  return OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF18181B),
    elevation: 0,
    padding: padding,
    side: const BorderSide(color: Color(0xFFE4E4E7)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

/// Estilo padrão de botão secundário para ações destrutivas ou de revogação.
ButtonStyle settingsDangerOutlinedButtonStyle({
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 9,
  ),
}) {
  return OutlinedButton.styleFrom(
    backgroundColor: const Color(0xFFFEF2F2),
    foregroundColor: const Color(0xFFB91C1C),
    elevation: 0,
    padding: padding,
    side: const BorderSide(color: Color(0xFFFECACA)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

/// [SettingsSectionCard]
///
/// Cartão de seção padronizado para a área de Configurações do estudante.
class SettingsSectionCard extends StatelessWidget {
  /// Conteúdo interno do cartão.
  final Widget child;

  /// Espaçamento interno (padrão: `EdgeInsets.all(24)`).
  final EdgeInsetsGeometry padding;

  /// Título opcional da seção renderizado no cabeçalho padrão.
  final String? title;

  /// Subtítulo descritivo opcional exibido abaixo do [title].
  final String? subtitle;

  /// Ícone opcional exibido ao lado do [title].
  final IconData? icon;

  /// Ação opcional alinhada à direita do cabeçalho da seção.
  final Widget? headerTrailing;

  /// Cria uma nova instância de [SettingsSectionCard].
  const SettingsSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.title,
    this.subtitle,
    this.icon,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null && title!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
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
      child: !hasHeader
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  size: 18,
                                  color: const Color(0xFF18181B),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  title!,
                                  style: jakarta(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: jakarta(
                                size: 12,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (headerTrailing != null) ...[
                      const SizedBox(width: 12),
                      headerTrailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
    );
  }
}

/// Linha ou subcard padronizado (`#FAFAFA`) para controles e itens de listagem.
class SettingsRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? titleBadge;
  final Widget? trailing;
  final String? tooltip;
  final bool darkIconBadge;
  final Color iconColor;
  final Color iconBgColor;

  const SettingsRowTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleBadge,
    this.trailing,
    this.tooltip,
    this.darkIconBadge = false,
    this.iconColor = const Color(0xFF18181B),
    this.iconBgColor = const Color(0xFFF4F4F5),
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460 && trailing != null;
          final badge = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: darkIconBadge ? const Color(0xFF18181B) : iconBgColor,
              shape: BoxShape.circle,
              border: darkIconBadge
                  ? null
                  : Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Icon(
              icon,
              size: 17,
              color: darkIconBadge ? Colors.white : iconColor,
            ),
          );

          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  if (titleBadge != null) titleBadge!,
                ],
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: jakarta(
                    size: 11.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(width: 12),
                    Expanded(child: textBlock),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            );
          }

          return Row(
            children: [
              badge,
              const SizedBox(width: 14),
              Expanded(child: textBlock),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          );
        },
      ),
    );

    if (tooltip != null && tooltip!.trim().isNotEmpty) {
      return Tooltip(message: tooltip!, child: content);
    }
    return content;
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
  String? labelText,
  String? errorText,
  Widget? suffix,
  bool readOnly = false,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    errorText: errorText,
    hintStyle: jakarta(
      size: 13,
      weight: FontWeight.w400,
      color: const Color(0xFFA1A1AA),
    ),
    labelStyle: jakarta(
      size: 12.5,
      weight: FontWeight.w500,
      color: const Color(0xFF71717A),
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
