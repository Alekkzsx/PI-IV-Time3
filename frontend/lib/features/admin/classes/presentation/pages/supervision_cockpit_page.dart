// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

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
                  _buildCockpitHeader(),
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

  // ==========================================
  // CABEÇALHO DO CONSOLE DE SUPERVISÃO
  // ==========================================
  Widget _buildCockpitHeader() {
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
                onPressed: widget.onBack,
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
                          .isSessionOpen(widget.classModel.code);
                      return ElevatedButton.icon(
                        key: const Key('btn_admin_supervisionar_chamada'),
                        onPressed: _controller.canPerform('manage_video_calls')
                            ? () {
                                Navigator.of(context).pushNamed(
                                  '/video-call',
                                  arguments: {
                                    'roomCode': widget.classModel.code,
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
                    isLocked: _controller.isGradeLockedFor(
                      widget.classModel.code,
                    ),
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
                      widget.classModel.subjectName,
                      style: jakarta(
                        size: 21,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${widget.classModel.code}  ·  ${widget.classModel.courseAndTerm}',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w500,
                        color: InstColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.classModel.location,
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
                widget.classModel.professor,
              ),
              _buildHeaderStat(
                Icons.groups_outlined,
                'Ocupação de vagas',
                '${widget.classModel.enrolled} / ${widget.classModel.maxCapacity} alunos',
              ),
              _buildHeaderStat(
                Icons.rule_rounded,
                'Regime vigente',
                widget.classModel.formulaRegime,
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
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
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
            onPressed: () {
              _controller.updateFormulaRegime(
                widget.classModel.code,
                'Impor pelo Admin',
              );
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

    final gradeRows = [
      {
        'nome': 'Gabriel Soares de Oliveira',
        'ra': '2024.1.00892',
        'p1': '8.5',
        'p2': '9.0',
        'trab': '9.5',
        'media': '8.9',
        'faltas': '4',
        'parecer': 'Aprovado por Média e Freq.',
      },
      {
        'nome': 'Mariana Rios Costa',
        'ra': '2024.1.00912',
        'p1': '9.0',
        'p2': '9.5',
        'trab': '9.8',
        'media': '9.4',
        'faltas': '2',
        'parecer': 'Aprovado por Média e Freq.',
      },
      {
        'nome': 'Lucas Silva Santos',
        'ra': '2024.1.00940',
        'p1': '4.0',
        'p2': '5.0',
        'trab': '6.0',
        'media': '5.0',
        'faltas': '14',
        'parecer': 'Exame Final Necessário',
      },
      {
        'nome': 'Beatriz Castro Lima',
        'ra': '2024.1.00955',
        'p1': '8.0',
        'p2': '8.5',
        'trab': '9.0',
        'media': '8.4',
        'faltas': '6',
        'parecer': 'Aprovado por Média e Freq.',
      },
    ];

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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ata consolidada exportada com carimbo digital.',
                    ),
                  ),
                ),
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
          const ListTile(
            leading: Icon(Icons.history, color: InstColors.ink),
            title: Text(
              'Última alteração de nota registrada por Profa. Dra. Helena Bittencourt',
            ),
            subtitle: Text(
              '20/10/2026 às 14:22 • IP: 177.136.24.10 • Chancela Digital: #AGR-CHANC-9981',
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 3: Atribuição Docente (Print 51) ---
  Widget _buildFacultyTab() {
    final profController = TextEditingController(
      text: widget.classModel.professor,
    );

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
              widget.classModel.professor,
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
            controller: profController,
            decoration: const InputDecoration(
              labelText: 'Nome do Docente Substituto',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _controller.reallocateProfessor(
                widget.classModel.code,
                profController.text,
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
    final enrolledStudents = AdminMockData.users
        .where(
          (user) =>
              user.profile == 'aluno' &&
              widget.classModel.enrolledStudentRas.contains(user.id),
        )
        .toList();

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
                'Discentes Matriculados (${widget.classModel.enrolled} / ${widget.classModel.maxCapacity} vagas)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: const Text(
                  '6 Vagas Disponíveis',
                  style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                ),
                backgroundColor: const Color(0xFFDCFCE7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            'Cadastros de demonstração vinculados: ${enrolledStudents.length}',
            style: TextStyle(fontSize: 12, color: InstColors.muted),
          ),
          const SizedBox(height: 8),
          if (enrolledStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum cadastro de demonstração vinculado à turma.'),
            )
          else
            ...enrolledStudents.map((u) {
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: InstColors.stoneActive,
                  child: Icon(Icons.school, color: InstColors.ink),
                ),
                title: Text(
                  u.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text('R.A.: ${u.id} • ${u.email}'),
                trailing: Chip(
                  label: Text(u.status),
                  backgroundColor: const Color(0xFFDCFCE7),
                ),
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
          if (_controller.isGradeLockedFor(widget.classModel.code)) ...[
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
              onPressed: () {
                _controller.lockAndHomologateClassPauta(widget.classModel.code);
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
