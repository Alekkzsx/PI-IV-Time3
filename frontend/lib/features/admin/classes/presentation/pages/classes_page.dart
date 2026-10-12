import 'package:flutter/material.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Turmas', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Gestão de Turmas, Ensalamento & Atribuição Docente', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Abertura de turmas no período letivo, alocação de salas/laboratórios e vinculação do professor regente.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('CÓDIGO / DISCIPLINA')),
                DataColumn(label: Text('CURSO & TURNO')),
                DataColumn(label: Text('LOCAL')),
                DataColumn(label: Text('VAGAS')),
                DataColumn(label: Text('DOCENTE')),
                DataColumn(label: Text('AÇÕES')),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Análise e Projeto de Sistemas II\n218131 - APS-II')),
                  const DataCell(Text('Engenharia de Software\n2026/2 • Noturno')),
                  const DataCell(Text('Lab Informática 04 - Bloco C')),
                  const DataCell(Text('34 / 40 vagas')),
                  const DataCell(Text('Profa. Dra. Helena Bittencourt')),
                  DataCell(ElevatedButton(onPressed: () {}, child: const Text('Supervisionar'))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}