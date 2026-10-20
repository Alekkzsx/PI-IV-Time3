// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';

/// Tela de Auditoria de Segurança & Trilha Documental (Audit Trail) da Visão do Administrador.
/// Exibe registros imutáveis de transações acadêmicas com rastreabilidade de operadores,
/// endereços IP, eventos de notas, protocolos e severidades.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final logs = _controller.auditLogs.where((l) {
      if (query.isEmpty) return true;
      return l.actor.toLowerCase().contains(query) ||
          l.description.toLowerCase().contains(query) ||
          l.actionType.toLowerCase().contains(query) ||
          l.ipAddress.contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auditoria', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Auditoria de Segurança & Trilha Documental (Audit Trail)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registro irrevogável de lançamentos de notas, deferimentos de protocolos, retificações e tentativas de acesso.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 380,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Filtrar por agente, descrição ou IP...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dossiê de auditoria exportado com assinatura ICP-Brasil.'))),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar Log Criptografado'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATA / HORA')),
                  DataColumn(label: Text('AGENTE OPERADOR')),
                  DataColumn(label: Text('EVENTO')),
                  DataColumn(label: Text('DESCRIÇÃO DA TRANSAÇÃO')),
                  DataColumn(label: Text('IP ORIGEM')),
                  DataColumn(label: Text('SEVERIDADE')),
                ],
                rows: logs.map((log) {
                  final isAtencao = log.severity == 'ATENCAO';
                  return DataRow(
                    cells: [
                      DataCell(Text(log.timestamp, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(log.actor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Chip(label: Text(log.actionType, style: const TextStyle(fontSize: 10)), backgroundColor: const Color(0xFFF1F5F9))),
                      DataCell(SizedBox(width: 320, child: Text(log.description, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                      DataCell(Text(log.ipAddress, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                      DataCell(
                        Chip(
                          label: Text(log.severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAtencao ? Colors.orange[800] : const Color(0xFF2563EB))),
                          backgroundColor: isAtencao ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
