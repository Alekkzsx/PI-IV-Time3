// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shell/presentation/widgets/student_sidebar.dart';
import '../../domain/entities/protocol_request.dart';
import '../controllers/student_secretariat_controller.dart';
import '../widgets/academic_record_card.dart';
import '../widgets/enrollment_declaration_modal.dart';
import '../widgets/new_protocol_modal.dart';
import '../widgets/protocol_opinion_modal.dart';
import '../widgets/protocol_requests_table.dart';

/// Página da Secretaria Virtual & Requerimentos (Visão do Aluno).
///
/// Permite consultar o Prontuário Acadêmico Regular, emitir declarações de
/// matrícula com autenticação digital e acompanhar protocolos cadastrados.
class StudentSecretariatPage extends StatefulWidget {
  /// Controlador reativo opcional da página de secretaria.
  final StudentSecretariatController? controller;

  /// Callback opcional para navegação customizada na barra lateral.
  final ValueChanged<StudentNavItem>? onNavItemSelected;

  /// Cria uma instância de [StudentSecretariatPage].
  const StudentSecretariatPage({
    super.key,
    this.controller,
    this.onNavItemSelected,
  });

  @override
  State<StudentSecretariatPage> createState() => _StudentSecretariatPageState();
}

class _StudentSecretariatPageState extends State<StudentSecretariatPage> {
  late final StudentSecretariatController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? StudentSecretariatController();
    _controller.addListener(_onControllerUpdated);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showEnrollmentDeclarationModal() {
    EnrollmentDeclarationModal.show(
      context,
      record: _controller.recordSummary,
    );
  }

  void _showNewRequestModal() {
    NewProtocolModal.show(
      context,
      controller: _controller,
    );
  }

  void _showOpinionModal(ProtocolRequest protocol) {
    ProtocolOpinionModal.show(
      context,
      protocol: protocol,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha de Cabeçalho: Título + Botões de Ação
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secretaria Virtual & Requerimentos',
                    style: jakarta(
                      size: 21,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Emissão de declarações com autenticação digital, solicitação de segundas chamadas e acompanhamento de protocolos.',
                    style: jakarta(
                      size: 13,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const Key('btn_emit_declaration'),
                  onPressed: _showEnrollmentDeclarationModal,
                  icon: const Icon(
                    Icons.print_outlined,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  label: Text(
                    'Emitir Declaração de Matrícula',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('btn_new_request'),
                  onPressed: _showNewRequestModal,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Novo Requerimento',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Cartão do Prontuário Acadêmico Regular
        AcademicRecordCard(record: _controller.recordSummary),
        const SizedBox(height: 28),
        // Tabela de Protocolos de Requerimento Cadastrados
        ProtocolRequestsTable(
          protocols: _controller.protocols,
          countLabel: _controller.protocolCountLabel,
          onViewOpinion: _showOpinionModal,
        ),
      ],
    );
  }
}
