import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';

class ScienceTrackingDialog extends StatefulWidget {
  final AcademicNotice notice;
  final DocenteController controller;

  const ScienceTrackingDialog({
    super.key,
    required this.notice,
    required this.controller,
  });

  static void show(
    BuildContext context, {
    required AcademicNotice notice,
    required DocenteController controller,
  }) {
    showDialog(
      context: context,
      builder: (ctx) =>
          ScienceTrackingDialog(notice: notice, controller: controller),
    );
  }

  @override
  State<ScienceTrackingDialog> createState() => _ScienceTrackingDialogState();
}

class _ScienceTrackingDialogState extends State<ScienceTrackingDialog> {
  late Future<Map<String, dynamic>?> _reads;

  @override
  void initState() {
    super.initState();
    _reads = widget.controller.getNoticeReads(widget.notice.id);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.notice.title),
    content: SizedBox(
      width: 480,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _reads,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Text('Não foi possível carregar as confirmações.');
          }
          final reads = data['reads'] is List
              ? (data['reads'] as List).whereType<Map>().toList()
              : const <Map>[];
          final readCount = data['readCount'] is num
              ? (data['readCount'] as num).toInt()
              : 0;
          final total = data['totalRecipients'] is num
              ? (data['totalRecipients'] as num).toInt()
              : 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$readCount de $total estudantes confirmaram ciência'),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: reads.isEmpty
                    ? const Center(
                        child: Text('Nenhuma confirmação registrada.'),
                      )
                    : ListView.separated(
                        itemCount: reads.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = reads[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text(
                              entry['displayName']?.toString() ??
                                  entry['identity']?.toString() ??
                                  'Discente',
                            ),
                            subtitle: Text(entry['identity']?.toString() ?? ''),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
    ],
  );
}
