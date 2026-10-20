// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';
import '../widgets/create_notice_modal.dart';

/// Tab page for managing official institutional announcements and tracking student read receipts.
class DocenteMessagesTab extends StatefulWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteMessagesTab({
    super.key,
    required this.controller,
  });

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

  void _openScienceTrackingDialog(AcademicNotice notice) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: DocenteColors.emerald),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rastreamento de Ciência Obrigatória', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(notice.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: DocenteColors.slate)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DocenteColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DocenteColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${notice.readCount} de ${notice.totalRecipients} confirmaram ciência',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${(notice.sciencePercentage * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: DocenteColors.emerald),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Estudantes com Ciência Confirmada:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: widget.controller.currentSession.attendanceList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final st = widget.controller.currentSession.attendanceList[idx];
                      final hasRead = idx < notice.readCount;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          hasRead ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: hasRead ? DocenteColors.emerald : DocenteColors.muted,
                          size: 18,
                        ),
                        title: Text(st.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('RA: ${st.ra}', style: const TextStyle(fontSize: 11, color: DocenteColors.slate)),
                        trailing: Text(
                          hasRead ? 'Ciência registrada' : 'Pendente de leitura',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: hasRead ? DocenteColors.emerald : DocenteColors.crimson,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notices = widget.controller.notices.where((n) {
      if (_filter == 'meus') return !n.isFromSecretaria;
      if (_filter == 'secretaria') return n.isFromSecretaria;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildFilterTabs(),
          const SizedBox(height: 20),
          ...notices.map((notice) => _buildNoticeCard(notice)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Central de Comunicados & Avisos Acadêmicos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DocenteColors.charcoal,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Transmissão para turmas, coordenação e rastreamento de ciência obrigatória',
              style: TextStyle(
                fontSize: 14,
                color: DocenteColors.slate,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openCreateNoticeModal,
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Novo Comunicado',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DocenteColors.charcoal,
            foregroundColor: DocenteColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DocenteColors.charcoal : DocenteColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? DocenteColors.charcoal : DocenteColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? DocenteColors.white : DocenteColors.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(AcademicNotice notice) {
    Color classColor;
    String classLabel;

    switch (notice.classification) {
      case NoticeClassification.informativo:
        classColor = const Color(0xFF2563EB); // Blue
        classLabel = 'Informativo';
        break;
      case NoticeClassification.urgencia:
        classColor = DocenteColors.amber;
        classLabel = 'Urgência';
        break;
      case NoticeClassification.convocacao:
        classColor = DocenteColors.crimson;
        classLabel = 'Convocação';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: classColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      classLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: classColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${notice.author} • ${notice.publishedAt}',
                    style: const TextStyle(fontSize: 12, color: DocenteColors.slate, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Text(
                  'Turma: ${notice.targetCourse} • ${notice.targetAudience}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DocenteColors.charcoal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notice.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DocenteColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notice.message,
            style: const TextStyle(
              fontSize: 13,
              color: DocenteColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: DocenteColors.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${notice.readCount} de ${notice.totalRecipients} estudantes confirmaram ciência',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DocenteColors.charcoal),
                        ),
                        Text(
                          '${(notice.sciencePercentage * 100).toInt()}% de ciência',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DocenteColors.emerald),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: notice.sciencePercentage,
                        backgroundColor: DocenteColors.offWhite,
                        color: DocenteColors.emerald,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: () => _openScienceTrackingDialog(notice),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: const Text('Rastrear Ciência', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.charcoal,
                  side: const BorderSide(color: DocenteColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

