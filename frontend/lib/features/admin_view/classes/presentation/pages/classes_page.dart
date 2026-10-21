// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin_view/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_footer.dart';
import 'supervision_cockpit_page.dart';

/// Tela de Gestão de Turmas, Ensalamento e Atribuição Docente na Visão do Administrador.
/// Permite alocar docentes regentes, gerenciar diretrizes de autonomia avaliativa
/// e supervisionar notas/frequências institucionais da turma.
class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  AdminClassModel? _activeSupervisedClass;

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
    if (_activeSupervisedClass != null) {
      return SupervisionCockpitPage(
        classModel: _activeSupervisedClass!,
        onBack: () => setState(() => _activeSupervisedClass = null),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 28),
                        _buildClassesTableCard(context),
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DA PÁGINA
  // ==========================================
  Widget _buildHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Turmas, Ensalamento & Atribuição Docente',
          style: jakarta(
            size: isDesktop ? 26 : 22,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Abertura de turmas no período letivo, alocação de salas/laboratórios e vinculação do professor regente.',
          style: jakarta(
            size: 14,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TABELA PRINCIPAL DE TURMAS
  // ==========================================
  Widget _buildClassesTableCard(BuildContext context) {
    final classesList = _controller.classes;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minWidth = 1180.0;
          final tableWidth =
              constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(),
                  for (int i = 0; i < classesList.length; i++)
                    _buildTableRow(context, classesList[i]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    final headerStyle = jakarta(
      size: 11,
      weight: FontWeight.w700,
      color: const Color(0xFF737373),
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 22,
            child: Text('CÓDIGO / DISCIPLINA', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 18,
            child: Text('CURSO & TURNO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 18,
            child: Text('LOCAL / ENSALAMENTO', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 12,
            child: Text(
              'VAGAS OCUPADAS',
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 18,
            child: Text('DOCENTE RESPONSÁVEL', style: headerStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 16,
            child: Text(
              'REGIME DE AVALIAÇÃO',
              style: headerStyle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 26,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('AÇÕES', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AdminClassModel c) {
    final isAutonomia = c.formulaRegime == 'Autonomia Docente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Código / Disciplina
          Expanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.subjectName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  c.code,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Curso & Turno
          Expanded(
            flex: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.courseName,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.semester,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  c.shift,
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Local / Ensalamento
          Expanded(
            flex: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    c.location,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF525252),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Vagas Ocupadas
          Expanded(
            flex: 12,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${c.enrolled}',
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    TextSpan(
                      text: ' / ${c.maxCapacity} vagas',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Docente Responsável
          Expanded(
            flex: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  size: 16,
                  color: Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.professor,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Regime de Avaliação
          Expanded(
            flex: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAutonomia
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAutonomia
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFE4E4E7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAutonomia
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                          size: 12,
                          color: isAutonomia
                              ? const Color(0xFF059669)
                              : const Color(0xFF737373),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          c.formulaRegime,
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: isAutonomia
                                ? const Color(0xFF059669)
                                : const Color(0xFF737373),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAutonomia
                      ? 'Docente define fórmula'
                      : 'Trava Regimental',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: isAutonomia
                        ? const Color(0xFF059669)
                        : const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Ações
          Expanded(
            flex: 26,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Supervisionar
                    InkWell(
                      onTap: () => setState(() => _activeSupervisedClass = c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Supervisionar',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Regime
                    InkWell(
                      onTap: () => _showRegimeFormulaModal(context, c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.balance,
                              size: 13,
                              color: Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Regime',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Alocar
                    InkWell(
                      onTap: () => _showAlocarDocenteModal(context, c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          'Alocar',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL REGIME DA FÓRMULA (Imagem 2)
  // ==========================================
  void _showRegimeFormulaModal(BuildContext context, AdminClassModel c) {
    String currentRegime = c.formulaRegime;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isAutonomia = currentRegime == 'Autonomia Docente';
          final isAdmin = currentRegime == 'Impor pelo Admin';

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: SizedBox(
              width: 660,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Modal
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE0E7FF),
                            ),
                          ),
                          child: const Icon(
                            Icons.balance,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GOVERNANÇA & PRERROGATIVAS DE AVALIAÇÃO',
                                style: jakarta(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF737373),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Regime da Fórmula da Nota Final',
                                style: jakarta(
                                  size: 20,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Color(0xFF737373),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Caixa de Identificação da Disciplina
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${c.code} – ${c.subjectName}',
                                  style: jakarta(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Text(
                                  c.courseName,
                                  style: jakarta(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Docente Regente: ',
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w400,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                TextSpan(
                                  text: c.professor,
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título da Seção
                    Text(
                      'DEFINIR PRERROGATIVA DA FÓRMULA DE AVALIAÇÃO',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Duas opções selecionáveis lado a lado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Impor pelo Admin
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(
                              () => currentRegime = 'Impor pelo Admin',
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isAdmin
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFE5E7EB),
                                  width: isAdmin ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: isAdmin
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF737373),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Impor pelo Admin',
                                          style: jakarta(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: const Color(0xFF18181B),
                                          ),
                                        ),
                                      ),
                                      if (isAdmin)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: Color(0xFF059669),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'O Admin/DTI fixa a fórmula de cálculo de forma compulsória. O professor fica com a fórmula travada em modo somente leitura no AVA.',
                                    style: jakarta(
                                      size: 12,
                                      weight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Card 2: Autonomia Docente
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(
                              () => currentRegime = 'Autonomia Docente',
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isAutonomia
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFE5E7EB),
                                  width: isAutonomia ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_open_outlined,
                                        size: 18,
                                        color: isAutonomia
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF737373),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Autonomia Docente',
                                          style: jakarta(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: const Color(0xFF18181B),
                                          ),
                                        ),
                                      ),
                                      if (isAutonomia)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: Color(0xFF059669),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Concede autonomia plena ao professor para decidir e parametrizar a fórmula da sua disciplina diretamente no seu AVA.',
                                    style: jakarta(
                                      size: 12,
                                      weight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Callout Informativo Dinâmico
                    if (isAutonomia)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          'Autonomia Pedagógica Habilitada:\n',
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF047857),
                                        height: 1.35,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'O docente ',
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                    TextSpan(
                                      text: c.professor,
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          ' visualizará um botão de configuração no AVA para escolher a fórmula matemática que preferir, adicionar ou remover instrumentos de avaliação, ajustar pesos e congelar/destravar notas.',
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF065F46),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_clock_outlined,
                              size: 20,
                              color: Color(0xFF475569),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Trava Regimental Aplicada:\n',
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                        height: 1.35,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'A fórmula de cálculo regimental (Média = N1 × 0.4 + N2 × 0.6) será imposta compulsoriamente. O professor regente visualizará o diário com os pesos bloqueados em modo de visualização estrita.',
                                      style: jakarta(
                                        size: 12.5,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Rodapé com Ações
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF525252),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            _controller.updateFormulaRegime(c.code, currentRegime);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Regime atualizado para: $currentRegime',
                                  style: jakarta(size: 13, color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF18181B),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Color(0xFF34D399),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Salvar Diretriz da Disciplina',
                                style: jakarta(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // MODAL ALOCAR DOCENTE
  // ==========================================
  void _showAlocarDocenteModal(BuildContext context, AdminClassModel c) {
    final profController = TextEditingController(text: c.professor);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE0E7FF),
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_outlined,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATRIBUIÇÃO & ENSALAMENTO DOCENTE',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF737373),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Alocar Docente Regente Titular',
                            style: jakarta(
                              size: 20,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF737373),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.code} – ${c.subjectName}',
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.courseName} • ${c.semester} • ${c.location}',
                        style: jakarta(
                          size: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  'Nome Completo do Docente Titular',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: profController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Profa. Dra. Helena Bittencourt',
                    hintStyle: jakarta(
                      size: 13.5,
                      color: const Color(0xFFA3A3A3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                  style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF525252),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (profController.text.trim().isNotEmpty) {
                          _controller.reallocateProfessor(
                            c.code,
                            profController.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Docente alocado com sucesso! Diário atualizado.',
                                style: jakarta(size: 13, color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFF18181B),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Confirmar Alocação',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
