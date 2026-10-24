// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Console Avançado de Supervisão Institucional da Turma na Visão Administrativa.
/// Permite auditar notas em tempo real, configurar regimes de avaliação, reatribuir
/// docentes e emitir o fechamento homologado da pauta acadêmica.
class SupervisionCockpitPage extends StatefulWidget {
  final AdminClassModel classModel;
  final VoidCallback onBack;

  const SupervisionCockpitPage({
    super.key,
    required this.classModel,
    required this.onBack,
  });

  @override
  State<SupervisionCockpitPage> createState() => _SupervisionCockpitPageState();
}

class _SupervisionCockpitPageState extends State<SupervisionCockpitPage> {
  final AdminPortalController _controller = AdminPortalController.instance;

  final List<String> _tabs = [
    'Diretriz & Regime Avaliativo',
    'Auditoria de Notas & Pauta',
    'Atribuição Docente',
    'Discentes & Vagas',
    'Fechamento de Pauta & Homologação',
  ];

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
          _buildCockpitHeader(),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 24),
          _buildActiveTabContent(),
        ],
      ),
    );
  }

  // ==========================================
  // CABEÇALHO DO CONSOLE DE SUPERVISÃO
  // ==========================================
  Widget _buildCockpitHeader() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Voltar para Gestão de Turmas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF18181B),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              Chip(
                label: Text(
                  _controller.isGradeLocked ? 'PAUTA LACRADA & HOMOLOGADA' : 'EM AUDITORIA ACADÊMICA',
                  style: TextStyle(
                    color: _controller.isGradeLocked ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: _controller.isGradeLocked ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervisão: ${widget.classModel.subjectName}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF18181B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${widget.classModel.code} • ${widget.classModel.courseAndTerm} • ${widget.classModel.location}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('Docente Regente', widget.classModel.professor),
              const SizedBox(width: 32),
              _buildHeaderStat('Ocupação de Vagas', '${widget.classModel.enrolled} / ${widget.classModel.maxCapacity} alunos'),
              const SizedBox(width: 32),
              _buildHeaderStat('Regime Vigente', widget.classModel.formulaRegime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  // ==========================================
  // BARRA DE ABAS DE SUPERVISÃO (5 ABAS)
  // ==========================================
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _controller.supervisionTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (_) => _controller.setSupervisionTab(index),
              selectedColor: const Color(0xFF0F172A),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DAS 5 ABAS
  // ==========================================
  Widget _buildActiveTabContent() {
    switch (_controller.supervisionTabIndex) {
      case 0:
        return _buildRegimeTab();
      case 1:
        return _buildGradeAuditTab();
      case 2:
        return _buildFacultyTab();
      case 3:
        return _buildStudentsTab();
      case 4:
        return _buildClosingTab();
      default:
        return _buildRegimeTab();
    }
  }

  // --- ABA 1: Diretriz & Regime Avaliativo (Print 49) ---
  Widget _buildRegimeTab() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diretrizes Institucionais de Cálculo da Nota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Fórmula Ponderada Regimental (N1 40% / N2 60%)'),
              subtitle: const Text('Padrão CONSEPE: Média Final = (N1 x 0.4) + (N2 x 0.6) • Presença Mínima: 75%'),
              value: 'Ponderada (N1 40% / N2 60%)',
              // ignore: deprecated_member_use
              groupValue: _controller.selectedEvaluationFormula,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _controller.selectedEvaluationFormula = val!),
            ),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Fórmula Equitativa (N1 50% / N2 50%)'),
              subtitle: const Text('Média Final = (N1 + N2) / 2'),
              value: 'Equitativa (N1 50% / N2 50%)',
              // ignore: deprecated_member_use
              groupValue: _controller.selectedEvaluationFormula,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _controller.selectedEvaluationFormula = val!),
            ),
            // ignore: deprecated_member_use
            RadioListTile<String>(
              title: const Text('Média Aritmética de Instrumentos Contínuos'),
              subtitle: const Text('Média de todas as atividades, provas e trabalhos lançados'),
              value: 'Aritmética Simples',
              // ignore: deprecated_member_use
              groupValue: _controller.selectedEvaluationFormula,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _controller.selectedEvaluationFormula = val!),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            const Text('Despacho Administrativo de Auditoria:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Registro de autorização da Secretaria Geral sobre eventuais flexibilizações regimentais...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _controller.updateFormulaRegime(widget.classModel.code, 'Impor pelo Admin');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diretriz de cálculo gravada e homologada.')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              child: const Text('Salvar Diretriz Regimental'),
            ),
          ],
        ),
      ),
    );
  }

  // --- ABA 2: Auditoria de Notas & Pauta (Print 50) ---
  Widget _buildGradeAuditTab() {
    final gradeRows = [
      {'nome': 'Gabriel Soares de Oliveira', 'ra': '2024.1.00892', 'p1': '8.5', 'p2': '9.0', 'trab': '9.5', 'media': '8.9', 'faltas': '4', 'parecer': 'Aprovado por Média e Freq.'},
      {'nome': 'Mariana Rios Costa', 'ra': '2024.1.00912', 'p1': '9.0', 'p2': '9.5', 'trab': '9.8', 'media': '9.4', 'faltas': '2', 'parecer': 'Aprovado por Média e Freq.'},
      {'nome': 'Lucas Silva Santos', 'ra': '2024.1.00940', 'p1': '4.0', 'p2': '5.0', 'trab': '6.0', 'media': '5.0', 'faltas': '14', 'parecer': 'Exame Final Necessário'},
      {'nome': 'Beatriz Castro Lima', 'ra': '2024.1.00955', 'p1': '8.0', 'p2': '8.5', 'trab': '9.0', 'media': '8.4', 'faltas': '6', 'parecer': 'Aprovado por Média e Freq.'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pauta Consolidada em Tempo Real', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ata consolidada exportada com carimbo digital.'))),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar Ata de Notas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 780,
              child: Table(
                border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                    children: [
                      Padding(padding: EdgeInsets.all(10), child: Text('DISCENTE / R.A.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('P1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('P2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('TRAB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('MÉDIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('FALTAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(10), child: Text('PARECER AUDITORIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  ...gradeRows.map((r) {
                    final isApproved = r['parecer']!.contains('Aprovado');
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(10), child: Text('${r['nome']}\n${r['ra']}', style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(r['p1']!, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(r['p2']!, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(r['trab']!, style: const TextStyle(fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(r['media']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Padding(padding: const EdgeInsets.all(10), child: Text(r['faltas']!, style: const TextStyle(fontSize: 12))),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            r['parecer']!,
                            style: TextStyle(color: isApproved ? const Color(0xFF16A34A) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Trilha de Auditoria da Pauta (Audit Trail)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.history, color: Color(0xFF0F172A)),
            title: Text('Última alteração de nota registrada por Profa. Dra. Helena Bittencourt'),
            subtitle: Text('20/10/2026 às 14:22 • IP: 177.136.24.10 • Chancela Digital: #AGR-CHANC-9981'),
          ),
        ],
      ),
    );
  }

  // --- ABA 3: Atribuição Docente (Print 51) ---
  Widget _buildFacultyTab() {
    final profController = TextEditingController(text: widget.classModel.professor);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Atribuição e Substituição Docente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF0F172A), child: Icon(Icons.person, color: Colors.white)),
            title: Text(widget.classModel.professor, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Docente Titular Homologado • Carga Horária: 80h/semestre'),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text('Reatribuir Turma para Novo Docente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: profController,
            decoration: const InputDecoration(labelText: 'Nome do Docente Substituto', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _controller.reallocateProfessor(widget.classModel.code, profController.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atribuição docente atualizada com sucesso!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('Confirmar Reatribuição'),
          ),
        ],
      ),
    );
  }

  // --- ABA 4: Discentes & Vagas (Print 52) ---
  Widget _buildStudentsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discentes Matriculados (${widget.classModel.enrolled} / ${widget.classModel.maxCapacity} vagas)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Chip(label: const Text('6 Vagas Disponíveis', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))), backgroundColor: const Color(0xFFDCFCE7)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...AdminMockData.users.where((u) => u.profile == 'Discente').map((u) {
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.school, color: Color(0xFF0F172A))),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('R.A.: ${u.id} • ${u.email}'),
              trailing: Chip(label: Text(u.status), backgroundColor: const Color(0xFFDCFCE7)),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 5: Fechamento de Pauta & Homologação (Print 53) ---
  Widget _buildClosingTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fechamento de Pauta & Lacração Oficial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const CheckboxListTile(value: true, onChanged: null, title: Text('100% das avaliações regimentais (N1 e N2) lançadas no diário')),
          const CheckboxListTile(value: true, onChanged: null, title: Text('Carga horária mínima exigida pelo MEC (80h) integralmente registrada')),
          const CheckboxListTile(value: true, onChanged: null, title: Text('Frequências apuradas e abonos de atestados médicos deferidos computados')),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          if (_controller.isGradeLocked) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF16A34A)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta pauta foi homologada e lacrada pela Secretaria Geral Acadêmica. Nenhuma alteração de nota ou frequência é permitida sem processo formal de retificação.',
                      style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () {
                _controller.lockAndHomologateClassPauta(widget.classModel.code);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pauta acadêmica homologada e lacrada definitivamente!')));
              },
              icon: const Icon(Icons.lock, size: 16),
              label: const Text('Homologar e Lacrar Pauta'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
