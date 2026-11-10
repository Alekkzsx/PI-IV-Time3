// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/controllers/docente_controller.dart';

/// Card atômico com histórico recente de logs de acesso e auditoria de segurança.
class SecurityAuditLogsViewer extends StatelessWidget {
  final DocenteController controller;

  const SecurityAuditLogsViewer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico recente de acesso',
            style: jakarta(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.securityLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Falha ao carregar o histórico: ${snapshot.error}');
              }
              final logs = snapshot.data ?? const [];
              if (logs.isEmpty) return const Text('Nenhum acesso registrado.');
              return Column(
                children: logs.map((log) {
                  final time = log['createdAt'] ??
                      log['timestamp'] ??
                      log['date'] ??
                      '';
                  final action = log['action'] ??
                      log['event'] ??
                      log['status'] ??
                      'Acesso';
                  final device = log['device'] ?? log['userAgent'] ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(action.toString()),
                    subtitle: Text(
                      '$time${device.toString().isEmpty ? '' : ' · $device'}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
