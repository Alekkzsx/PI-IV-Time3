// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';

/// Modal dialog para rastrear confirmação de ciência discente com lista detalhada.
class ScienceTrackingDialog extends StatelessWidget {
  final AcademicNotice notice;
  final List<AttendanceStudent> attendanceList;

  const ScienceTrackingDialog({
    super.key,
    required this.notice,
    required this.attendanceList,
  });

  static void show(
    BuildContext context, {
    required AcademicNotice notice,
    required List<AttendanceStudent> attendanceList,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) =>
          ScienceTrackingDialog(notice: notice, attendanceList: attendanceList),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rastreamento de Ciência Obrigatória',
                  style: jakarta(size: 16, weight: FontWeight.w700),
                ),
                Text(
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(size: 12, color: const Color(0xFF71717A)),
                ),
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
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notice.readCount} de ${notice.totalRecipients} confirmaram ciência',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                  Text(
                    '${(notice.sciencePercentage * 100).toInt()}%',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estudantes com Ciência Confirmada:',
              style: jakarta(size: 12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: attendanceList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final st = attendanceList[idx];
                  final hasRead = idx < notice.readCount;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      hasRead
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: hasRead
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFA1A1AA),
                      size: 18,
                    ),
                    title: Text(
                      st.name,
                      style: jakarta(size: 13, weight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'RA: ${st.ra}',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    trailing: Text(
                      hasRead ? 'Ciência registrada' : 'Pendente de leitura',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: hasRead
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
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
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
