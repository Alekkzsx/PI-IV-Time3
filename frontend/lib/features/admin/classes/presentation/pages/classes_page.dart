// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/presentation/controllers/admin_portal_controller.dart';
import 'supervision_cockpit_page.dart';

/// Tela de Gestão de Turmas, Ensalamento e Atribuição Docente na Visão do Administrador.
/// Permite alocar docentes, alternar o regime da fórmula regimental e abrir o
/// console de supervisão institucional da turma.
class ClassesPage extends StatefulWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  AdminClassModel? _activeSupervisedClass;

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
    if (_activeSupervisedClass != null) {
      return SupervisionCockpitPage(
        classModel: _activeSupervisedClass!,
        onBack: () => setState(() => _activeSupervisedClass = null),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Turmas', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Gestão de Turmas, Ensalamento & Atribuição Docente',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Abertura de turmas no período letivo, alocação de salas/laboratórios e vinculação do professor regente.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('CÓDIGO / DISCIPLINA')),
                DataColumn(label: Text('CURSO & TURNO')),
                DataColumn(label: Text('LOCAL')),
                DataColumn(label: Text('VAGAS')),
                DataColumn(label: Text('DOCENTE REGENTE')),
                DataColumn(label: Text('AÇÕES')),
              ],
              rows: _controller.classes.map((c) {
                return DataRow(
                  cells: [
                    DataCell(Text('${c.subjectName}\n${c.code}')),
                    DataCell(Text(c.courseAndTerm)),
                    DataCell(Text(c.location)),
                    DataCell(Text('${c.enrolled} / ${c.maxCapacity} vagas')),
                    DataCell(
                      Row(
                        children: [
                          Expanded(child: Text(c.professor, overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            tooltip: 'Alocar Docente',
                            onPressed: () => _showAlocarDocenteModal(context, c),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => setState(() => _activeSupervisedClass = c),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Supervisionar', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _showRegimeFormulaModal(context, c),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            child: const Text('Regime', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL REGIME DA FÓRMULA (Print 47)
  // ==========================================
  void _showRegimeFormulaModal(BuildContext context, AdminClassModel c) {
    String currentRegime = c.formulaRegime;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Regime de Avaliação: ${c.subjectName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Impor pelo Admin (Trava Regimental)'),
                subtitle: const Text('A fórmula regimental (N1 40% / N2 60%) é obrigatória e bloqueada contra alterações no Gradebook do professor.'),
                value: 'Impor pelo Admin',
                groupValue: currentRegime,
                onChanged: (val) => setModalState(() => currentRegime = val!),
              ),
              RadioListTile<String>(
                title: const Text('Conceder Autonomia Docente'),
                subtitle: const Text('Permite ao professor flexibilizar pesos de provas, atividades práticas e projetos integradores no diário.'),
                value: 'Autonomia Docente',
                groupValue: currentRegime,
                onChanged: (val) => setModalState(() => currentRegime = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                _controller.updateFormulaRegime(c.code, currentRegime);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Regime atualizado para: $currentRegime')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              child: const Text('Salvar Regime'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL ALOCAR DOCENTE (Print 48)
  // ==========================================
  void _showAlocarDocenteModal(BuildContext context, AdminClassModel c) {
    final profController = TextEditingController(text: c.professor);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Alocar Docente: ${c.subjectName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Turma: ${c.code} • ${c.courseAndTerm}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: profController,
              decoration: const InputDecoration(labelText: 'Docente Regente Titular', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (profController.text.isNotEmpty) {
                _controller.reallocateProfessor(c.code, profController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Docente alocado com sucesso! Diário atualizado.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text('Confirmar Alocação'),
          ),
        ],
      ),
    );
  }
}
