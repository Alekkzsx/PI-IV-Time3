// Desenvolvido por Guilherme Henrique Moreira

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';

/// Console Avançado de Supervisão Institucional da Turma na Visão Administrativa.
/// Permite auditar notas em tempo real, configurar regimes de avaliação, reatribuir
/// docentes e emitir o fechamento homologado da pauta acadêmica.
class SupervisionCockpitPage extends StatefulWidget {
  final AdminClassModel classModel;
  final VoidCallback onBack;

  const SupervisionCockpitPage({
    super.key,
    required this.classModel,
    required this.onBack,
  });

  @override
  State<SupervisionCockpitPage> createState() => _SupervisionCockpitPageState();
}

class _SupervisionCockpitPageState extends State<SupervisionCockpitPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  late final TextEditingController _justificationController;
  late final TextEditingController _profController;

  AdminClassModel get _activeClass =>
      _controller.classes
          .where((item) => item.code == widget.classModel.code)
          .firstOrNull ??
      widget.classModel;

  static String _initialProfessorInput(String professor) {
    final normalized = professor.trim();
    if (normalized.isEmpty ||
        normalized == 'Não alocado' ||
        normalized == 'Não atribuído') {
      return '';
    }
    return normalized;
  }

  static String _formulaChoiceFromExpression(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('equitativa') ||
        lower.contains('/ 2') ||
        lower.contains('0.5')) {
      return 'Equitativa (N1 50% / N2 50%)';
    }
    if (lower.contains('aritm') || lower.contains('contínu')) {
      return 'Aritmética Simples';
    }
    return 'Ponderada (N1 40% / N2 60%)';
  }

  static String _formulaExpressionFor(String selected) {
    switch (selected) {
      case 'Equitativa (N1 50% / N2 50%)':
        return '(N1 + N2) / 2';
      case 'Aritmética Simples':
        return 'Média aritmética de instrumentos contínuos';
      default:
        return '(N1 × 0.4) + (N2 × 0.6)';
    }
  }

  final List<String> _tabs = [
    'Diretriz & Regime Avaliativo',
    'Auditoria de Notas & Pauta',
    'Atribuição Docente',
    'Discentes & Vagas',
    'Fechamento de Pauta & Homologação',
  ];

  static const List<IconData> _tabIcons = [
    Icons.rule_rounded,
    Icons.fact_check_outlined,
    Icons.person_search_outlined,
    Icons.groups_2_outlined,
    Icons.lock_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final initialClass = _activeClass;
    _justificationController = TextEditingController();
    _profController = TextEditingController(
      text: _initialProfessorInput(initialClass.professor),
    );
    _controller.selectedEvaluationFormula = _formulaChoiceFromExpression(
      initialClass.evaluationFormula,
    );
    _controller.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadClassSupervision(widget.classModel.code);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.clearSupervisionError(notify: false);
    _justificationController.dispose();
    _profController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _exportGrades() async {
    final activeClass = _activeClass;
    final rows = [
      ['RA', 'Discente', 'N1', 'N2', 'Média', 'Faltas'],
      ..._controller.supervisedGrades.map(
        (grade) => [
          grade.ra,
          grade.studentName,
          grade.n1.toStringAsFixed(2),
          grade.n2.toStringAsFixed(2),
          grade.finalAverage.toStringAsFixed(2),
          grade.absences.toString(),
        ],
      ),
    ];
    final csv = rows
        .map((row) => row.map((field) => '"${field.replaceAll('"', '""')}"').join(';'))
        .join('\n');
    final saved = await PlatformFileHelper.saveOrDownloadFile(
      fileName: 'pauta-${activeClass.code}.csv',
      bytes: utf8.encode(csv),
      mimeType: 'text/csv',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved == null ? 'Não foi possível exportar a pauta.' : 'Pauta exportada: $saved',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClass = _activeClass;
    return Container(
      color: InstColors.stone,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: DefaultTextStyle(
              style: jakarta(size: 13, color: InstColors.ink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCockpitHeader(activeClass),
                  if (_controller.isLoadingSupervision) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_controller.supervisionError != null) ...[
                    const SizedBox(height: 12),
                    _buildSupervisionErrorBanner(activeClass),
                  ],
                  const SizedBox(height: 16),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildActiveTabContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisionErrorBanner(AdminClassModel activeClass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _controller.supervisionError!,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w500,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _controller.loadClassSupervision(activeClass.code),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DO CONSOLE DE SUPERVISÃO
  // ==========================================
  Widget _buildCockpitHeader(AdminClassModel activeClass) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _controller.clearSupervisionError();
                  widget.onBack();
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Voltar para Gestão de Turmas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: AcademicBridgeService.instance,
                    builder: (context, _) {
                      final isLive = AcademicBridgeService.instance
                          .isSessionOpen(activeClass.code);
                      return ElevatedButton.icon(
                        key: const Key('btn_admin_supervisionar_chamada'),
                        onPressed: _controller.canPerform('manage_video_calls')
                            ? () {
                                Navigator.of(context).pushNamed(
                                  '/video-call',
                                  arguments: {
                                    'roomCode': activeClass.code,
                                  },
                                );
                              }
                            : null,
                        icon: Icon(
                          isLive
                              ? Icons.videocam_rounded
                              : Icons.video_call_outlined,
                          size: 17,
                        ),
                        label: Text(
                          isLive
                              ? 'Supervisionar ao vivo'
                              : 'Abrir videochamada',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive
                              ? InstColors.live
                              : InstColors.ink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 13,
                          ),
                          textStyle: jakarta(size: 12, weight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildStatusBadge(
                    isLocked: activeClass.gradeLocked ||
                        _controller.isGradeLockedFor(activeClass.code),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: InstColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPERVISÃO ACADÊMICA',
                      style: jakarta(
                        size: 10,
                        weight: FontWeight.w700,
                        color: InstColors.muted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activeClass.subjectName,
                      style: jakarta(
                        size: 21,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${activeClass.code}  ·  ${activeClass.courseAndTerm}',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: InstColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeClass.location,
                      style: jakarta(size: 12, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: InstColors.border),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeaderStat(
                Icons.person_outline_rounded,
                'Docente regente',
                activeClass.professor,
              ),
              _buildHeaderStat(
                Icons.groups_outlined,
                'Ocupação de vagas',
                '${_controller.supervisedEnrollments.isNotEmpty ? _controller.supervisedEnrollments.length : activeClass.enrolled} / ${activeClass.maxCapacity} alunos',
              ),
              _buildHeaderStat(
                Icons.rule_rounded,
                'Regime vigente',
                activeClass.formulaRegime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required bool isLocked}) {
    final color = isLocked ? InstColors.success : const Color(0xFF525252);
    final background = isLocked ? InstColors.successBg : InstColors.stoneActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.verified_outlined : Icons.visibility_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            isLocked ? 'Pauta homologada' : 'Em auditoria acadêmica',
            style: jakarta(size: 11, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: InstColors.hoverSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: InstColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: InstColors.muted),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w600,
                    color: InstColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: InstColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BARRA DE ABAS DE SUPERVISÃO (5 ABAS)
  // ==========================================
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _controller.supervisionTabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Material(
                color: isSelected ? InstColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _controller.setSupervisionTab(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabIcons[index],
                          size: 16,
                          color: isSelected ? Colors.white : InstColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tabs[index],
                          style: jakarta(
                            size: 11,
                            weight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : InstColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DAS 5 ABAS
  // ==========================================
  Widget _buildActiveTabContent() {
    switch (_controller.supervisionTabIndex) {
      case 0:
        return _buildRegimeTab();
      case 1:
        return _buildGradeAuditTab();
      case 2:
        return _buildFacultyTab();
      case 3:
        return _buildStudentsTab();
      case 4:
        return _buildClosingTab();
      default:
        return _buildRegimeTab();
    }
  }

  // --- ABA 1: Diretriz & Regime Avaliativo (Print 49) ---
  Widget _buildRegimeTab() {
    return _buildContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            icon: Icons.rule_rounded,
            eyebrow: 'CONFIGURAÇÃO ACADÊMICA',
            title: 'Diretrizes de cálculo da nota',
            subtitle:
                'Selecione a fórmula aplicada à turma e registre a justificativa administrativa.',
          ),
          const SizedBox(height: 22),
          Text(
            'Fórmula de avaliação',
            style: jakarta(
              size: 12,
              weight: FontWeight.w600,
              color: InstColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          RadioGroup<String>(
            groupValue: _controller.selectedEvaluationFormula,
            onChanged: (value) {
              if (value != null) {
                setState(() => _controller.selectedEvaluationFormula = value);
              }
            },
            child: Column(
              children: [
                _buildFormulaOption(
                  title: 'Fórmula ponderada regimental',
                  subtitle:
                      'N1 40% + N2 60% · Média final = (N1 × 0,4) + (N2 × 0,6) · Presença mínima: 75%',
                  value: 'Ponderada (N1 40% / N2 60%)',
                ),
                const SizedBox(height: 8),
                _buildFormulaOption(
                  title: 'Fórmula equitativa',
                  subtitle: 'N1 50% + N2 50% · Média final = (N1 + N2) / 2',
                  value: 'Equitativa (N1 50% / N2 50%)',
                ),
                const SizedBox(height: 8),
                _buildFormulaOption(
                  title: 'Média aritmética de instrumentos contínuos',
                  subtitle:
                      'Média de todas as atividades, provas e trabalhos lançados.',
                  value: 'Aritmética Simples',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: InstColors.border),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: InstColors.stoneActive,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 19,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Despacho administrativo de auditoria',
                      style: jakarta(size: 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Documente a justificativa para eventuais flexibilizações regimentais.',
                      style: jakarta(size: 12, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _justificationController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Registro de autorização da Secretaria Geral ou justificativa da alteração...',
              filled: true,
              fillColor: InstColors.hoverSurface,
              contentPadding: EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(9)),
                borderSide: BorderSide(color: InstColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(9)),
                borderSide: BorderSide(color: InstColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(9)),
                borderSide: BorderSide(color: InstColors.ink, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final activeClass = _activeClass;
              final justification = _justificationController.text.trim();
              final formulaExpression = _formulaExpressionFor(
                _controller.selectedEvaluationFormula,
              );
              final ok = _controller.usesRemote
                  ? await _controller.persistClass(activeClass.code, {
                      'formulaRegime': 'admin',
                      'evaluationFormula': formulaExpression,
                      if (justification.isNotEmpty)
                        'justificationNote': justification,
                    })
                  : await _controller.updateFormulaRegime(
                      activeClass.code,
                      'Impor pelo Admin',
                    );
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _controller.remoteError ?? 'Falha ao salvar.',
                    ),
                  ),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Diretriz de cálculo gravada e homologada.'),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined, size: 17),
            label: const Text('Salvar diretriz regimental'),
            style: ElevatedButton.styleFrom(
              backgroundColor: InstColors.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              textStyle: jakarta(size: 12, weight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = _controller.selectedEvaluationFormula == value;
    return Material(
      color: selected ? InstColors.stone : InstColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            setState(() => _controller.selectedEvaluationFormula = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? InstColors.ink : InstColors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(value: value, activeColor: InstColors.ink),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: InstColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: jakarta(size: 11.5, color: InstColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeading({
    required IconData icon,
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: InstColors.stoneActive,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: InstColors.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: jakarta(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: InstColors.muted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: jakarta(
                  size: 17,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: jakarta(size: 11.5, color: InstColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ABA 2: Auditoria de Notas & Pauta (Print 50) ---
  Widget _buildGradeAuditTab() {
    if (!AppUserSession.instance.hasPermission('view_class_grades') ||
        !_controller.hasPermission(
          _controller.currentOperatorRole,
          'view_class_grades',
        )) {
      return const Center(
        child: AccessDeniedView(
          message: 'Seu perfil não pode consultar as pautas desta turma.',
        ),
      );
    }

    final gradeRows = _controller.supervisedGrades.map((grade) {
      final approved = grade.hasGrades &&
          grade.finalAverage >= 6.0 && grade.attendanceRate >= 75;
      return <String, String>{
        'nome': grade.studentName,
        'ra': grade.ra,
        'p1': grade.p1Score.toStringAsFixed(1),
        'p2': grade.p2Score.toStringAsFixed(1),
        'trab': grade.assignmentsScore.toStringAsFixed(1),
        'media': grade.finalAverage.toStringAsFixed(1),
        'faltas': grade.absences.toString(),
        'parecer': !grade.hasGrades
            ? 'Sem notas lançadas'
            : approved
                ? 'Aprovado por média e frequência'
                : 'Pendente de aprovação',
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pauta Consolidada em Tempo Real',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: _exportGrades,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar Ata de Notas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 780,
              child: Table(
                border: TableBorder.all(color: InstColors.border),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: InstColors.hoverSurface),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'DISCENTE / R.A.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'P1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'P2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'TRAB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'MÉDIA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'FALTAS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'PARECER AUDITORIA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...gradeRows.map((r) {
                    final isApproved = r['parecer']!.contains('Aprovado');
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '${r['nome']}\n${r['ra']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['p1']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['p2']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['trab']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['media']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['faltas']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['parecer']!,
                            style: TextStyle(
                              color: isApproved
                                  ? InstColors.success
                                  : InstColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Trilha de Auditoria da Pauta (Audit Trail)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.history, color: InstColors.ink),
            title: Text(
              '${_controller.supervisedGrades.length} registros de pauta carregados do servidor.',
            ),
            subtitle: _controller.supervisionError == null
                ? null
                : Text(_controller.supervisionError!),
          ),
        ],
      ),
    );
  }

  // --- ABA 3: Atribuição Docente (Print 51) ---
  Widget _buildFacultyTab() {
    final activeClass = _activeClass;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atribuição e Substituição Docente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: InstColors.ink,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              activeClass.professor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Docente Titular Homologado • Carga Horária: 80h/semestre',
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text(
            'Reatribuir Turma para Novo Docente:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _profController,
            decoration: const InputDecoration(
              labelText: 'Nome, e-mail ou matrícula do docente substituto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final profInput = _profController.text.trim();
              if (profInput.isEmpty ||
                  profInput == 'Não alocado' ||
                  profInput == 'Não atribuído') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Informe o nome, e-mail ou matrícula de um docente válido.',
                    ),
                  ),
                );
                return;
              }
              final ok = _controller.usesRemote
                  ? await _controller.persistClass(activeClass.code, {
                      'professorIdentity': profInput,
                    })
                  : await _controller.reallocateProfessor(
                      activeClass.code,
                      profInput,
                    );
              if (!mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _controller.remoteError ?? 'Falha ao salvar.',
                    ),
                  ),
                );
                return;
              }
              _profController.text = _initialProfessorInput(
                _activeClass.professor,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atribuição docente atualizada com sucesso!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: InstColors.ink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reatribuição'),
          ),
        ],
      ),
    );
  }

  // --- ABA 4: Discentes & Vagas (Print 52) ---
  Widget _buildStudentsTab() {
    final activeClass = _activeClass;
    final enrolledStudents = _controller.supervisedEnrollments;
    final enrolledCount = enrolledStudents.isNotEmpty
        ? enrolledStudents.length
        : activeClass.enrolled;
    final availableSeats = (activeClass.maxCapacity - enrolledCount)
        .clamp(0, activeClass.maxCapacity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discentes Matriculados ($enrolledCount / ${activeClass.maxCapacity} vagas)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: Text(
                  '$availableSeats ${availableSeats == 1 ? 'Vaga Disponível' : 'Vagas Disponíveis'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                  ),
                ),
                backgroundColor: const Color(0xFFDCFCE7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            'Estudantes matriculados: ${enrolledStudents.length}',
            style: TextStyle(fontSize: 12, color: InstColors.muted),
          ),
          const SizedBox(height: 8),
          if (enrolledStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum estudante matriculado nesta turma.'),
            )
          else
            ...enrolledStudents.map((u) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: InstColors.stoneActive,
                  child: Icon(Icons.school, color: InstColors.ink),
                ),
                title: Text(
                  u.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text('R.A.: ${u.ra}'),
              );
            }),
        ],
      ),
    );
  }

  // --- ABA 5: Fechamento de Pauta & Homologação (Print 53) ---
  Widget _buildClosingTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InstColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fechamento de Pauta & Lacração Oficial',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const CheckboxListTile(
            value: true,
            onChanged: null,
            title: Text(
              '100% das avaliações regimentais (N1 e N2) lançadas no diário',
            ),
          ),
          const CheckboxListTile(
            value: true,
            onChanged: null,
            title: Text(
              'Carga horária mínima exigida pelo MEC (80h) integralmente registrada',
            ),
          ),
          const CheckboxListTile(
            value: true,
            onChanged: null,
            title: Text(
              'Frequências apuradas e abonos de atestados médicos deferidos computados',
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          if (_activeClass.gradeLocked ||
              _controller.isGradeLockedFor(_activeClass.code)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: InstColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta pauta foi homologada e lacrada pela Secretaria Geral Acadêmica. Nenhuma alteração de nota ou frequência é permitida sem processo formal de retificação.',
                      style: TextStyle(
                        color: InstColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () async {
                final activeClass = _activeClass;
                final ok = _controller.usesRemote
                    ? await _controller.persistClass(activeClass.code, {
                        'gradeLocked': true,
                      })
                    : await _controller.lockAndHomologateClassPauta(
                        activeClass.code,
                      );
                if (!mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.remoteError ?? 'Falha ao salvar.',
                      ),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pauta acadêmica homologada e lacrada definitivamente!',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.lock, size: 16),
              label: const Text('Homologar e Lacrar Pauta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
