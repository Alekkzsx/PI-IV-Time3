// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/presentation/controllers/admin_portal_controller.dart';

/// Tela do Calendário Acadêmico Oficial e Prazos Regimentais (CONSEPE) na Visão do Administrador.
/// Exibe as janelas de avaliação, controle da trava regimental de diários eletrônicos
/// e cronograma de homologação de pautas.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final AdminPortalController _controller = AdminPortalController.instance;

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
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calendário', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Calendário Acadêmico Oficial & Prazos Regimentais',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Parametrização das janelas de provas, controle das travas regimentais de notas e homologação de semestres.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildConsepeResolutionCard(),
          const SizedBox(height: 24),
          _buildTimelineCard(),
        ],
      ),
    );
  }

  // ==========================================
  // CARD RESOLUÇÃO CONSEPE E TRAVAS
  // ==========================================
  Widget _buildConsepeResolutionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('RESOLUÇÃO CONSEPE 2026/04', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Semestre Letivo 2026/2 • Carga de 100 Dias Letivos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Período: 01 de Agosto de 2026 a 22 de Dezembro de 2026', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _controller.isRegimentalLockActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _controller.isRegimentalLockActive ? Icons.lock : Icons.lock_open,
                  color: _controller.isRegimentalLockActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _controller.isRegimentalLockActive ? 'TRAVA REGIMENTAL ATIVA' : 'DIÁRIOS LIBERADOS',
                  style: TextStyle(
                    color: _controller.isRegimentalLockActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _controller.toggleRegimentalLock,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: BorderSide(color: _controller.isRegimentalLockActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                  ),
                  child: Text(_controller.isRegimentalLockActive ? 'Liberar Diários' : 'Ativar Trava', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TIMELINE DAS JANELAS REGIMENTAIS (Print 56)
  // ==========================================
  Widget _buildTimelineCard() {
    final timelineItems = [
      {'data': '01/08/2026', 'titulo': 'Início Oficial do Semestre Letivo 2026/2', 'desc': 'Abertura de turmas e ensalamento presencial.', 'status': 'Concluído'},
      {'data': '15/10/2026 a 24/10/2026', 'titulo': 'Janela Oficial de Aplicação e Lançamento N1', 'desc': 'Docentes lançam notas de P1 e atividades parciais.', 'status': 'Vigente'},
      {'data': '25/10/2026 23:59', 'titulo': 'Fechamento dos Diários Eletrônicos N1 (Trava Regimental)', 'desc': 'Bloqueio compulsório de edição no portal docente.', 'status': 'Próximo'},
      {'data': '01/12/2026 a 12/12/2026', 'titulo': 'Janela Oficial de Provas e Entregas N2', 'desc': 'Provas integradoras e fechamento de médias.', 'status': 'Agendado'},
      {'data': '15/12/2026 a 19/12/2026', 'titulo': 'Período de Exames Especiais Finais', 'desc': 'Para estudantes com média entre 4.0 e 5.9.', 'status': 'Agendado'},
      {'data': '22/12/2026', 'titulo': 'Emissão e Lacração das Atas Finais', 'desc': 'Homologação final perante o Conselho Universitário.', 'status': 'Agendado'},
    ];

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
          const Text('Cronograma de Prazos Regimentais Homologados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...timelineItems.map((item) {
            final isVigente = item['status'] == 'Vigente';
            final isConcluido = item['status'] == 'Concluído';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isVigente ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['data']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isVigente ? Colors.white : const Color(0xFF334155),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['titulo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(item['desc']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      item['status']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isConcluido ? const Color(0xFF16A34A) : (isVigente ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                      ),
                    ),
                    backgroundColor: isConcluido ? const Color(0xFFDCFCE7) : (isVigente ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
