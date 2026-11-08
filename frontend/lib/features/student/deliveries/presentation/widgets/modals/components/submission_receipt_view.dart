// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:agmrm_security/student/student_security.dart';

/// [SubmissionReceiptView]
///
/// Visualização do recibo oficial emitido após submissão bem-sucedida,
/// apresentando código de protocolo, timestamp, arquivo anexado,
/// assinatura digital SHA-256 e ações de download/conclusão.
class SubmissionReceiptView extends StatelessWidget {
  /// Código oficial do protocolo gerado.
  final String generatedProtocol;

  /// Carimbo de data/hora formatado.
  final String timestampStr;

  /// Nome do arquivo protocolado.
  final String? attachedFileName;

  /// Hash criptográfico SHA-256 retornado e verificado.
  final String sha256;

  /// Identificador da submissão para download, se disponível.
  final String? submissionId;

  /// Callback para baixar o arquivo submetido.
  final VoidCallback onDownloadSubmission;

  /// Callback para encerrar o modal.
  final VoidCallback onClose;

  /// Cria uma nova instância de [SubmissionReceiptView].
  const SubmissionReceiptView({
    super.key,
    required this.generatedProtocol,
    required this.timestampStr,
    required this.attachedFileName,
    required this.sha256,
    required this.submissionId,
    required this.onDownloadSubmission,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sua entrega foi autenticada e enviada para a fila de correção do docente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  generatedProtocol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Data e Hora do Registro:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      timestampStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Arquivo Protocolado:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      attachedFileName ?? 'trabalho.zip',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Assinatura Digital:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    SelectableText(
                      sha256.isEmpty ? 'Hash SHA-256 não retornado' : sha256,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                if (sha256.isNotEmpty && !sha256.contains('ALERTA')) ...[
                  const SizedBox(height: 12),
                  StudentIntegrityBadge(sha256: sha256, isVerified: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: submissionId == null ? null : onDownloadSubmission,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Baixar submissão'),
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
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Concluir e Voltar às Entregas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
