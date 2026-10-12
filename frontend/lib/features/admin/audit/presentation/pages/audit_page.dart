import 'package:flutter/material.dart';

class AuditPage extends StatelessWidget {
  const AuditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auditoria', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Auditoria de Segurança & Trilha Documental (Audit Trail)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Registro irrevogável de lançamentos de notas, deferimentos de protocolos, retificações e tentativas de acesso.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: const ListTile(
              title: Text('Lançamento de nota de avaliação (9.5) para discente Mariana Rios Costa'),
              subtitle: Text('Agente: Profa. Dra. Helena Bittencourt • IP: 177.136.24.10'),
              trailing: Chip(label: Text('INFO', style: TextStyle(color: Colors.blue))),
            ),
          ),
        ],
      ),
    );
  }
}