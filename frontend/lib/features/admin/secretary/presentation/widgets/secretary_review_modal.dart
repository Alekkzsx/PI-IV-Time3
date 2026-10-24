// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Modal de Análise e Despacho de Requerimento da Secretaria Acadêmica
class SecretaryReviewModal extends StatefulWidget {
  final AdminProtocolModel protocol;
  final AdminPortalController controller;

  const SecretaryReviewModal({
    super.key,
    required this.protocol,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required AdminProtocolModel protocol,
    required AdminPortalController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) =>
          SecretaryReviewModal(protocol: protocol, controller: controller),
    );
  }

  @override
  State<SecretaryReviewModal> createState() => _SecretaryReviewModalState();
}

class _SecretaryReviewModalState extends State<SecretaryReviewModal> {
  late final TextEditingController _parecerController;

  @override
  void initState() {
    super.initState();
    _parecerController = TextEditingController(
      text:
          widget.protocol.decisionNote ??
          'Documentação idônea conferida perante os critérios da Resolução CONSEPE. Deferimento concedido com reflexo no diário.',
    );
  }

  @override
  void dispose() {
    _parecerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.protocol;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 660,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo com identificação e botão fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.id,
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'RA: ${p.studentRa}',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF737373),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF737373),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Nome do Discente e Metadados
              Text(
                p.studentName,
                style: jakarta(
                  size: 20,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo: ${p.requestType} • Submetido em ${p.date}',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w400,
                  color: const Color(0xFF737373),
                ),
              ),
              const SizedBox(height: 22),

              // Justificativa / Objeto do Requerimento
              Text(
                'Justificativa / Objeto do Requerimento',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  p.justification,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w400,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Documento Anexo
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.attachmentName,
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Documento oficial digitalizado',
                            style: jakarta(
                              size: 11.5,
                              color: const Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Anexo ${p.attachmentName} está disponível para conferência no prontuário.',
                              style: jakarta(size: 13, color: Colors.white),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.file_download_outlined,
                        size: 14,
                        color: Color(0xFF18181B),
                      ),
                      label: Text(
                        'Conferir Anexo',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Parecer Conclusivo da Secretaria Geral
              Text(
                'Parecer Conclusivo da Secretaria Geral (Registrado no Prontuário)',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _parecerController,
                maxLines: 3,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText: 'Escreva a fundamentação legal da decisão...',
                  hintStyle: jakarta(size: 13, color: const Color(0xFFA3A3A3)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF18181B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Callout de Impacto Imediato
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Impacto Imediato: ',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      TextSpan(
                        text:
                            p.immediateImpact ??
                            'Ao deferir a solicitação, a decisão da Secretaria Geral surtirá efeitos imediatos no histórico e diário acadêmico do aluno.',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Rodapé com Ações
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.controller.decideProtocol(
                        protocolId: p.id,
                        defer: false,
                        parecerNote: _parecerController.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Requerimento indeferido.',
                            style: jakarta(size: 13, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.highlight_off_rounded,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    label: Text(
                      'Indeferir',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.controller.decideProtocol(
                        protocolId: p.id,
                        defer: true,
                        parecerNote: _parecerController.text,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Requerimento deferido! Lançamento homologado com sucesso.',
                            style: jakarta(size: 13, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF18181B),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Deferir Requerimento',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
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
}
