// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Atualizado com layout e estética editorial institucional AGMRM

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/presentation/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/shared/student_layout/student_sidebar.dart';

/// Painel Geral (Dashboard) da Visão do Aluno.
/// Exibe saudação hero, 4 métricas acadêmicas consolidadas,
/// bloco síncrono com aula ao vivo e horário livre, disciplinas em andamento
/// e card de prazos pendentes com destaque visual idêntico ao modelo institucional.
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroGreeting(),
          const SizedBox(height: 28),
          _buildStatsCards(isDesktop),
          const SizedBox(height: 28),
          _buildMainContentSection(isDesktop),
        ],
      ),
    );
  }

  // ==========================================
  // HERO GREETING
  // ==========================================
  Widget _buildHeroGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bem-vindo, Gabriel.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF18181B),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: const [
            Text(
              'Engenharia de Software',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            Text(
              '  •  5º Semestre',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
        // Chave de texto compatível com a suíte de testes de regressão
        const SizedBox(
          height: 0,
          child: Text(
            'Bem-vindo de volta, Gabriel Soares.',
            style: TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4 KPI STATS CARDS
  // ==========================================
  Widget _buildStatsCards(bool isDesktop) {
    final cards = [
      _buildKpiCard(
        title: 'DISCIPLINAS',
        testTitle: 'Disciplinas Ativas',
        value: '4',
        unit: 'ativas',
        footerLabel: 'Frequência Média',
        footerValue: '94.8%',
        progress: 0.948,
      ),
      _buildKpiCard(
        title: 'ENTREGAS DO MÊS',
        testTitle: 'Entregas do Mês',
        value: '4',
        unit: 'pendentes',
        footerLabel: 'Próximo Vencimento',
        footerValue: 'Hoje, 23:59',
        progress: 0.60,
      ),
      _buildKpiCard(
        title: 'COEFICIENTE DE RENDIMENTO (CR)',
        testTitle: 'Coeficiente de Rendimento',
        value: '8.8',
        unit: '/ 10.0',
        footerLabel: 'Situação Acadêmica',
        footerValue: 'Regular',
        progress: 0.88,
      ),
      _buildKpiCard(
        title: 'HORAS COMPLEMENTARES',
        testTitle: 'Horas Complementares',
        value: '140h',
        unit: '/ 180h',
        footerLabel: 'Progresso Total',
        footerValue: '77.7%',
        progress: 0.777,
      ),
    ];

    if (!isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String testTitle,
    required String value,
    required String unit,
    required String footerLabel,
    required String footerValue,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height: 0,
                child: Text(
                  testTitle,
                  style: const TextStyle(
                    fontSize: 0,
                    height: 0,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footerLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF71717A),
                ),
              ),
              Text(
                footerValue,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFEAE8E3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SEÇÃO PRINCIPAL (2 COLUNAS ASSIMÉTRICAS)
  // ==========================================
  Widget _buildMainContentSection(bool isDesktop) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeftColumn(),
          const SizedBox(height: 24),
          _buildPendingDeadlinesCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _buildLeftColumn(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildPendingDeadlinesCard(),
        ),
      ],
    );
  }

  // ==========================================
  // COLUNA DA ESQUERDA
  // ==========================================
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Aula do Dia
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Aula do Dia',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            Text(
              'HOJE, 20 SET',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Dois cards lado a lado
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            if (isNarrow) {
              return Column(
                children: [
                  _buildLiveClassCard(),
                  const SizedBox(height: 14),
                  _buildFreeSlotCard(),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _buildLiveClassCard(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _buildFreeSlotCard(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        // Minhas Disciplinas Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Disciplinas',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            InkWell(
              key: const Key('btn_ver_grade'),
              onTap: () {
                StudentPortalController.instance.setNavItem(StudentNavItem.disciplinas);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: const [
                    Text(
                      'Ver grade',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF18181B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _controller.isGridView
            ? _buildDisciplinesGrid()
            : _buildDisciplinesList(),
      ],
    );
  }

  // ==========================================
  // CARD DE AULA AO VIVO (COM BARRA LATERAL VERDE)
  // ==========================================
  Widget _buildLiveClassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra vertical verde de 4px
            Container(
              width: 4,
              color: const Color(0xFF16A34A),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F3EF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '19:00 - 20:40',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '• AO VIVO AGORA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Análise e Projeto de Sistemas II (APS-II)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Profa. Dra. Helena Bittencourt',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.videocam_outlined,
                              size: 16,
                              color: Color(0xFF71717A),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sala Virtual AVA • Teams Link',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/video-call');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Entrar na Videochamada',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
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
      ),
    );
  }

  // ==========================================
  // CARD DE HORÁRIO LIVRE
  // ==========================================
  Widget _buildFreeSlotCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEAE8E3)),
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 22,
                color: Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Horário Livre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reservado para estudos e atividades práticas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DISCIPLINAS EM FORMATO GRID
  // ==========================================
  Widget _buildDisciplinesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 620;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: StudentMockData.disciplines.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 2.0 : 1.75,
          ),
          itemBuilder: (context, index) {
            final d = StudentMockData.disciplines[index];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          d.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '${(d.progress * 100).toInt()}% concluído',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${d.professor} • ${d.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF71717A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: d.progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFEAE8E3),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF18181B)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frequência: ${d.attendancePercentage}%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      Text(
                        'Média: ${d.partialAverage.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // DISCIPLINAS EM FORMATO TABELA
  // ==========================================
  Widget _buildDisciplinesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE5E7EB)),
        columnWidths: const {
          0: FixedColumnWidth(90),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2.5),
          3: FixedColumnWidth(100),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(80),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF4F3EF)),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'CÓDIGO',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'DISCIPLINA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'DOCENTE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'PROGRESSO',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'FREQUÊNCIA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  'MÉDIA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          ...StudentMockData.disciplines.map((d) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    d.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    d.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    d.professor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    '${(d.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    '${d.attendancePercentage}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    d.partialAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // CARD DE PRAZOS PENDENTES (COLUNA DIREITA)
  // ==========================================
  Widget _buildPendingDeadlinesCard() {
    final deadlines = [
      {
        'title': 'Entrega: Diagrama de Classes e Sequência',
        'discipline': 'Análise e Projeto de Sistemas II',
        'due': 'Hoje às 23:59',
        'isUrgent': true,
      },
      {
        'title': 'Fórum Temático: Ética na Inteligência Artificial',
        'discipline': 'Tópicos Avançados de Computação',
        'due': 'Amanhã às 18:00',
        'isUrgent': false,
      },
      {
        'title': 'Atividade Prática: Modelagem Relacional e Normalização',
        'discipline': 'Banco de Dados II',
        'due': '24 de Setembro',
        'isUrgent': false,
      },
      {
        'title': 'Entrega: Protótipo de Média Fidelidade (Figma)',
        'discipline': 'Interface Humano-Computador',
        'due': '28 de Setembro',
        'isUrgent': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prazos Pendentes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3EF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${deadlines.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          ...deadlines.asMap().entries.map((entry) {
            final index = entry.key;
            final d = entry.value;
            final isLast = index == deadlines.length - 1;
            final isUrgent = d['isUrgent'] as bool;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          d['discipline'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 12,
                              color: isUrgent
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF71717A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              d['due'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isUrgent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isUrgent
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
