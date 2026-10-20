// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/shell/presentation/widgets/student_sidebar.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _faint = Color(0xFFA3A3A3);
const _border = Color(0xFFE5E5E5);
const _stone = Color(0xFFFAF9F6);
const _track = Color(0xFFEFEDE8);

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
    _Disc('218131 - APS-II', 'Análise e Projeto de Sistemas II',
        'Profa. Dra. Helena Bittencourt', 0.68),
    _Disc('218131 - BD-II', 'Estudos de Banco de Dados II',
        'Profa. Dra. Helena Bittencourt', 0.75),
    _Disc('218131 - FIS', 'Filosofia, Informação e Sociedade',
        'Prof. Dr. Marcos Vinícius Ferreira', 0.82),
    _Disc('218131 - FSO', 'Fundamentos de Sistemas Operacionais',
        'Prof. Esp. André Luiz Silveira', 0.54),
  ];

  static const _deadlines = [
    _Deadline('Entrega: Diagrama de Classes e Sequência',
        'Análise e Projeto de Sistemas II', 'Hoje, 20/09 às 23:59'),
    _Deadline('Fórum Temático: Ética na Inteligência Artificial',
        'Filosofia, Informação e Sociedade', 'Amanhã, 21/09 às 18:00'),
    _Deadline('Atividade Prática: Modelagem Relacional e Normalização',
        'Estudos de Banco de Dados II', 'Quinta, 24/09 às 23:59'),
    _Deadline('Avaliação Parcial: Gerenciamento de Memória',
        'Fundamentos de Sistemas Operacionais', 'Terça, 29/09 às 20:40'),
  ];

  static const _notices = [
    _Notice(
      'Prof. Carlos Eduardo (APS-II)',
      'Hoje, 14:10',
      'Feedback da Sprint 1 e Orientações para o Diagrama UML',
      'Prezados alunos, os apontamentos da primeira etapa do projeto de sistemas já constam no ambiente de entrega.',
      true,
    ),
    _Notice(
      'Profª. Eliane Ramos (BD-II)',
      'Ontem, 17:45',
      'Material de Apoio: Normalização em 3FN e BCNF',
      'Disponibilizei os slides com os exercícios resolvidos em aula sobre dependências funcionais e índices.',
      true,
    ),
    _Notice(
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
          _hero(),
          const SizedBox(height: 32),
          _kpis(isDesktop),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _leftColumn()),
                const SizedBox(width: 24),
                SizedBox(width: 280, child: _rightColumn()),
              ],
            )
          else ...[
            _leftColumn(),
            const SizedBox(height: 24),
            _rightColumn(),
          ],
        ],
      ),
    );
  }

  // ---------------- HERO ----------------
  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bem-vindo, Gabriel.',
            style: jakarta(
                size: 36, weight: FontWeight.w500, letterSpacing: -1)),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Engenharia de Software',
                style: jakarta(size: 12, weight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: Color(0xFFD4D4D4), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text('5º Semestre',
                style: jakarta(
                    size: 12, weight: FontWeight.w500, color: _faint)),
          ],
        ),
      ],
    );
  }

  // ---------------- KPIs ----------------
  Widget _kpis(bool isDesktop) {
    final cards = [
      _kpi('DISCIPLINAS', '04', 'Ativas no Semestre', 'Frequência Média',
          '94.8%', 0.948),
      _kpi('ENTREGAS DO MÊS', '04', 'Cadastradas', 'Próximo Vencimento',
          'Hoje, 23:59', 0.55),
      _kpi('COEFICIENTE DE RENDIMENTO (CR)', '8.8', '/10.0',
          'Situação Acadêmica', 'Regular', 0.88),
      _kpi('HORAS COMPLEMENTARES', '140h', '/180h', 'Progresso Total',
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

  Widget _kpi(String label, String value, String unit, String footLabel,
      String footValue, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                  size: 9.5, weight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: jakarta(size: 24, weight: FontWeight.w500)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(unit,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(size: 10.5, color: _faint)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(footLabel, style: jakarta(size: 11, color: _muted)),
              Text(footValue,
                  style: jakarta(size: 11, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          _bar(progress, fill: _ink, track: _border, height: 3),
        ],
      ),
    );
  }

  // ---------------- COLUNA ESQUERDA ----------------
  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Aula do Dia',
                style: jakarta(size: 18, weight: FontWeight.w500)),
            Text('HOJE, 20 SET',
                style: jakarta(
                    size: 9.5,
                    weight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 560) {
            return Column(children: [
              _liveCard(),
              const SizedBox(height: 12),
              SizedBox(height: 150, child: _freeCard()),
            ]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _liveCard()),
                const SizedBox(width: 12),
                Expanded(child: _freeCard()),
              ],
            ),
          );
        }),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Minhas Disciplinas',
                style: jakarta(size: 18, weight: FontWeight.w500)),
            InkWell(
              key: const Key('btn_ver_grade'),
              onTap: () => _controller.setNavItem(StudentNavItem.disciplinas),
              child: Row(
                children: [
                  Text('Ver grade',
                      style: jakarta(size: 13, weight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: _ink),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _controller.isGridView ? _disciplinesGrid() : _disciplinesList(),
      ],
    );
  }

  Widget _liveCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: const Color(0xFF16A34A)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F0),
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '19:00 - 20:40',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontFamilyFallback: ['Consolas', 'monospace'],
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text('AO VIVO AGORA',
                                style: jakarta(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Análise e Projeto de Sistemas II',
                      style: jakarta(size: 14.5, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('Profa. Dra. Helena Bittencourt',
                      style: jakarta(size: 10, color: _muted)),
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined,
                          size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Sala Virtual AVA • Teams Link',
                            style: jakarta(size: 9.5)),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _ink,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/video-call'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Entrar na\nVideochamada',
                                    style: jakarta(
                                        size: 9,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.2)),
                                const SizedBox(width: 14),
                                const Icon(Icons.arrow_forward,
                                    size: 11, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _freeCard() {
    return Container(
      decoration: BoxDecoration(
        color: _stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: _faint),
            const SizedBox(height: 10),
            Text('Horário Livre',
                style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF525252))),
            const SizedBox(height: 4),
            Text('Reservado para estudos e atividades práticas',
                textAlign: TextAlign.center,
                style: jakarta(size: 9.5, color: _muted)),
          ],
        ),
      ),
    );
  }

  Widget _disciplinesGrid() {
    return LayoutBuilder(builder: (context, c) {
      final single = c.maxWidth < 560;
      final w = single ? c.maxWidth : (c.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final d in _disciplines)
            SizedBox(width: w, child: _disciplineCard(d)),
        ],
      );
    });
  }

  Widget _disciplineCard(_Disc d) {
    return Container(
      height: 144,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeChip(d.code),
          const SizedBox(height: 14),
          Text(d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(d.professor, style: jakarta(size: 10, color: _muted)),
          const Spacer(),
          _progressRow(d.progress),
        ],
      ),
    );
  }

  Widget _disciplinesList() {
    return Column(
      children: [
        for (final d in _disciplines)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                _codeChip(d.code),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(size: 13, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(d.professor,
                          style: jakarta(size: 10, color: _muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 160, child: _progressRow(d.progress)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _codeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F0),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(code, style: jakarta(size: 10.5, weight: FontWeight.w500)),
    );
  }

  Widget _progressRow(double p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progresso',
                style: jakarta(
                    size: 10, weight: FontWeight.w600, color: _muted)),
            Text('${(p * 100).round()}%',
                style: jakarta(size: 10.5, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        _bar(p, fill: const Color(0xFFC8C6C0), track: _track, height: 3),
      ],
    );
  }

  // ---------------- COLUNA DIREITA ----------------
  Widget _rightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _deadlinesCard(),
        const SizedBox(height: 20),
        _noticesCard(),
      ],
    );
  }

  Widget _deadlinesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prazos Pendentes',
                  style: jakarta(size: 15, weight: FontWeight.w500)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F0),
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text('${_deadlines.length}',
                    style: jakarta(size: 10, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
          const SizedBox(height: 16),
          for (final d in _deadlines)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 2, color: _ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                  size: 11.5, weight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(d.discipline,
                              style: jakarta(size: 9.5, color: _muted)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 10, color: _faint),
                              const SizedBox(width: 4),
                              Text(d.due,
                                  style: jakarta(size: 9.5, color: _muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 2),
          Material(
            color: _stone,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: _border),
            ),
            child: InkWell(
              key: const Key('btn_abrir_calendario'),
              borderRadius: BorderRadius.circular(4),
              onTap: () => _controller.setNavItem(StudentNavItem.calendario),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Text('Abrir Calendário',
                      style: jakarta(size: 11, weight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mural de Avisos',
                  style: jakarta(size: 15, weight: FontWeight.w500)),
              Text('NÃO LIDOS',
                  style: jakarta(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
          const SizedBox(height: 16),
          for (int i = 0; i < _notices.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _noticeItem(_notices[i]),
          ],
        ],
      ),
    );
  }

  Widget _noticeItem(_Notice n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(n.author,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(size: 9.5, weight: FontWeight.w600)),
            ),
            if (n.unread) ...[
              const SizedBox(width: 6),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: _ink, shape: BoxShape.circle),
              ),
            ],
            const Spacer(),
            Text(n.time, style: jakarta(size: 9, color: _faint)),
          ],
        ),
        const SizedBox(height: 6),
        Text(n.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: jakarta(size: 12, weight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 5),
        Text(n.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: jakarta(size: 10, color: _muted, height: 1.4)),
      ],
    );
  }

  // ---------------- HELPERS ----------------
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      );

  Widget _bar(double value,
      {required Color fill, required Color track, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }
}

class _Disc {
  final String code;
  final String name;
  final String professor;
  final double progress;
  const _Disc(this.code, this.name, this.professor, this.progress);
}

class _Deadline {
  final String title;
  final String discipline;
  final String due;
  const _Deadline(this.title, this.discipline, this.due);
}

class _Notice {
  final String author;
  final String time;
  final String title;
  final String body;
  final bool unread;
  const _Notice(this.author, this.time, this.title, this.body, this.unread);
}
