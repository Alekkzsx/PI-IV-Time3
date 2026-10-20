// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/presentation/controllers/student_portal_controller.dart';

/// Painel Geral (Dashboard) da Visão do Aluno.
/// Exibe métricas acadêmicas consolidadas (CR, Disciplinas, Entregas, Horas Complementares),
/// aula síncrona do dia ao vivo e alternador reativo entre visualização em Cards e Lista.
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
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
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildLiveClassCard(),
          const SizedBox(height: 24),
          _buildDisciplinesHeader(),
          const SizedBox(height: 16),
          _controller.isGridView ? _buildDisciplinesGrid() : _buildDisciplinesList(),
          const SizedBox(height: 32),
          _buildDeadlinesAndNotices(),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO COM BOAS-VINDAS
  // ==========================================
  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Bem-vindo de volta, Gabriel Soares.',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18181B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'R.A.: 2024.1.00892 • Bacharelado em Engenharia de Software (4º Semestre • Matutino)',
              style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: const [
              Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text('2º Semestre Letivo de 2026', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BLOCO DE CARDS DE KPI (4 MÉTRICAS)
  // ==========================================
  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            'Disciplinas Ativas',
            '04',
            'Frequência média: 94.8%',
            Icons.school_outlined,
            const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            'Entregas do Mês',
            '04',
            'Próximo vencimento: Hoje 23:59',
            Icons.assignment_turned_in_outlined,
            const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            'Coeficiente de Rendimento',
            '8.8',
            'Situação Curricular: Regular',
            Icons.trending_up,
            const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            'Horas Complementares',
            '140h / 180h',
            '77.7% integralizadas',
            Icons.verified_outlined,
            const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
        ],
      ),
    );
  }

  // ==========================================
  // CARD DA AULA DO DIA (LIVE CARD)
  // ==========================================
  Widget _buildLiveClassCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.videocam_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('AULA DO DIA • 19:00 ÀS 20:40', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Análise e Projeto de Sistemas II (APS-II)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Profa. Dra. Helena Bittencourt • Sala Virtual AVA & Lab Informática 04', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/video-call'),
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Entrar na Videochamada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DO GRID COM ALTERNADOR DE VISUALIZAÇÃO
  // ==========================================
  Widget _buildDisciplinesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Minhas Disciplinas em Andamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _controller.toggleDashboardView(true),
              icon: Icon(Icons.grid_view, size: 16, color: _controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
              label: Text('Cards', style: TextStyle(color: _controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _controller.toggleDashboardView(false),
              icon: Icon(Icons.view_list, size: 16, color: !_controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
              label: Text('Tabela', style: TextStyle(color: !_controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: !_controller.isGridView ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // GRID VIEW DE DISCIPLINAS (Print 02)
  // ==========================================
  Widget _buildDisciplinesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: StudentMockData.disciplines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                    child: Text(d.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Text('${(d.progress * 100).toInt()}% concluído', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('${d.professor} • ${d.time}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: d.progress, backgroundColor: const Color(0xFFE2E8F0), valueColor: const AlwaysStoppedAnimation(Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frequência: ${d.attendancePercentage}%', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                  Text('Média: ${d.partialAverage.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // LIST VIEW DE DISCIPLINAS (Print 03)
  // ==========================================
  Widget _buildDisciplinesList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE5E7EB)),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              Padding(padding: EdgeInsets.all(12), child: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(12), child: Text('DISCIPLINA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(12), child: Text('DOCENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(12), child: Text('PROGRESSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(12), child: Text('FREQUÊNCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              Padding(padding: EdgeInsets.all(12), child: Text('MÉDIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ],
          ),
          ...StudentMockData.disciplines.map((d) {
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Text(d.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text(d.name, style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text(d.professor, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                Padding(padding: const EdgeInsets.all(12), child: Text('${(d.progress * 100).toInt()}%', style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text('${d.attendancePercentage}%', style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12), child: Text(d.partialAverage.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A)))),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================
  // PRAZOS PENDENTES E MURAL DE AVISOS
  // ==========================================
  Widget _buildDeadlinesAndNotices() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prazos & Entregas Pendentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildDeadlineRow('Padrões Adapter e Facade', 'APS-II', 'Hoje às 23:59', true),
                const SizedBox(height: 10),
                _buildDeadlineRow('Modelagem Relacional 3FN', 'BD-II', '24/10 às 23:59', false),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mural de Avisos & Comunicados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildNoticeRow('DTI: Manutenção Preventiva no Servidor AVA', 'Sábado 02:00 às 04:00', 'Informativo'),
                const SizedBox(height: 10),
                _buildNoticeRow('Secretaria: Prazo de Entrega de Horas Complementares', 'Encerramento em 30/11', 'Importante'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineRow(String title, String discipline, String due, bool isUrgent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(discipline, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        Chip(
          label: Text(due, style: TextStyle(fontSize: 11, color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          backgroundColor: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _buildNoticeRow(String title, String subtitle, String tag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Chip(label: Text(tag, style: const TextStyle(fontSize: 10)), backgroundColor: const Color(0xFFF1F5F9)),
      ],
    );
  }
}
