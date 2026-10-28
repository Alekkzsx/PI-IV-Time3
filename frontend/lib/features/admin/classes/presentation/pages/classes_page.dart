// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_alocar_docente_modal.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_list_table.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_regime_formula_modal.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'supervision_cockpit_page.dart';

/// Tela de Gestão de Turmas, Ensalamento e Atribuição Docente na Visão do Administrador.
/// Refatorada com arquitetura limpa e subcomponentes desacoplados em `widgets/`.
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

  void _showRegimeFormulaModal(BuildContext context, AdminClassModel c) {
    ClassRegimeFormulaModal.show(
      context: context,
      classModel: c,
      onSaveRegime: (regime) => _controller.updateFormulaRegime(c.code, regime),
    );
  }

  void _showAlocarDocenteModal(BuildContext context, AdminClassModel c) {
    ClassAlocarDocenteModal.show(
      context: context,
      classModel: c,
      onConfirmAllocation: (prof) => _controller.reallocateProfessor(c.code, prof),
    );
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
                        ClassListTable(
                          classes: _controller.classes,
                          onSupervise: (c) => setState(() => _activeSupervisedClass = c),
                          onOpenRegime: (c) => _showRegimeFormulaModal(context, c),
                          onOpenAlocar: (c) => _showAlocarDocenteModal(context, c),
                        ),
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
}
