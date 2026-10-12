import 'package:flutter/material.dart';

class SecretaryPage extends StatelessWidget {
  const SecretaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Secretaria', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Secretaria Acadêmica Geral & Protocolos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Mesa de análise de atestados médicos, pedidos de segunda chamada, trancamentos e validação de horas complementares.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: const ListTile(
              title: Text('PROT-2026/8841'),
              subtitle: Text('Camila Duarte Fagundes (2024.1.00962) • ATESTADO MÉDICO'),
              trailing: Chip(label: Text('Deferido', style: TextStyle(color: Colors.green))),
            ),
          ),
        ],
      ),
    );
  }
}