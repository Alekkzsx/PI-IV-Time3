// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'guidelines_metric_card.dart';
import 'guidelines_formula_card.dart';

/// Configuration tab for Institutional Academic Guidelines.
///
/// Allows central administration to configure cut-off grades, minimum attendance thresholds,
/// and the official institutional grade-weighting formula (CONSU Resolution).
class AcademicGuidelinesTab extends StatefulWidget {
  const AcademicGuidelinesTab({super.key});

  @override
  State<AcademicGuidelinesTab> createState() => _AcademicGuidelinesTabState();
}

class _AcademicGuidelinesTabState extends State<AcademicGuidelinesTab> {
  final _approvalController = TextEditingController(text: '6');
  final _attendanceController = TextEditingController(text: '75');
  final _specialExamController = TextEditingController(text: '4');
  final _formulaController = TextEditingController(
    text: 'Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)',
  );

  @override
  void dispose() {
    _approvalController.dispose();
    _attendanceController.dispose();
    _specialExamController.dispose();
    _formulaController.dispose();
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
          // 1. Tab Header
          _buildHeader(),
          const SizedBox(height: 24),

          // 2. Institutional Hierarchy and Faculty Autonomy Banner
          _buildBanner(),
          const SizedBox(height: 24),

          // 3. Metric Cards Grid (Approval, Attendance, Special Exam)
          _buildMetricsGrid(),
          const SizedBox(height: 24),

          // 4. Regimental Weighting Formula Description & Deliberation
          GuidelinesFormulaCard(formulaController: _formulaController),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFF2563EB), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hierarquia Institucional e Autonomia Docente:\n'
              'Os professores possuem plena liberdade pedagógica para criar tarefas, definir seus pesos (peso 1, peso 2, etc.), '
              'destinar atividades a turmas inteiras ou discentes específicos e lançar frequências. No entanto, as metas de corte '
              'para aprovação, exames e frequência mínima são regimentadas exclusivamente pela administração aqui configurada.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;
        final approvalCard = GuidelinesMetricCard(
          icon: Icons.calculate_outlined,
          iconColor: const Color(0xFF2563EB),
          title: 'MÉDIA DE APROVAÇÃO',
          badgeText: 'Aprovação Direta',
          badgeBg: const Color(0xFFEFF6FF),
          badgeBorder: const Color(0xFFBFDBFE),
          badgeTextColor: const Color(0xFF2563EB),
          subtitle:
              'Nota de Corte Mínima (0 a 10)\nMédia semestral exigida para aprovação sem necessidade de exame.',
          controller: _approvalController,
          footerText: 'Padrão regimental vigente: 6.0',
        );

        final attendanceCard = GuidelinesMetricCard(
          icon: Icons.percent_rounded,
          iconColor: const Color(0xFF059669),
          title: 'FREQUÊNCIA PRESENCIAL',
          badgeText: 'LDB 9.394/96',
          badgeBg: const Color(0xFFECFDF5),
          badgeBorder: const Color(0xFFA7F3D0),
          badgeTextColor: const Color(0xFF059669),
          subtitle:
              'Presença Mínima Obrigatória (%)\nAbaixo deste índice o aluno é reprovado por infrequência (RF).',
          controller: _attendanceController,
          suffixText: '%',
          footerText: 'Padrão regimental institucional: 75%',
        );

        final examCard = GuidelinesMetricCard(
          icon: Icons.description_outlined,
          iconColor: const Color(0xFFD97706),
          title: 'EXAME ESPECIAL',
          badgeText: 'Recuperação',
          badgeBg: const Color(0xFFFFFBEB),
          badgeBorder: const Color(0xFFFDE68A),
          badgeTextColor: const Color(0xFFD97706),
          subtitle:
              'Corte para Prova Final (0 a 10)\nNota mínima para discentes que não atingiram a média direta.',
          controller: _specialExamController,
          footerText: 'Abaixo de 4.0: Reprovado direto',
        );

        if (isNarrow) {
          return Column(
            children: [
              approvalCard,
              const SizedBox(height: 16),
              attendanceCard,
              const SizedBox(height: 16),
              examCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: approvalCard),
            const SizedBox(width: 16),
            Expanded(child: attendanceCard),
            const SizedBox(width: 16),
            Expanded(child: examCard),
          ],
        );
      },
    );
  }
}
