// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agmrm_security/student/student_security.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'components/submission_context_banner.dart';
import 'components/submission_file_dropzone.dart';
import 'components/submission_integrity_term.dart';
import 'components/submission_receipt_view.dart';

/// [DeliverySubmissionModal]
///
/// Modal orquestrador de submissão formal de atividades acadêmicas pelo estudante.
/// Coordena a validação criptográfica, rate limiting e persistência remota,
/// delegando a renderização visual para [SubmissionContextBanner],
/// [SubmissionFileDropzone], [SubmissionIntegrityTerm] e [SubmissionReceiptView].
class DeliverySubmissionModal extends StatefulWidget {
  /// Atividade acadêmica a ser submetida.
  final StudentDeliveryItem item;

  /// Cria uma nova instância de [DeliverySubmissionModal].
  const DeliverySubmissionModal({super.key, required this.item});

  /// Exibe o diálogo modal na árvore de widgets com bloqueio de cancelamento acidental.
  static Future<void> show(BuildContext context, StudentDeliveryItem item) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeliverySubmissionModal(item: item),
    );
  }

  @override
  State<DeliverySubmissionModal> createState() =>
      _DeliverySubmissionModalState();
}

class _DeliverySubmissionModalState extends State<DeliverySubmissionModal> {
  final _gitController = TextEditingController();
  final _obsController = TextEditingController();
  bool _agreedToIntegrity = false;
  bool _isSubmitting = false;

  String? _attachedFileName;
  String? _attachedFileSize;
  String? _attachedMimeType;
  List<int>? _attachedBytes;
  bool _isSuccess = false;
  String _generatedProtocol = '';
  String _sha256 = '';
  String? _submissionId;
  String _timestampStr = '';

  @override
  void dispose() {
    _gitController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _onPickFile() async {
    final file = await PlatformFileHelper.pickFile();
    if (file == null || !mounted) return;

    final validation = StudentFileUploadValidator.validateDeliveryFile(
      fileName: file.name,
      sizeBytes: file.sizeBytes,
      fileBytes: file.bytes,
    );

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage ?? 'Arquivo inválido.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final bytes = file.bytes;
    if (bytes.isEmpty || !mounted) return;
    setState(() {
      _attachedFileName = validation.sanitizedFileName;
      _attachedFileSize = file.sizeLabel;
      _attachedMimeType = file.mimeType;
      _attachedBytes = bytes;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arquivo "$_attachedFileName" validado com sucesso.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onRemoveFile() {
    setState(() {
      _attachedFileName = null;
      _attachedFileSize = null;
      _attachedMimeType = null;
      _attachedBytes = null;
    });
  }

  Future<void> _handleProtocolarEnvio() async {
    if (!_agreedToIntegrity ||
        _attachedFileName == null ||
        _attachedBytes == null) {
      return;
    }

    if (!StudentActionRateLimiter.instance.canExecute(
      StudentActionType.submitDelivery,
    )) {
      final cooldown = StudentActionRateLimiter.instance
          .getRemainingCooldownSeconds(StudentActionType.submitDelivery);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limite de submissões atingido. Aguarde $cooldown s por segurança.',
          ),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    final rawGitUrl = _gitController.text.trim();
    String? normalizedGitUrl;
    if (rawGitUrl.isNotEmpty) {
      final urlValidation =
          StudentGitRepositoryValidator.validateGitRepositoryUrl(rawGitUrl);
      if (!urlValidation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              urlValidation.errorMessage ??
                  'Link do repositório Git inválido.',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
      normalizedGitUrl = urlValidation.normalizedUrl;
    }

    final sanitizedComments =
        StudentTextInputSanitizer.sanitizeDeliveryComments(_obsController.text);

    setState(() => _isSubmitting = true);
    try {
      final receipt = await StudentPortalController.instance.submitDelivery(
        deliveryId: widget.item.id,
        fileName: _attachedFileName!,
        fileSize: _attachedFileSize!,
        mimeType: _attachedMimeType ?? 'application/octet-stream',
        contentBase64: base64Encode(_attachedBytes!),
        gitUrl: normalizedGitUrl,
        comments: sanitizedComments.isNotEmpty ? sanitizedComments : null,
      );

      StudentActionRateLimiter.instance.recordAction(
        StudentActionType.submitDelivery,
      );

      if (!mounted) return;
      final now = DateTime.now();
      final timeFormatted =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final serverSha = receipt['sha256']?.toString() ?? '';
      final isTamperProof =
          StudentSubmissionIntegrityVerifier.verifySubmissionReceipt(
            localFileBytes: _attachedBytes!,
            serverReceiptSha256: serverSha,
          );

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _generatedProtocol = receipt['protocolCode']?.toString() ?? '';
        _sha256 = isTamperProof ? serverSha : 'ALERTA: Divergência de Hash';
        _submissionId =
            receipt['submissionId']?.toString() ?? receipt['id']?.toString();
        _timestampStr = timeFormatted;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = error is ApiException
          ? error.message
          : 'Não foi possível protocolar a entrega.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _downloadSubmission() async {
    final id = _submissionId;
    if (id == null || id.isEmpty) return;
    try {
      final path = await StudentPortalController.instance.downloadSubmission(
        id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Não foi possível salvar a submissão.'
                : 'Submissão salva em $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Container(
        width: 660,
        constraints: const BoxConstraints(maxHeight: 740),
        child: _isSuccess
            ? SubmissionReceiptView(
                generatedProtocol: _generatedProtocol,
                timestampStr: _timestampStr,
                attachedFileName: _attachedFileName,
                sha256: _sha256,
                submissionId: _submissionId,
                onDownloadSubmission: _downloadSubmission,
                onClose: () => Navigator.pop(context),
              )
            : _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      size: 20,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submissão de Atividade Acadêmica',
                        style: jakarta(
                          size: 16,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confira os parâmetros regimentais e protocole os artefatos requeridos.',
                        style: jakarta(
                          size: 12,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Color(0xFF71717A),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubmissionContextBanner(item: widget.item),
                const SizedBox(height: 20),
                Text(
                  '1. Artefato Principal da Entrega',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                SubmissionFileDropzone(
                  attachedFileName: _attachedFileName,
                  attachedFileSize: _attachedFileSize,
                  allowedFormats: widget.item.allowedFormats,
                  onPickFile: _onPickFile,
                  onRemoveFile: _onRemoveFile,
                ),
                const SizedBox(height: 20),
                Text(
                  '2. Links & Observações Pedagógicas (Opcional)',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _gitController,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    labelText:
                        'Link do Repositório Git (GitHub, GitLab ou Bitbucket)',
                    labelStyle: jakarta(
                      size: 12,
                      color: const Color(0xFF71717A),
                    ),
                    prefixIcon: const Icon(
                      Icons.code,
                      size: 18,
                      color: Color(0xFF71717A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _obsController,
                  maxLines: 2,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    labelText: 'Notas / Observações para o Docente',
                    labelStyle: jakarta(
                      size: 12,
                      color: const Color(0xFF71717A),
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SubmissionIntegrityTerm(
                  agreed: _agreedToIntegrity,
                  onChanged: (val) => setState(() => _agreedToIntegrity = val),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F5),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF71717A),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: jakarta(
                    size: 12,
                    color: const Color(0xFF71717A),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    (_agreedToIntegrity &&
                        _attachedFileName != null &&
                        !_isSubmitting)
                    ? _handleProtocolarEnvio
                    : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, size: 16),
                label: Text(
                  _isSubmitting
                      ? 'Gerando Protocolo...'
                      : 'Protocolar Envio Oficial',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFFA1A1AA),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

