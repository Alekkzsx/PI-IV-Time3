// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Utilitários para exibição de modais acadêmicos (Boletim e Plano de Ensino).
class StudentDisciplinesModals {
  StudentDisciplinesModals._();

  /// Exibe o modal com o Boletim & Histórico Escolar Oficial.
  static void showBoletimModal(BuildContext context) {
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
              children: const [
                Text(
                  'Boletim & Histórico Escolar Oficial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gabriel Soares de Oliveira • R.A.: 2024.1.00892',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...StudentMockData.historicalBoletim.map((period) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.period,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Table(
                          border:
                              TableBorder.all(color: const Color(0xFFE5E7EB)),
                          children: [
                            const TableRow(
                              decoration:
                                  BoxDecoration(color: Color(0xFFF8FAFC)),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('CÓDIGO',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('DISCIPLINA',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('N1',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('N2',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('MÉDIA',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('FALTAS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('RESULTADO',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ),
                              ],
                            ),
                            ...period.items.map((item) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['codigo'] as String,
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['disciplina'] as String,
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['n1'].toString(),
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['n2'].toString(),
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['media'].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(item['faltas'].toString(),
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      item['situacao'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Download do Boletim Oficial iniciado (PDF).')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Exportar PDF Assinado'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Exibe o modal com o Plano de Ensino & Ementa Homologada.
  static void showPlanoEnsinoModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Plano de Ensino & Ementa Homologada',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Curso: Bacharelado em Engenharia de Software (4º Semestre)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  'Critérios Regimentais de Aprovação (Resolução CONSEPE 2026/04):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF18181B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Aprovação Direta: Média Final ≥ 6.0 e Frequência Global ≥ 75%\n'
                  '• Fórmula: Média Final = (N1 x 0.4) + (N2 x 0.6)\n'
                  '• Exame Especial: Médias entre 4.0 e 5.9 têm direito à Prova Final.\n'
                  '• Reprovação por Falta: Frequência inferior a 75% reprova sem direito a exame.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
                ),
                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 16),
                Text(
                  'Competências Pedagógicas Desenvolvidas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Aplicar padrões de projeto de software para produzir sistemas escaláveis e modulares.\n'
                  '2. Conduzir revisões arquiteturais e aplicar testes unitários com Clean Architecture.\n'
                  '3. Modelar e integrar soluções acadêmicas distribuídas.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

