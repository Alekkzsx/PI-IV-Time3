// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card consolidado de métricas institucionais do estudante (Carga Horária, Média, Frequência e Situação).
class StudentDisciplinesStatsCard extends StatelessWidget {
  const StudentDisciplinesStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 900;
          if (isSmall) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCargaHoraria()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMediaPonderada()),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFrequencia()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSituacao()),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCargaHoraria()),
              _buildDivider(),
              Expanded(child: _buildMediaPonderada()),
              _buildDivider(),
              Expanded(child: _buildFrequencia()),
              _buildDivider(),
              Expanded(child: _buildSituacao()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildCargaHoraria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARGA HORÁRIA TOTAL',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '190h',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'de 280h (68%)',
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 11.5,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const LinearProgressIndicator(
            value: 0.68,
            minHeight: 3.5,
            backgroundColor: Color(0xFFF4F4F5),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPonderada() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÉDIA PONDERADA PARCIAL',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '8.63',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Aprovado em todas',
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w600,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Mínimo regimental: 6.0',
          style: jakarta(
            size: 11,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUÊNCIA GLOBAL CONSOLIDADA',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '95.7%',
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '(12 faltas)',
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 11.5,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Excelente assiduidade presencial',
          style: jakarta(
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildSituacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SITUAÇÃO CURRICULAR 2026/2',
          style: jakarta(
            size: 10.5,
            weight: FontWeight.w700,
            color: const Color(0xFF71717A),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Color(0xFF16A34A),
            ),
            const SizedBox(width: 6),
            Text(
              'Regular & Apto',
              style: jakarta(
                size: 15,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '4 disciplinas em andamento',
          style: jakarta(
            size: 11,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
  }
}
