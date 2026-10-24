// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/create_notice_modal.dart';
import '../widgets/docente_notice_card.dart';
import '../widgets/science_tracking_dialog.dart';

/// Tab page for managing official institutional announcements and tracking student read receipts.
class DocenteMessagesTab extends StatefulWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteMessagesTab({super.key, required this.controller});

  @override
  State<DocenteMessagesTab> createState() => _DocenteMessagesTabState();
}

class _DocenteMessagesTabState extends State<DocenteMessagesTab> {
  String _filter = 'todos'; // 'todos', 'meus', 'secretaria'

  void _openCreateNoticeModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => CreateNoticeModal(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final notices = widget.controller.notices.where((n) {
          if (_filter == 'meus') return !n.isFromSecretaria;
          if (_filter == 'secretaria') return n.isFromSecretaria;
          return true;
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildFilterTabs(),
                          const SizedBox(height: 24),
                          ...notices.map(
                            (notice) => DocenteNoticeCard(
                              notice: notice,
                              onTrackScience: () {
                                ScienceTrackingDialog.show(
                                  context,
                                  notice: notice,
                                  attendanceList: widget
                                      .controller
                                      .currentSession
                                      .attendanceList,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const DocenteFooter(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Central de Comunicados & Avisos Acadêmicos',
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transmissão para turmas, coordenação e rastreamento de ciência obrigatória',
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openCreateNoticeModal,
          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          label: Text(
            'Novo Comunicado',
            style: jakarta(
              size: 13,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        _buildFilterButton('todos', 'Todos os Comunicados'),
        const SizedBox(width: 8),
        _buildFilterButton('meus', 'Emitidos por Mim'),
        const SizedBox(width: 8),
        _buildFilterButton('secretaria', 'Secretaria & Coordenação'),
      ],
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _filter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _filter = key),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE4E4E7),
            ),
          ),
          child: Text(
            label,
            style: jakarta(
              size: 12.5,
              weight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF27272A),
            ),
          ),
        ),
      ),
    );
  }
}
