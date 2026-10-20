// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/data/admin_mock_data.dart';

/// Tela de Cursos & Matrizes Curriculares (PPC) da Visão do Administrador.
/// Exibe a estrutura pedagógica institucional, carga horária regimental,
/// critérios de aprovação e o modal de detalhamento do ementário por período.
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cursos', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Cursos & Matrizes Curriculares (PPC)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Estrutura pedagógica institucional, carga horária regimental e parametrização das fórmulas de avaliação.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          ...AdminMockData.courses.map((course) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCourseCard(context, course),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, AdminCourseModel course) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(label: Text(course.code)),
              Row(
                children: [
                  const Text('Graduação Presencial', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showMatrizCurricularModal(context, course),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('Ver Matriz & Ementário'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(course.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Matriz Homologada: ${course.matrix}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text('Carga Horária: ${course.workload}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text('Discentes Matriculados: ${course.studentsCount}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'CRITÉRIO REGIMENTAL DE APROVAÇÃO: ${course.formula}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL MATRIZ CURRICULAR & EMENTÁRIO (Print 45)
  // ==========================================
  void _showMatrizCurricularModal(BuildContext context, AdminCourseModel course) {
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
                Text('Matriz Curricular & Componentes: ${course.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${course.matrix} • Carga Horária Total: ${course.workload}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Componentes Curriculares em Oferta no Período Letivo Vigente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        Padding(padding: EdgeInsets.all(10), child: Text('PERÍODO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(10), child: Text('COMPONENTE CURRICULAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(10), child: Text('CARGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.all(10), child: Text('DOCENTE HOMOLOGADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    ...course.components.map((c) {
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(10), child: Text(c['semestre'] as String, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(10), child: Text(c['disciplina'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(10), child: Text(c['carga'] as String, style: const TextStyle(fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(10), child: Text(c['docente'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
