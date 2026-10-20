// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/presentation/controllers/admin_portal_controller.dart';

/// Tela da Secretaria Acadêmica Geral & Mesa de Protocolos da Visão do Administrador.
/// Permite filtrar protocolos por status, inspecionar documentos digitalizados
/// anexados e emitir deferimento ou indeferimento oficial com despacho formal.
class SecretaryPage extends StatefulWidget {
  const SecretaryPage({super.key});

  @override
  State<SecretaryPage> createState() => _SecretaryPageState();
}

class _SecretaryPageState extends State<SecretaryPage> {
  final AdminPortalController _controller = AdminPortalController.instance;

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
    final filteredProtocols = _controller.filteredProtocols;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Secretaria', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Secretaria Acadêmica Geral & Protocolos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mesa de análise de atestados médicos, pedidos de segunda chamada, trancamentos e validação de horas complementares.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildFilterTabs(),
          const SizedBox(height: 20),
          ...filteredProtocols.map((p) {
            final isAguardando = p.status == 'Aguardando Parecer';
            final isDeferido = p.status == 'Deferido';

            Color statusColor = const Color(0xFFD97706);
            Color statusBg = const Color(0xFFFEF3C7);
            if (isDeferido) {
              statusColor = const Color(0xFF16A34A);
              statusBg = const Color(0xFFDCFCE7);
            } else if (!isAguardando) {
              statusColor = const Color(0xFFDC2626);
              statusBg = const Color(0xFFFEE2E2);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                            const SizedBox(width: 12),
                            Chip(
                              label: Text(p.requestType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: const Color(0xFFF1F5F9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${p.studentName} (R.A.: ${p.studentRa}) • Entrada em ${p.date}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text('Justificativa: "${p.justification}"', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
                        if (p.decisionNote != null) ...[
                          const SizedBox(height: 6),
                          Text('Parecer Formal: ${p.decisionNote}', style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(p.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        backgroundColor: statusBg,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAnalisarRequerimentoModal(context, p),
                        icon: Icon(isAguardando ? Icons.fact_check : Icons.visibility, size: 16),
                        label: Text(isAguardando ? 'Analisar Requerimento' : 'Ver Parecer Completo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Aguardando Parecer', 'Deferido', 'Todos'];

    return Row(
      children: filters.map((f) {
        final isSelected = _controller.protocolFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (_) => _controller.setProtocolFilter(f),
            selectedColor: const Color(0xFF0F172A),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            side: BorderSide(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // MODAL ANALISAR REQUERIMENTO (Print 55)
  // ==========================================
  void _showAnalisarRequerimentoModal(BuildContext context, AdminProtocolModel p) {
    final parecerController = TextEditingController(text: p.decisionNote ?? 'Documentação idônea conferida perante os critérios da Resolução CONSEPE. Deferimento concedido com reflexo no diário.');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Análise do Requerimento: ${p.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${p.studentName} • R.A.: ${p.studentRa}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de Solicitação: ${p.requestType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Justificativa Discente: "${p.justification}"', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                const SizedBox(height: 16),
                const Text('Documento Digitalizado Anexo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.attachmentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Arquivo assinado digitalmente com certificado ICP-Brasil • 1.4 MB', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      OutlinedButton(onPressed: () {}, child: const Text('Visualizar')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Parecer Decisório da Secretaria Geral:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: parecerController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Escreva a fundamentação legal da decisão...'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
          if (p.status == 'Aguardando Parecer') ...[
            OutlinedButton(
              onPressed: () {
                _controller.decideProtocol(protocolId: p.id, defer: false, parecerNote: parecerController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requerimento indeferido.')));
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: const Text('Indeferir'),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.decideProtocol(protocolId: p.id, defer: true, parecerNote: parecerController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requerimento deferido! Lançamento automático em diário realizado.')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
              child: const Text('Deferir Requerimento'),
            ),
          ],
        ],
      ),
    );
  }
}
