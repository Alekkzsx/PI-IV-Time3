// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Modal interativo de submissão de atividade ("Realizar Entrega").
/// Oferece simulação de anexo de arquivo, link de repositório Git, notas ao docente,
/// termo de integridade acadêmica com trava de validação e emissão de protocolo criptográfico.
class DeliverySubmissionModal extends StatefulWidget {
  final StudentDeliveryItem item;

  const DeliverySubmissionModal({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, StudentDeliveryItem item) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeliverySubmissionModal(item: item),
    );
  }

  @override
  State<DeliverySubmissionModal> createState() => _DeliverySubmissionModalState();
}

class _DeliverySubmissionModalState extends State<DeliverySubmissionModal> {
  final _gitController = TextEditingController();
  final _obsController = TextEditingController();
  bool _agreedToIntegrity = false;
  bool _isSubmitting = false;

  // Estado do Arquivo Anexado
  String? _attachedFileName;
  String? _attachedFileSize;
  bool _isSuccess = false;
  String _generatedProtocol = '';
  String _timestampStr = '';

  @override
  void initState() {
    super.initState();
    // Sugestão de nome padrão amigável baseado no ID
    _attachedFileName = 'submissao_${widget.item.id.toLowerCase()}_trabalho.zip';
    _attachedFileSize = '4.2 MB';
  }

  @override
  void dispose() {
    _gitController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _onPickFile() {
    setState(() {
      _attachedFileName = '${widget.item.activityCode?.replaceAll(' ', '').toLowerCase() ?? 'entrega'}_final.pdf';
      _attachedFileSize = '2.8 MB';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arquivo "$_attachedFileName" selecionado e validado.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRemoveFile() {
    setState(() {
      _attachedFileName = null;
      _attachedFileSize = null;
    });
  }

  void _handleProtocolarEnvio() {
    if (!_agreedToIntegrity || _attachedFileName == null) return;

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final protocol = StudentPortalController.instance.submitDelivery(
        deliveryId: widget.item.id,
        fileName: _attachedFileName!,
        gitUrl: _gitController.text.trim().isNotEmpty ? _gitController.text.trim() : null,
        comments: _obsController.text.trim().isNotEmpty ? _obsController.text.trim() : null,
      );

      final now = DateTime.now();
      final timeFormatted = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _generatedProtocol = protocol;
        _timestampStr = timeFormatted;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 660,
        constraints: const BoxConstraints(maxHeight: 740),
        child: _isSuccess ? _buildSuccessReceipt() : _buildFormContent(),
      ),
    );
  }

  // ===========================================================================
  // TELA DO FORMULÁRIO DE ENVIO
  // ===========================================================================
  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabeçalho do Modal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, size: 20, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Submissão de Atividade Acadêmica',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Confira os parâmetros regimentais e protocole os artefatos requeridos.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // 2. Corpo com Rolagem
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumo Contextual da Atividade
                _buildActivityContextBanner(),
                const SizedBox(height: 20),

                // Seção 1: Upload de Arquivo / Dropzone
                const Text(
                  '1. Artefato Principal da Entrega',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                _buildDropzoneArea(),
                const SizedBox(height: 20),

                // Seção 2: Repositório Git & Observações
                const Text(
                  '2. Links & Observações Pedagógicas (Opcional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _gitController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Link do Repositório Git (GitHub, GitLab ou Bitbucket)',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.code, size: 18, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Notas / Observações para o Docente',
                    labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Seção 3: Termo de Integridade Acadêmica
                _buildIntegrityCard(),
              ],
            ),
          ),
        ),

        // 3. Rodapé com Ações
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: (_agreedToIntegrity && _attachedFileName != null && !_isSubmitting)
                    ? _handleProtocolarEnvio
                    : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_outlined, size: 16),
                label: Text(_isSubmitting ? 'Gerando Protocolo...' : 'Protocolar Envio Oficial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityContextBanner() {
    return Container(
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
              Text(
                widget.item.activityCode ?? widget.item.disciplineCode,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled, size: 11, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text(
                      'Prazo: ${widget.item.dueDate} às ${widget.item.dueHour}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.item.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Disciplina: ${widget.item.disciplineName} • Docente: ${widget.item.professor ?? "Docente Titular"} • Peso: ${widget.item.weight.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropzoneArea() {
    if (_attachedFileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insert_drive_file, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _attachedFileName!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tamanho: ${_attachedFileSize ?? "4.2 MB"} • Arquivo íntegro verificado',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _onPickFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text('Substituir', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
              onPressed: _onRemoveFile,
              tooltip: 'Remover anexo',
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _onPickFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF64748B)),
            const SizedBox(height: 10),
            const Text(
              'Clique ou arraste o arquivo do trabalho aqui',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.allowedFormats ?? 'Formatos aceitos: .pdf, .zip • Max: 25MB',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreedToIntegrity,
            activeColor: const Color(0xFFD97706),
            onChanged: (val) => setState(() => _agreedToIntegrity = val ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Declaração de Integridade Acadêmica & Anti-Plágio',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 4),
                Text(
                  'Declaro formalmente sob as penalidades regimentais que o artefato submetido é de minha autoria autêntica e não constitui cópia não autorizada, plágio ou violação às normas pedagógicas da instituição.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TELA DO RECIBO OFICIAL COM PROTOCOLO EMITIDO
  // ===========================================================================
  Widget _buildSuccessReceipt() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 36, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Submissão Protocolada com Sucesso!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sua entrega foi autenticada e enviada para a fila de correção do docente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Painel do Protocolo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Text(
                  'CÓDIGO OFICIAL DO PROTOCOLO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _generatedProtocol,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Data e Hora do Registro:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(_timestampStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Arquivo Protocolado:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(_attachedFileName ?? 'trabalho.zip', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Assinatura Digital:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text('SHA-256 Validado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download do comprovante de entrega iniciado (PDF).')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Baixar Comprovante (PDF)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Concluir e Voltar às Entregas', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
