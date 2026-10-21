// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import '../widgets/student_deadlines_panel.dart';
import '../widgets/student_disciplines_grid_section.dart';
import '../widgets/student_live_class_section.dart';
import '../widgets/student_notices_panel.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _faint = Color(0xFFA3A3A3);
const _border = Color(0xFFE5E5E5);

/// Painel Geral (Dashboard) da Visão do Aluno.
///
/// Saudação, 4 indicadores, aula do dia, disciplinas (grade/lista),
/// prazos pendentes e mural de avisos.
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  static const _disciplines = [
    StudentDisciplineItemData('218131 - APS-II', 'Análise e Projeto de Sistemas II',
        'Profa. Dra. Helena Bittencourt', 0.68),
    StudentDisciplineItemData('218131 - BD-II', 'Estudos de Banco de Dados II',
        'Profa. Dra. Helena Bittencourt', 0.75),
    StudentDisciplineItemData('218131 - FIS', 'Filosofia, Informação e Sociedade',
        'Prof. Dr. Marcos Vinícius Ferreira', 0.82),
    StudentDisciplineItemData('218131 - FSO', 'Fundamentos de Sistemas Operacionais',
        'Prof. Esp. André Luiz Silveira', 0.54),
  ];

  static const _deadlines = [
    StudentDeadlineItemData('Entrega: Diagrama de Classes e Sequência',
        'Análise e Projeto de Sistemas II', 'Hoje, 20/09 às 23:59'),
    StudentDeadlineItemData('Fórum Temático: Ética na Inteligência Artificial',
        'Filosofia, Informação e Sociedade', 'Amanhã, 21/09 às 18:00'),
    StudentDeadlineItemData('Atividade Prática: Modelagem Relacional e Normalização',
        'Estudos de Banco de Dados II', 'Quinta, 24/09 às 23:59'),
    StudentDeadlineItemData('Avaliação Parcial: Gerenciamento de Memória',
        'Fundamentos de Sistemas Operacionais', 'Terça, 29/09 às 20:40'),
  ];

  static const _notices = [
    StudentNoticeItemData(
      'Prof. Carlos Eduardo (APS-II)',
      'Hoje, 14:10',
      'Feedback da Sprint 1 e Orientações para o Diagrama UML',
      'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
      true,
    ),
    StudentNoticeItemData(
      'Profª. Eliane Ramos (BD-II)',
      'Ontem, 17:45',
      'Material de Apoio: Normalização em 3FN e BCNF',
      'Disponibilizei os slides com os exercícios resolvidos em aula sobre dependências funcionais e índices.',
      true,
    ),
    StudentNoticeItemData(
      'Secretaria Acadêmica AGMRM',
      '18 de set',
      'Prazo para Validação de Atividades Complementares 2026/2',
      'Lembramos a todos os estudantes que o envio de certificados de cursos e palestras para cômputo de horas complementares encerra em breve.',
      false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 32),
          _buildKpis(isDesktop),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftColumn()),
                const SizedBox(width: 24),
                SizedBox(width: 280, child: _buildRightColumn()),
              ],
            )
          else ...[
            _buildLeftColumn(),
            const SizedBox(height: 24),
            _buildRightColumn(),
          ],
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo, Gabriel.',
          style: jakarta(size: 44, weight: FontWeight.w600, letterSpacing: -1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Engenharia de Software',
                style: jakarta(size: 16, weight: FontWeight.w700, color: Colors.black)),
            const SizedBox(width: 10),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: Color(0xFFD4D4D4), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text('5º Semestre',
                style: jakarta(
                    size: 16, weight: FontWeight.w600, color: _muted)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpis(bool isDesktop) {
    final cards = [
      _buildKpiCard('Disciplinas', '04', 'Ativas no Semestre', 'Frequência Média',
          '94.8%', 0.948),
      _buildKpiCard('Entregas do Mês', '04', 'Cadastradas', 'Próximo Vencimento',
          'Hoje, 23:59', 0.50),
      _buildKpiCard('Coeficiente de Rendimento (CR)', '8.8', '/ 10.0',
          'Situação Acadêmica', 'Regular', 0.88),
      _buildKpiCard('Horas Complementares', '140h', '/ 180h', 'Progresso Total',
          '77.7%', 0.777),
    ];
    if (!isDesktop) {
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ]);
    }
    return Row(children: [
      for (int i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 16),
        Expanded(child: cards[i]),
      ],
    ]);
  }

  Widget _buildKpiCard(String label, String value, String unit, String footLabel,
      String footValue, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                  size: 11, weight: FontWeight.w700, letterSpacing: 0.8, color: Colors.black)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: jakarta(size: 28, weight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              const SizedBox(width: 8),
              Flexible(
                child: Text(unit,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(size: 13, color: const Color(0xFFA3A3A3), weight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(footLabel, style: jakarta(size: 13, color: const Color(0xFF737373), weight: FontWeight.w500)),
              Text(footValue,
                  style: jakarta(size: 13, weight: FontWeight.w600, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFF2F0EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StudentLiveClassSection(),
        const SizedBox(height: 36),
        StudentDisciplinesGridSection(
          controller: _controller,
          disciplines: _disciplines,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentDeadlinesPanel(
          controller: _controller,
          deadlines: _deadlines,
        ),
        const SizedBox(height: 20),
        const StudentNoticesPanel(notices: _notices),
      ],
    );
  }
}
