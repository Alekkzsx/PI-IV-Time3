// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../controllers/student_secretariat_controller.dart';

/// Modal para submissão formal de novos requerimentos acadêmicos pelo aluno.
///
/// Reproduz com máxima fidelidade o fluxo de protocolo acadêmico direcionado
/// à Secretaria Geral e Coordenação de Curso.
class NewProtocolModal extends StatefulWidget {
  /// Controlador da secretaria para consultar opções e submeter o protocolo.
  final StudentSecretariatController controller;

  /// Cria uma instância de [NewProtocolModal].
  const NewProtocolModal({super.key, required this.controller});

  /// Método estático utilitário para exibir o modal na tela.
  static Future<void> show(
    BuildContext context, {
    required StudentSecretariatController controller,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NewProtocolModal(controller: controller),
    );
  }

  @override
  State<NewProtocolModal> createState() => _NewProtocolModalState();
}

class _NewProtocolModalState extends State<NewProtocolModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late String _selectedCurricularObject;
  final TextEditingController _justificationController =
      TextEditingController();

  String? _attachedFileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = StudentSecretariatController.availableRequestTypes.first;
    _selectedCurricularObject =
        StudentSecretariatController.availableCurricularObjects.first;
  }

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  void _simulateAttachment() {
    setState(() {
      _attachedFileName = _selectedType.contains('Horas')
          ? 'Certificado_Atividade_Extracurricular.pdf (1.8 MB)'
          : _selectedType.contains('Chamada')
          ? 'Atestado_Medico_CID_J06.pdf (840 KB)'
          : 'Documento_Comprobatorio_Academico.pdf (1.2 MB)';
      _errorMessage = null;
    });
  }

  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
    });
  }

  void _handleSubmit() {
    final justificationText = _justificationController.text.trim();
    if (justificationText.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, descreva a justificativa acadêmica.';
      });
      return;
    }

    widget.controller.addProtocolRequest(
      subjectType: _selectedType,
      componentObject: _selectedCurricularObject,
      justification: justificationText,
      attachmentName: _attachedFileName,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF18181B),
        content: Row(
          children: const [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF16A34A),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Requerimento acadêmico protocolado com sucesso!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: Ícone, Título, Subtítulo e Botão Fechar 'X'
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo Requerimento Acadêmico Formal',
                            style: jakarta(
                              size: 16,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Protocolo direcionado à Secretaria Geral e Coordenação de Curso',
                            style: jakarta(
                              size: 12.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF71717A),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF4F4F5),
                ),
                const SizedBox(height: 20),

                // Campo 1: Tipo de Requerimento
                _buildFieldLabel('Tipo de Requerimento *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF71717A),
                    size: 20,
                  ),
                  decoration: _buildInputDecoration(),
                  items: StudentSecretariatController.availableRequestTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: jakarta(
                              size: 13,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Campo 2: Componente Curricular / Objeto do Pedido
                _buildFieldLabel('Componente Curricular / Objeto do Pedido *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurricularObject,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF71717A),
                    size: 20,
                  ),
                  decoration: _buildInputDecoration(),
                  items: StudentSecretariatController.availableCurricularObjects
                      .map(
                        (obj) => DropdownMenuItem(
                          value: obj,
                          child: Text(
                            obj,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(
                              size: 13,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCurricularObject = val);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Campo 3: Justificativa Acadêmica e Motivação
                _buildFieldLabel('Justificativa Acadêmica e Motivação *'),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('new_request_justification_input'),
                  controller: _justificationController,
                  minLines: 4,
                  maxLines: 6,
                  style: jakarta(
                    size: 13,
                    color: const Color(0xFF18181B),
                    height: 1.45,
                  ),
                  decoration: _buildInputDecoration(
                    hintText:
                        'Descreva de forma clara os motivos do requerimento (ex: data da prova perdida, atestado anexado, especificação das atividades complementares)...',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Campo 4: Anexo Comprobatório
                _buildFieldLabel(
                  'Anexo Comprobatório (Atestado, Certificado ou Comprovante)',
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE4E4E7),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _attachedFileName == null
                            ? Icons.file_upload_outlined
                            : Icons.picture_as_pdf_outlined,
                        size: 20,
                        color: _attachedFileName == null
                            ? const Color(0xFF71717A)
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _attachedFileName ??
                              'Nenhum documento selecionado (PDF ou JPG até 10MB)',
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 12.5,
                            weight: _attachedFileName != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _attachedFileName != null
                                ? const Color(0xFF18181B)
                                : const Color(0xFF71717A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_attachedFileName == null)
                        OutlinedButton(
                          key: const Key('btn_simulate_attachment'),
                          onPressed: _simulateAttachment,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFE4E4E7),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Simular Anexo',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _removeAttachment,
                          child: Text(
                            'Remover',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Rodapé de Ações: Cancelar e Protocolar Requerimento
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE4E4E7),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF52525B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('confirm_new_request_button'),
                      onPressed: _handleSubmit,
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Protocolar Requerimento',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
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
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: jakarta(
        size: 12.5,
        weight: FontWeight.w600,
        color: const Color(0xFF27272A),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 12.5,
        color: const Color(0xFFA1A1AA),
        height: 1.4,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.2),
      ),
    );
  }
}
