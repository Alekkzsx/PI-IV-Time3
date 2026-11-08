// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../widgets/widgets.dart';

/// [DashboardPage]
///
/// Página inicial e painel de controle principal do Portal do Aluno.
/// Agrega indicadores-chave de desempenho acadêmico (CR, frequência, horas concluídas, tarefas pendentes),
/// banner da aula síncrona/presencial do dia, seletor de visualização (Grade ou Linha do Tempo),
/// grade curricular de disciplinas matriculadas e painéis de avisos institucionais e prazos imediatos.
class DashboardPage extends StatefulWidget {
  /// Controlador opcional injetável para testes instrumentados.
  final StudentPortalController? controller;

  /// Cria uma nova instância de [DashboardPage].
  const DashboardPage({super.key, this.controller});

  @override
  State<DashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<DashboardPage> {
  late final StudentPortalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? StudentPortalController.instance;
    _controller.addListener(_onUpdate);
    _controller.loadRemote();
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
    final dashboard = _controller.remoteDashboard;
    if (dashboard == null) {
      if (_controller.isLoadingRemote) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.remoteError ?? 'Nenhum dado acadêmico disponível.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _controller.loadRemote(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.isGridView) {
      return StudentDashboardListView(
        dashboard: dashboard,
        timeline: _controller.timeline,
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(dashboard),
          const SizedBox(height: 28),
          _buildKpis(dashboard, isDesktop),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftColumn(dashboard)),
                const SizedBox(width: 28),
                SizedBox(width: 380, child: _buildRightColumn(dashboard)),
              ],
            )
          else ...[
            _buildLeftColumn(dashboard),
            const SizedBox(height: 28),
            _buildRightColumn(dashboard),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(dynamic dashboard) {
    final info = dashboard.studentInfo;
    final name = (info['socialName'] as String?)?.trim().isNotEmpty == true
        ? info['socialName'] as String
        : info['name'] as String? ?? 'Estudante';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo, $name.',
          style: jakarta(
            size: 34,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              info['courseName'] as String? ?? 'Curso não informado',
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFD4D4D8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              info['semester'] as String? ?? 'Semestre não informado',
              style: jakarta(
                size: 13.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpis(dynamic dashboard, bool isDesktop) {
    final stats = dashboard.stats;
    final pending = dashboard.deliveries
        .where((delivery) => delivery.status == 'Pendente')
        .toList();
    final nextDue = pending.isEmpty
        ? 'Nenhuma pendente'
        : '${pending.first.dueDate} às ${pending.first.dueHour}';
    final completedHours = (stats['completedHoursSemester'] as num?)?.toInt() ?? 0;
    final totalHours = (stats['totalHoursSemester'] as num?)?.toInt() ?? 0;
    final hoursProgress = totalHours > 0 ? completedHours / totalHours : 0.0;
    final averageAttendance = (stats['averageAttendance'] as num?)?.toDouble() ?? 0;
    final cr = (stats['cr'] as num?)?.toDouble() ?? 0;
    final cards = [
      _buildKpiCard(
        'DISCIPLINAS',
        '${stats['activeDisciplines'] ?? 0}'.padLeft(2, '0'),
        'Ativas no Semestre',
        'Frequência Média',
        '${averageAttendance.toStringAsFixed(1)}%',
        averageAttendance / 100,
      ),
      _buildKpiCard(
        'ENTREGAS PENDENTES',
        '${pending.length}'.padLeft(2, '0'),
        'Cadastradas',
        'Próximo Vencimento',
        nextDue,
        pending.isEmpty ? 1 : 0.45,
      ),
      _buildKpiCard(
        'COEFICIENTE DE RENDIMENTO (CR)',
        cr.toStringAsFixed(1),
        '/10.0',
        'Situação Acadêmica',
        stats['academicStatus'] as String? ?? 'Regular',
        cr / 10,
      ),
      _buildKpiCard(
        'CARGA HORÁRIA DO SEMESTRE',
        '${completedHours}h',
        '/ ${totalHours > 0 ? totalHours : 180}h',
        'Progresso Total',
        '${(hoursProgress * 100).toStringAsFixed(1)}%',
        hoursProgress,
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
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _buildKpiCard(
    String label,
    String value,
    String unit,
    String footLabel,
    String footValue,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
              color: const Color(0xFF71717A),
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
                  size: 28,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  unit,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12,
                    color: const Color(0xFF71717A),
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footLabel,
                style: jakarta(
                  size: 12,
                  color: const Color(0xFF71717A),
                  weight: FontWeight.w400,
                ),
              ),
              Text(
                footValue,
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(dynamic dashboard) {
    final todayClass = dashboard.todayClass;
    final List<StudentDisciplineItemData> disciplines =
      dashboard.disciplines.map<StudentDisciplineItemData>(
          (discipline) => StudentDisciplineItemData(
            discipline.fullCode ?? discipline.code,
            discipline.name,
            discipline.professor,
            discipline.progress,
          ),
        ).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentLiveClassSection(
          roomCode: todayClass?['roomCode'] as String?,
          className: todayClass?['disciplineName'] as String?,
          time: todayClass?['time'] as String?,
          teacher: todayClass?['teacher'] as String?,
          isOpen: todayClass?['isLive'] == true,
          freeMessage: dashboard.freeSchedule?['message'] as String?,
        ),
        const SizedBox(height: 36),
        StudentDisciplinesGridSection(
          controller: _controller,
          disciplines: disciplines,
        ),
      ],
    );
  }

  Widget _buildRightColumn(dynamic dashboard) {
    final List<StudentDeadlineItemData> deadlines = dashboard.deliveries
      .where((delivery) => delivery.status == 'Pendente')
      .map<StudentDeadlineItemData>(
          (delivery) => StudentDeadlineItemData(
            delivery.title,
            delivery.disciplineName,
            '${delivery.dueDate} às ${delivery.dueHour}',
          ),
        )
        .toList();
      final List<StudentNoticeItemData> notices = dashboard.messages
        .map<StudentNoticeItemData>(
          (message) => StudentNoticeItemData(
            message['sender']?.toString() ?? 'Comunicado acadêmico',
            message['dateLabel']?.toString() ?? '',
            message['title']?.toString() ?? '',
            message['body']?.toString() ?? '',
            message['isNew'] == true,
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentDeadlinesPanel(
          controller: _controller,
          deadlines: deadlines,
        ),
        const SizedBox(height: 24),
        StudentNoticesPanel(notices: notices),
      ],
    );
  }
}


typedef StudentDashboardPage = DashboardPage;
