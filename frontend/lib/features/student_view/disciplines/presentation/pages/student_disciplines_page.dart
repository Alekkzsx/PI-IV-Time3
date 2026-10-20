// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'student_ava_cockpit_page.dart';

/// Tela principal de Minhas Disciplinas da Visão do Aluno.
/// Exibe carga horária total, média consolidada, ensalamento semanal,
/// modais de Boletim Oficial e Ementário, e acesso ao Ambiente Virtual (AVA).
class StudentDisciplinesPage extends StatefulWidget {
  const StudentDisciplinesPage({super.key});

  @override
  State<StudentDisciplinesPage> createState() => _StudentDisciplinesPageState();
}

class _StudentDisciplinesPageState extends State<StudentDisciplinesPage> {
  final StudentPortalController _controller = StudentPortalController.instance;
  StudentDisciplineModel? _activeDisciplineCockpit;
  String _selectedFilter = 'Todas as Disciplinas (4)';

  @override
  Widget build(BuildContext context) {
    if (_activeDisciplineCockpit != null) {
      return StudentAvaCockpitPage(
        discipline: _activeDisciplineCockpit!,
        onBack: () => setState(() => _activeDisciplineCockpit = null),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGeneralStats(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 24),
          _buildDisciplinesGrid(),
          const SizedBox(height: 32),
          _buildScheduleAndEnsalamento(),
        ],
      ),
    );
  }

  // ==========================================
  // BLOCO 1: CABEÇALHO
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
                'Minhas Disciplinas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ambiente Virtual de Aprendizagem (AVA), cronograma de aulas, tarefas ativas e boletim oficial.',
                style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showPlanoEnsinoModal(context),
              icon: const Icon(Icons.menu_book_outlined, size: 18, color: Color(0xFF18181B)),
              label: const Text('Plano de Ensino & Ementa', style: TextStyle(color: Color(0xFF18181B))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showBoletimModal(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Boletim & Histórico Oficial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // BLOCO 2: ESTATÍSTICAS GERAIS
  // ==========================================
  Widget _buildGeneralStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Carga Horária do Semestre',
              '190h / 280h cursadas (68%)',
              Icons.timelapse_outlined,
              const Color(0xFF18181B),
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _buildStatItem(
              'Média Ponderada Consolidada',
              '8.63 / 10.0',
              Icons.analytics_outlined,
              const Color(0xFF16A34A),
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _buildStatItem(
              'Frequência Global Registrada',
              '95.7% (12 faltas acumuladas)',
              Icons.check_circle_outline,
              const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF18181B)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLOCO 3: FILTROS
  // ==========================================
  Widget _buildFilterRow() {
    final filters = [
      'Todas as Disciplinas (4)',
      'Com Tarefas Pendentes (3)',
      'Aulas em Laboratório (2)',
    ];

    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = f),
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
  // BLOCO 4: GRID DE DISCIPLINAS
  // ==========================================
  Widget _buildDisciplinesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: StudentMockData.disciplines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final d = StudentMockData.disciplines[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(d.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Chip(
                    label: Text('${(d.progress * 100).toInt()}% Concluído', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                    backgroundColor: const Color(0xFFDCFCE7),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF18181B))),
              Text('${d.professor} • ${d.time}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: d.progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF18181B)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frequência: ${d.attendancePercentage}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ElevatedButton(
                    onPressed: () {
                      _controller.selectDiscipline(d);
                      setState(() => _activeDisciplineCockpit = d);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Acessar AVA', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // BLOCO 5: ENSALAMENTO E QUADRO SEMANAL
  // ==========================================
  Widget _buildScheduleAndEnsalamento() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quadro Semanal de Horários & Ensalamento Físico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Locais de aula presenciais homologados pela DTI e Conselho Universitário para 2026/2.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: const Color(0xFFE5E7EB)),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('DIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('1º HORÁRIO (19:00 - 20:40)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('2º HORÁRIO (20:50 - 22:30)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('Segunda-feira', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Análise e Projeto de Sistemas II\nLab 04 - Bloco C', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Fundamentos de Sist. Operacionais\nLab 01 - Bloco C', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('Terça-feira', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Fundamentos de I.A.\nSala 302 - Bloco A', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Banco de Dados II\nLab 02 - Bloco B', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('Quarta-feira', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Análise e Projeto de Sistemas II\nLab 04 - Bloco C', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Fundamentos de Sist. Operacionais\nLab 01 - Bloco C', style: TextStyle(fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text('Quinta-feira', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Fundamentos de I.A.\nSala 302 - Bloco A', style: TextStyle(fontSize: 12))),
                  Padding(padding: EdgeInsets.all(12), child: Text('Banco de Dados II\nLab 02 - Bloco B', style: TextStyle(fontSize: 12))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL: BOLETIM & HISTÓRICO OFICIAL (Print 08)
  // ==========================================
  void _showBoletimModal(BuildContext context) {
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
                Text('Boletim & Histórico Escolar Oficial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Gabriel Soares de Oliveira • R.A.: 2024.1.00892', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
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
                        Text(period.period, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF18181B))),
                        const SizedBox(height: 8),
                        Table(
                          border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('DISCIPLINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('N1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('N2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('MÉDIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('FALTAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('RESULTADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              ],
                            ),
                            ...period.items.map((item) {
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['codigo'] as String, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['disciplina'] as String, style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['n1'].toString(), style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['n2'].toString(), style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['media'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['faltas'].toString(), style: const TextStyle(fontSize: 11))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(item['situacao'] as String, style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11))),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download do Boletim Oficial iniciado (PDF).')));
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Exportar PDF Assinado'),
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
  // MODAL: PLANO DE ENSINO & EMENTA (Print 09)
  // ==========================================
  void _showPlanoEnsinoModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Plano de Ensino & Ementa Homologada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Curso: Bacharelado em Engenharia de Software (4º Semestre)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 12),
                Text('Critérios Regimentais de Aprovação (Resolução CONSEPE 2026/04):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF18181B))),
                SizedBox(height: 4),
                Text('• Aprovação Direta: Média Final ≥ 6.0 e Frequência Global ≥ 75%\n• Fórmula: Média Final = (N1 x 0.4) + (N2 x 0.6)\n• Exame Especial: Médias entre 4.0 e 5.9 têm direito à Prova Final.\n• Reprovação por Falta: Frequência inferior a 75% reprova sem direito a exame.', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 16),
                Text('Competências Pedagógicas Desenvolvidas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 4),
                Text('1. Aplicar padrões de projeto de software para produzir sistemas escaláveis e modulares.\n2. Conduzir revisões arquiteturais e aplicar testes unitários com Clean Architecture.\n3. Modelar e integrar soluções acadêmicas distribuídas.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18181B), foregroundColor: Colors.white),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
