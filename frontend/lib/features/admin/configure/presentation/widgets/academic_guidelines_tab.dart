// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de configuração das Diretrizes Acadêmicas Regimentais.
///
/// Permite à administração central definir notas de corte, frequência mínima
/// e fórmula oficial de ponderação institucional (Resolução CONSU).
class AcademicGuidelinesTab extends StatefulWidget {
  const AcademicGuidelinesTab({super.key});

  @override
  State<AcademicGuidelinesTab> createState() => _AcademicGuidelinesTabState();
}

class _AcademicGuidelinesTabState extends State<AcademicGuidelinesTab> {
  final TextEditing4ApprovalController = TextEditingController(text: '6');
  final TextEditingAttendanceController = TextEditingController(text: '75');
  final TextEditingSpecialExamController = TextEditingController(text: '4');
  final TextEditingFormulaController = TextEditingController(
    text: 'Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)',
  );

  @override
  void dispose() {
    TextEditing4ApprovalController.dispose();
    TextEditingAttendanceController.dispose();
    TextEditingSpecialExamController.dispose();
    TextEditingFormulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho da Aba
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Diretrizes Acadêmicas Regimentais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Definição institucional centralizada das metas de frequência, notas de corte e regras de aprovação.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF059669),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Governança Central Ativa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Banner de Hierarquia Institucional e Autonomia Docente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A), height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Hierarquia Institucional e Autonomia Docente:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Os professores possuem plena liberdade pedagógica para criar tarefas, definir seus pesos (peso 1, peso 2, etc.), destinar atividades a turmas inteiras ou discentes específicos e lançar frequências. No entanto, as metas de corte para aprovação, exames e frequência mínima são regimentadas exclusivamente pela administração aqui configurada.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Grid de 3 Cards de Métricas
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 850;
              return isNarrow
                  ? Column(
                      children: [
                        _buildMetricCard(
                          icon: Icons.calculate_outlined,
                          iconColor: const Color(0xFF2563EB),
                          title: 'MÉDIA DE APROVAÇÃO',
                          badgeText: 'Aprovação Direta',
                          badgeBg: const Color(0xFFEFF6FF),
                          badgeBorder: const Color(0xFFBFDBFE),
                          badgeTextColor: const Color(0xFF2563EB),
                          subtitle:
                              'Nota de Corte Mínima (0 a 10)\nMédia semestral exigida para aprovação sem necessidade de exame.',
                          controller: TextEditing4ApprovalController,
                          footerText: 'Padrão regimental vigente: 6.0',
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          icon: Icons.percent_rounded,
                          iconColor: const Color(0xFF059669),
                          title: 'FREQUÊNCIA PRESENCIAL',
                          badgeText: 'LDB 9.394/96',
                          badgeBg: const Color(0xFFECFDF5),
                          badgeBorder: const Color(0xFFA7F3D0),
                          badgeTextColor: const Color(0xFF059669),
                          subtitle:
                              'Presença Mínima Obrigatória (%)\nAbaixo deste índice o aluno é reprovado por infrequência (RF).',
                          controller: TextEditingAttendanceController,
                          suffixText: '%',
                          footerText: 'Padrão regimental institucional: 75%',
                        ),
                        const SizedBox(height: 16),
                        _buildMetricCard(
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFFD97706),
                          title: 'EXAME ESPECIAL',
                          badgeText: 'Recuperação',
                          badgeBg: const Color(0xFFFFFBEB),
                          badgeBorder: const Color(0xFFFDE68A),
                          badgeTextColor: const Color(0xFFD97706),
                          subtitle:
                              'Corte para Prova Final (0 a 10)\nNota mínima para discentes que não atingiram a média direta.',
                          controller: TextEditingSpecialExamController,
                          footerText: 'Abaixo de 4.0: Reprovado direto',
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.calculate_outlined,
                            iconColor: const Color(0xFF2563EB),
                            title: 'MÉDIA DE APROVAÇÃO',
                            badgeText: 'Aprovação Direta',
                            badgeBg: const Color(0xFFEFF6FF),
                            badgeBorder: const Color(0xFFBFDBFE),
                            badgeTextColor: const Color(0xFF2563EB),
                            subtitle:
                                'Nota de Corte Mínima (0 a 10)\nMédia semestral exigida para aprovação sem necessidade de exame.',
                            controller: TextEditing4ApprovalController,
                            footerText: 'Padrão regimental vigente: 6.0',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.percent_rounded,
                            iconColor: const Color(0xFF059669),
                            title: 'FREQUÊNCIA PRESENCIAL',
                            badgeText: 'LDB 9.394/96',
                            badgeBg: const Color(0xFFECFDF5),
                            badgeBorder: const Color(0xFFA7F3D0),
                            badgeTextColor: const Color(0xFF059669),
                            subtitle:
                                'Presença Mínima Obrigatória (%)\nAbaixo deste índice o aluno é reprovado por infrequência (RF).',
                            controller: TextEditingAttendanceController,
                            suffixText: '%',
                            footerText: 'Padrão regimental institucional: 75%',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFFD97706),
                            title: 'EXAME ESPECIAL',
                            badgeText: 'Recuperação',
                            badgeBg: const Color(0xFFFFFBEB),
                            badgeBorder: const Color(0xFFFDE68A),
                            badgeTextColor: const Color(0xFFD97706),
                            subtitle:
                                'Corte para Prova Final (0 a 10)\nNota mínima para discentes que não atingiram a média direta.',
                            controller: TextEditingSpecialExamController,
                            footerText: 'Abaixo de 4.0: Reprovado direto',
                          ),
                        ),
                      ],
                    );
            },
          ),

          const SizedBox(height: 24),

          // 4. Descrição da Fórmula Regimental e Ponderação
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Descrição da Fórmula Regimental e Ponderação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Texto explicativo exibido para os professores no diário de notas e para os alunos na consulta de rendimento.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: TextEditingFormulaController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Resolução e Homologação
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Resolução / Órgão Deliberador',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Administração Central & Resolução CONSU nº 14/2023',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Última Homologação Registrada',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '15 de Agosto de 2026',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeTextColor,
    required String subtitle,
    required TextEditingController controller,
    String? suffixText,
    required String footerText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (suffixText != null) ...[
                  Text(
                    suffixText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        final val = double.tryParse(controller.text) ?? 0;
                        controller.text = (val + 1).toInt().toString();
                      },
                      child: const Icon(Icons.keyboard_arrow_up, size: 16, color: Color(0xFF64748B)),
                    ),
                    InkWell(
                      onTap: () {
                        final val = double.tryParse(controller.text) ?? 0;
                        if (val > 0) controller.text = (val - 1).toInt().toString();
                      },
                      child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            footerText,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
