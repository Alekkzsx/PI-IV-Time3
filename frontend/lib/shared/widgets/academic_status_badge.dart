// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Tipo semântico de status acadêmico para unificar tags de alunos, docentes e secretaria.
enum AcademicStatusType {
  aprovado,
  reprovado,
  recuperacao,
  ativo,
  inativo,
  trancado,
  concluido,
  pendente,
  emAnalise,
  deferido,
  indeferido,
  atrasado,
  entregue,
  aberto,
  fechado,
  custom,
}

/// Pílula/Badge semântica reutilizável com resolução automática de estilo, cores e bordas.
class AcademicStatusBadge extends StatelessWidget {
  final String? label;
  final dynamic academicStatus;
  final AcademicStatusType type;
  final bool showDot;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? customBgColor;
  final Color? customTextColor;
  final Color? customBorderColor;

  const AcademicStatusBadge({
    super.key,
    this.label,
    this.academicStatus,
    this.type = AcademicStatusType.pendente,
    this.showDot = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 6,
    this.customBgColor,
    this.customTextColor,
    this.customBorderColor,
  });

  /// Construtor facilitador para strings dinâmicas comuns vindas de APIs ou banco de dados.
  factory AcademicStatusBadge.fromString(
    String status, {
    Key? key,
    bool showDot = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 4,
    ),
  }) {
    final lower = status.trim().toLowerCase();
    AcademicStatusType resolvedType = AcademicStatusType.custom;

    if (lower.contains('aprovad') ||
        lower == 'deferido' ||
        lower == 'ativo' ||
        lower == 'entregue' ||
        lower == 'concluido') {
      resolvedType = AcademicStatusType.aprovado;
    } else if (lower.contains('reprovad') ||
        lower == 'indeferido' ||
        lower == 'inativo' ||
        lower.contains('atrasad')) {
      resolvedType = AcademicStatusType.reprovado;
    } else if (lower.contains('recupera') ||
        lower.contains('exame') ||
        lower == 'pendente' ||
        lower.contains('analise') ||
        lower.contains('análise') ||
        lower == 'trancado') {
      resolvedType = AcademicStatusType.recuperacao;
    } else if (lower == 'aberto') {
      resolvedType = AcademicStatusType.aberto;
    } else if (lower == 'fechado') {
      resolvedType = AcademicStatusType.fechado;
    }

    return AcademicStatusBadge(
      key: key,
      label: status,
      type: resolvedType,
      showDot: showDot,
      padding: padding,
    );
  }

  AcademicStatusType _resolveType() {
    if (academicStatus != null) {
      if (academicStatus is AcademicStatusType) {
        return academicStatus as AcademicStatusType;
      }
      final str = academicStatus.toString().toLowerCase();
      if (str.contains('aprovad') ||
          str == 'deferido' ||
          str == 'ativo' ||
          str == 'entregue' ||
          str == 'concluido') {
        return AcademicStatusType.aprovado;
      } else if (str.contains('reprovad') ||
          str == 'indeferido' ||
          str == 'inativo' ||
          str.contains('atrasad')) {
        return AcademicStatusType.reprovado;
      } else if (str.contains('recupera') ||
          str.contains('exame') ||
          str == 'pendente' ||
          str.contains('analise') ||
          str.contains('análise') ||
          str == 'trancado') {
        return AcademicStatusType.recuperacao;
      } else if (str == 'aberto') {
        return AcademicStatusType.aberto;
      } else if (str == 'fechado') {
        return AcademicStatusType.fechado;
      }
      return AcademicStatusType.custom;
    }
    return type;
  }

  String _resolveLabel(AcademicStatusType resolvedType) {
    if (label != null && label!.isNotEmpty) return label!;
    if (academicStatus != null) {
      if (academicStatus is Enum) {
        final name = (academicStatus as Enum).name;
        if (name == 'aprovado') return 'APROVADO';
        if (name == 'exame') return 'EM EXAME';
        if (name == 'reprovadoPorNota') return 'REPR. NOTA';
        if (name == 'reprovadoPorFalta') return 'REPR. FALTA';
      }
      if (academicStatus is String) {
        return academicStatus as String;
      }
    }
    return _defaultLabelForType(resolvedType);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveType = _resolveType();
    final (bgColor, textColor, borderColor, dotColor) = _resolveColors(
      effectiveType,
    );
    final displayLabel = _resolveLabel(effectiveType);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: customBgColor ?? bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: customBorderColor ?? (borderColor ?? Colors.transparent),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: customTextColor ?? textColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _defaultLabelForType(AcademicStatusType type) {
    switch (type) {
      case AcademicStatusType.aprovado:
        return 'APROVADO';
      case AcademicStatusType.reprovado:
        return 'REPROVADO';
      case AcademicStatusType.recuperacao:
        return 'EM RECUPERAÇÃO';
      case AcademicStatusType.ativo:
        return 'ATIVO';
      case AcademicStatusType.inativo:
        return 'INATIVO';
      case AcademicStatusType.trancado:
        return 'TRANCADO';
      case AcademicStatusType.concluido:
        return 'CONCLUÍDO';
      case AcademicStatusType.pendente:
        return 'PENDENTE';
      case AcademicStatusType.emAnalise:
        return 'EM ANÁLISE';
      case AcademicStatusType.deferido:
        return 'DEFERIDO';
      case AcademicStatusType.indeferido:
        return 'INDEFERIDO';
      case AcademicStatusType.atrasado:
        return 'ATRASADO';
      case AcademicStatusType.entregue:
        return 'ENTREGUE';
      case AcademicStatusType.aberto:
        return 'ABERTO';
      case AcademicStatusType.fechado:
        return 'FECHADO';
      case AcademicStatusType.custom:
        return 'REGULAR';
    }
  }

  (Color, Color, Color?, Color) _resolveColors(AcademicStatusType targetType) {
    switch (targetType) {
      case AcademicStatusType.aprovado:
      case AcademicStatusType.ativo:
      case AcademicStatusType.deferido:
      case AcademicStatusType.entregue:
      case AcademicStatusType.concluido:
        return (
          const Color(0xFFECFDF5),
          InstColors.success,
          const Color(0xFFA7F3D0),
          InstColors.success,
        );
      case AcademicStatusType.reprovado:
      case AcademicStatusType.indeferido:
      case AcademicStatusType.inativo:
      case AcademicStatusType.atrasado:
        return (
          const Color(0xFFFEF2F2),
          InstColors.danger,
          const Color(0xFFFECACA),
          InstColors.danger,
        );
      case AcademicStatusType.recuperacao:
      case AcademicStatusType.pendente:
      case AcademicStatusType.emAnalise:
      case AcademicStatusType.trancado:
        return (
          const Color(0xFFFFFBEB),
          InstColors.warning,
          const Color(0xFFFDE68A),
          InstColors.warning,
        );
      case AcademicStatusType.aberto:
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFF2563EB),
          const Color(0xFFBFDBFE),
          const Color(0xFF2563EB),
        );
      case AcademicStatusType.fechado:
      case AcademicStatusType.custom:
        return (
          const Color(0xFFF4F4F5),
          const Color(0xFF3F3F46),
          const Color(0xFFE4E4E7),
          InstColors.ink,
        );
    }
  }
}
