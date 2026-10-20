// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Tela da Central de Entregas & Atividades Avaliativas da Visão do Aluno.
/// Exibe métricas de prazos, listagem com filtros, modal de envio com declaração
/// de integridade acadêmica e modal de devolutiva com notas por rubrica e recibo.
class StudentDeliveriesPage extends StatefulWidget {
  const StudentDeliveriesPage({super.key});

  @override
  State<StudentDeliveriesPage> createState() => _StudentDeliveriesPageState();
}

class _StudentDeliveriesPageState extends State<StudentDeliveriesPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildFilterTabs(),
          const SizedBox(height: 20),
          _buildDeliveriesList(),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO
  // ==========================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Central de Entregas & Atividades',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Acompanhamento de prazos regimentais, envio de artefatos de avaliação e pareceres detalhados por rubrica.',
                style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showSubmissaoGeralModal(context),
          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
          label: const Text('Submeter Atividade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARDS DE ESTATÍSTICA (KPIS DE ENTREGAS)
  // ==========================================
  Widget _buildStatsRow() {
    final pendingCount = _controller.deliveries.where((d) => d.status == 'Pendente').length;
    final inReviewCount = _controller.deliveries.where((d) => d.status == 'Em Análise').length;
    final evaluatedCount = _controller.deliveries.where((d) => d.status == 'Avaliada').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Pendentes de Envio', '$pendingCount', 'Atenção aos prazos', const Color(0xFFD97706))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Em Análise Docente', '$inReviewCount', 'Protocolos aguardando nota', const Color(0xFF2563EB))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Avaliadas com Parecer', '$evaluatedCount', 'Notas consolidadas', const Color(0xFF16A34A))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Média Ponderada', '9.7 / 10.0', 'Excelente rendimento', const Color(0xFF18181B))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
        ],
      ),
    );
  }

  // ==========================================
  // FILTROS POR STATUS (Print 28)
  // ==========================================
  Widget _buildFilterTabs() {
    final filters = ['Todas', 'Pendente', 'Em Análise', 'Avaliada'];

    return Row(
      children: filters.map((f) {
        final isSelected = _controller.activeDeliveryFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f == 'Todas' ? 'Todas as Atividades' : f),
            selected: isSelected,
            onSelected: (_) => _controller.setDeliveryFilter(f),
            selectedColor: const Color(0xFF18181B),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            side: BorderSide(color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // LISTAGEM DE ATIVIDADES
  // ==========================================
  Widget _buildDeliveriesList() {
    final filtered = _controller.deliveries.where((d) {
      if (_controller.activeDeliveryFilter == 'Todas') return true;
      return d.status == _controller.activeDeliveryFilter;
    }).toList();

    return Column(
      children: filtered.map((d) {
        Color badgeBg = const Color(0xFFF1F5F9);
        Color badgeFg = const Color(0xFF18181B);

        if (d.status == 'Pendente') {
          badgeBg = const Color(0xFFFEF3C7);
          badgeFg = const Color(0xFFD97706);
        } else if (d.status == 'Em Análise') {
          badgeBg = const Color(0xFFDBEAFE);
          badgeFg = const Color(0xFF1D4ED8);
        } else if (d.status == 'Avaliada') {
          badgeBg = const Color(0xFFDCFCE7);
          badgeFg = const Color(0xFF16A34A);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(4)),
                          child: Text(d.disciplineCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Text(d.disciplineName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(d.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
                    const SizedBox(height: 6),
                    Text('Prazo Final: ${d.dueDate} às ${d.dueHour} • Peso Regimental: ${d.weight.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                  ],
                ),
              ),
              Row(
                children: [
                  Chip(
                    label: Text(d.status, style: TextStyle(color: badgeFg, fontWeight: FontWeight.bold, fontSize: 11)),
                    backgroundColor: badgeBg,
                  ),
                  const SizedBox(width: 16),
                  if (d.status == 'Avaliada') ...[
                    OutlinedButton.icon(
                      onPressed: () => _showDevolutivaModal(context, d),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: Text('Ver Nota: ${d.score}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                      ),
                    ),
                  ] else if (d.status == 'Pendente') ...[
                    ElevatedButton.icon(
                      onPressed: () => _showSubmissaoDiretaModal(context, d),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () => _showProtocolModal(context, d),
                      child: Text('Protocolo: ${d.protocol ?? 'AGR-2026-SUB'}'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // MODAL DEVOLUTIVA & NOTA DETALHADA (Print 29)
  // ==========================================
  void _showDevolutivaModal(BuildContext context, StudentDeliveryItem item) {
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
                const Text('Devolutiva & Parecer Pedagógico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(item.title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nota Oficial Atribuída:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A))),
                      Text('${item.score} / 10.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Parecer Descritivo do Docente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text(item.feedback ?? 'Trabalho avaliado conforme critérios de rubrica.', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                const SizedBox(height: 16),
                const Text('Detalhamento por Rubrica Avaliativa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        Padding(padding: EdgeInsets.all(8), child: Text('CRITÉRIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('PESO MÁXIMO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(8), child: Text('NOTA OBTIDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...item.rubrics.map((r) {
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text(r['criterio'] as String, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${r['pontos']} pts', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                          Padding(padding: const EdgeInsets.all(8), child: Text('${r['nota']} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)))),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Protocolo Oficial de Submissão: ${item.protocol ?? 'AGR-2026-0913-1092'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download do comprovante de entrega iniciado (PDF).')));
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Baixar Comprovante Assinado'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL SUBMISSÃO DE ATIVIDADE (Print 30)
  // ==========================================
  void _showSubmissaoGeralModal(BuildContext context) {
    if (_controller.deliveries.isEmpty) return;
    final firstPending = _controller.deliveries.firstWhere((d) => d.status == 'Pendente', orElse: () => _controller.deliveries.first);
    _showSubmissaoDiretaModal(context, firstPending);
  }

  void _showSubmissaoDiretaModal(BuildContext context, StudentDeliveryItem item) {
    bool hasAgreedToIntegrity = false;
    final gitController = TextEditingController();
    final obsController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Submissão: ${item.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disciplina: ${item.disciplineName} • Prazo: ${item.dueDate} às ${item.dueHour}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: const [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF64748B)),
                        SizedBox(height: 8),
                        Text('Clique ou arraste o arquivo da entrega (PDF, DOCX, ZIP até 25MB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: gitController, decoration: const InputDecoration(labelText: 'Link do Repositório Git (Opcional)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: obsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações para o Docente', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: hasAgreedToIntegrity,
                        onChanged: (val) => setModalState(() => hasAgreedToIntegrity = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Declaração de Integridade Acadêmica: Declaro formalmente que este trabalho é de minha autoria e que não utilizei plágio ou ferramentas em desacordo com as diretrizes da disciplina.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: hasAgreedToIntegrity
                  ? () {
                      _controller.submitDelivery(
                        deliveryId: item.id,
                        fileName: 'submissao_${item.id.toLowerCase()}.zip',
                        gitUrl: gitController.text,
                        comments: obsController.text,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atividade submetida com sucesso! Protocolo emitido.')));
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
              child: const Text('Protocolar Envio'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProtocolModal(BuildContext context, StudentDeliveryItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Protocolo de Entrega Emitido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atividade: ${item.title}'),
            const SizedBox(height: 8),
            Text('Código do Protocolo: ${item.protocol ?? 'AGR-2026-SUB'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            const SizedBox(height: 8),
            const Text('Status: Em fila de correção pedagógica pelo docente titular.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
