// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card universal de KPI / Métrica Acadêmica compartilhado entre Aluno, Professor e Admin.
class InstitutionalKpiCard extends StatelessWidget {
  /// Título em caixa alta (ex: 'CRÉDITOS NO SEMESTRE', 'TURMAS ATIVAS', 'DISCENTES ATIVOS').
  final String title;

  /// Valor principal em destaque (ex: '24', '03', '1.240').
  final String value;

  /// Subtítulo ao lado do valor principal (ex: '/ 160 totais', 'no Semestre', 'Matriculados').
  final String subtitle;

  /// Rótulo do rodapé (ex: 'Progresso do Curso', 'Discentes Matriculados', 'Índice de Retenção').
  final String footerLabel;

  /// Valor do rodapé (ex: '15.0%', '101 alunos', '96.4%').
  final String footerValue;

  /// Progresso opcional entre 0.0 e 1.0. Se fornecido, exibe barra de progresso de 6px;
  /// caso contrário, exibe divisor sutil de 1px.
  final double? progress;

  /// Se `true`, empilha o rodapé verticalmente (estilo Admin); se `false`, alinha lado a lado.
  final bool stackFooter;

  const InstitutionalKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.footerLabel,
    required this.footerValue,
    this.progress,
    this.stackFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w700,
              color: const Color(0xFF000000),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: jakarta(
                  size: 30,
                  weight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w500,
                    color: const Color(0xFFA3A3A3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (stackFooter)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  footerLabel,
                  style: jakarta(size: 13, color: const Color(0xFF737373)),
                ),
                const SizedBox(height: 2),
                Text(
                  footerValue,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    footerLabel,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(
                      size: 13.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF737373),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  footerValue,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: const Color(0xFFF2F0EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
              ),
            )
          else
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
        ],
      ),
    );
  }
}

