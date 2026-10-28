// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../domain/entities/academic_record_summary.dart';

/// Modal para exibição e emissão da Declaração de Matrícula Digital com autenticação.
class EnrollmentDeclarationModal extends StatelessWidget {
  /// Dados consolidados do prontuário acadêmico do discente.
  final AcademicRecordSummary record;

  /// Cria uma instância de [EnrollmentDeclarationModal].
  const EnrollmentDeclarationModal({
    super.key,
    required this.record,
  });

  /// Método estático utilitário para exibir a declaração na tela.
  static Future<void> show(
    BuildContext context, {
    required AcademicRecordSummary record,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EnrollmentDeclarationModal(record: record),
    );
  }

  void _handlePrintOrDownload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF18181B),
        content: Row(
          children: const [
            Icon(Icons.download_done_rounded, color: Color(0xFF16A34A), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Declaração de Matrícula gerada com sucesso! Download do PDF iniciado.',
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Oficial da Instituição
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          size: 26,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PORTAL AVA AGMRM',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFF18181B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Secretaria Geral de Registro e Controle Acadêmico',
                            style: jakarta(
                              size: 11.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF71717A),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
              const SizedBox(height: 22),

              // Título do Documento
              Center(
                child: Column(
                  children: [
                    Text(
                      'DECLARAÇÃO DE MATRÍCULA E REGULARIDADE ACADÊMICA',
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w800,
                        color: const Color(0xFF18181B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFFA7F3D0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        record.activeEnrollmentBadge,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Corpo do Texto Oficial
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  'Declaramos para os devidos fins de direito que o(a) discente ALEX GABRIEL SOARES SOUSA, inscrito(a) sob o Registro Acadêmico (R.A.) ${record.ra}, encontra-se regularmente matriculado(a) e com vínculo acadêmico ativo no curso de ${record.course}, no período letivo regular vigente (2026/2), cumprindo as exigências do Regimento Geral da Instituição.',
                  style: jakarta(
                    size: 13,
                    color: const Color(0xFF27272A),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grade de Detalhes Complementares
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      label: 'Coeficiente de Rendimento (CR)',
                      value: record.academicIndex,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildInfoItem(
                      label: 'Carga Horária Integralizada',
                      value: record.completedWorkload,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Caixa de Autenticação Digital e QR Code Simulado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 44,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chave Criptográfica de Autenticidade Digital:',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 3),
                          SelectableText(
                            'AGMRM-2026-BR-9941-8A7F-E21B',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Autenticidade passível de validação pública no portal agmrm.edu.br/autenticacao com validade de 90 dias a contar da emissão.',
                            style: jakarta(
                              size: 10.5,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Ações do Rodapé
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE4E4E7), width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Fechar',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF52525B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('btn_download_declaration_pdf'),
                    onPressed: () => _handlePrintOrDownload(context),
                    icon: const Icon(
                      Icons.print_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Imprimir / Salvar PDF',
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
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: jakarta(
              size: 11,
              weight: FontWeight.w500,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}
