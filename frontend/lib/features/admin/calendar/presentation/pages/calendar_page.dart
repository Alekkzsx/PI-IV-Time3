// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';

/// Tela do Calendário Acadêmico Oficial e Prazos Regimentais (CONSEPE) na Visão do Administrador.
/// Exibe as janelas de avaliação, controle das travas regimentais de notas e homologação de semestres.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da Página
                      const Text(
                        'Calendário Acadêmico Oficial & Prazos Regimentais',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Parametrização das janelas de provas, controle das travas regimentais de notas e homologação de semestres.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Card Resolução CONSEPE 2026/04
                      _buildConsepeResolutionCard(),
                      const SizedBox(height: 24),

                      // Card Lista de Prazos Regimentais
                      _buildTimelineCard(),
                    ],
                  ),
                ),

                // Rodapé Institucional
                const AdminFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // CARD RESOLUÇÃO CONSEPE 2026/04
  // ==========================================
  Widget _buildConsepeResolutionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'RESOLUÇÃO CONSEPE 2026/04',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF71717A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Semestre Letivo 2026/2 • Carga de 100 Dias Letivos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Semana 10 de 18',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'O regimento acadêmico prevê o bloqueio automatizado do lançamento de notas após o encerramento do prazo regulamentar. Qualquer retificação extemporânea exige protocolo com justificativa homologada pelo colegiado de curso.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF52525B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD TIMELINE DOS PRAZOS REGIMENTAIS
  // ==========================================
  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        children: [
          // Item 1: Período N1
          _buildTimelineRow(
            tag: 'Período N1',
            dateText: '20 de Setembro a 10 de Outubro de 2026',
            title: 'Janela de Avaliações Parciais e Trabalhos Práticos',
            trailing: _buildBadge(
              label: 'Em Andamento',
              textColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFEFF6FF),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),

          // Item 2: Fechamento N1 & Trava Regimental
          _buildTimelineRow(
            tag: 'Fechamento N1',
            dateText: '15 de Outubro de 2026 às 23:59',
            title: 'Prazo Final para Digitação e Homologação de Diários',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _controller.isRegimentalLockActive
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _controller.isRegimentalLockActive
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFE4E4E7),
                    ),
                  ),
                  child: Text(
                    _controller.isRegimentalLockActive
                        ? 'Trava Regimental Ativa'
                        : 'Aberto para Digitação',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _controller.isRegimentalLockActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF27272A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.toggleRegimentalLock();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.isRegimentalLockActive
                              ? 'Trava Regimental ativada. Lançamento e retificação de notas bloqueados.'
                              : 'Trava Regimental liberada. Diários abertos para digitação.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: Icon(
                    _controller.isRegimentalLockActive
                        ? Icons.lock_open
                        : Icons.lock_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: Text(
                    _controller.isRegimentalLockActive
                        ? 'Liberar Diários'
                        : 'Ativar Trava Regimental',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),

          // Item 3: Período N2
          _buildTimelineRow(
            tag: 'Período N2',
            dateText: '20 de Novembro a 05 de Dezembro de 2026',
            title:
                'Janela de Avaliações Finais e Defesa de Projetos Integradores',
            trailing: _buildBadge(
              label: 'Futuro',
              textColor: const Color(0xFF71717A),
              backgroundColor: const Color(0xFFF4F4F5),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),

          // Item 4: Exames Finais
          _buildTimelineRow(
            tag: 'Exames Finais',
            dateText: '10 de Dezembro a 15 de Dezembro de 2026',
            title: 'Semana de Provas Regimentais de Exame Final',
            trailing: _buildBadge(
              label: 'Futuro',
              textColor: const Color(0xFF71717A),
              backgroundColor: const Color(0xFFF4F4F5),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),

          // Item 5: Atas Finais
          _buildTimelineRow(
            tag: 'Atas Finais',
            dateText: '18 de Dezembro de 2026',
            title: 'Emissão, Assinatura Eletrônica e Arquivo Geral das Atas',
            trailing: _buildBadge(
              label: 'Futuro',
              textColor: const Color(0xFF71717A),
              backgroundColor: const Color(0xFFF4F4F5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String tag,
    required String dateText,
    required String title,
    required Widget trailing,
  }) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF52525B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF09090B),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: trailing),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              trailing,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
