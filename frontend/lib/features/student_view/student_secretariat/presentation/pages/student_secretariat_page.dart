// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../../../../shared/student_layout/student_sidebar.dart';
import '../../domain/entities/protocol_request.dart';
import '../controllers/student_secretariat_controller.dart';
import '../widgets/academic_record_card.dart';
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
    final record = _controller.recordSummary;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.verified_outlined, size: 20, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Declaração de Matrícula Digital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Declaramos para os devidos fins que o(a) discente portador(a) do R.A. ${record.ra} encontra-se regularmente matriculado(a) no curso de ${record.course} no período letivo vigente (2026/2).',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF3F3F46),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Código de Autenticidade Digital:\nAGMRM-2026-AUTH-9941-EF08',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF52525B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: Color(0xFF18181B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewRequestModal() {
    String selectedType = 'Horas Complementares';
    final objectController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Novo Requerimento Acadêmico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo / Assunto',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F46),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Horas Complementares',
                      child: Text('Horas Complementares'),
                    ),
                    DropdownMenuItem(
                      value: 'Segunda Chamada de Prova',
                      child: Text('Segunda Chamada de Prova'),
                    ),
                    DropdownMenuItem(
                      value: 'Revisão de Nota / Frequência',
                      child: Text('Revisão de Nota / Frequência'),
                    ),
                    DropdownMenuItem(
                      value: 'Histórico Escolar Oficial',
                      child: Text('Histórico Escolar Oficial'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedType = val);
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Objeto / Componente Curricular',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F46),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('new_request_object_input'),
                  controller: objectController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Certificado Workshop Cloud Computing (20h)',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF9CA3AF),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF71717A)),
              ),
            ),
            ElevatedButton(
              key: const Key('confirm_new_request_button'),
              onPressed: () {
                final text = objectController.text.trim();
                _controller.addProtocolRequest(
                  subjectType: selectedType,
                  componentObject: text.isEmpty
                      ? 'Solicitação Acadêmica Formal'
                      : text,
                );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Protocolar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpinionModal(ProtocolRequest protocol) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Parecer — ${protocol.protocolCode}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${protocol.subjectType}\n${protocol.componentObject}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                protocol.officialOpinion,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF3F3F46),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: Color(0xFF18181B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retornamos apenas a Column, eliminando o StudentPortalShell daqui!
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
                children: const [
                  Text(
                    'Secretaria Virtual & Requerimentos',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Emissão de declarações com autenticação digital, solicitação de segundas chamadas e acompanhamento de protocolos.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
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
                  label: const Text(
                    'Emitir Declaração de Matrícula',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181B),
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
                  label: const Text(
                    'Novo Requerimento',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
