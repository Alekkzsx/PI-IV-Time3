// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/controllers/docente_controller.dart';
import '../../../../shared/domain/models/docente_profile.dart';

/// Card molecular para listagem e revogação de sessões ativas e dispositivos conectados.
class ActiveSessionsListView extends StatelessWidget {
  final DocenteController controller;
  final DocenteProfile profile;

  const ActiveSessionsListView({
    super.key,
    required this.controller,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: Color(0xFF18181B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sessões Ativas & Dispositivos Conectados',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => controller.disconnectOtherSessions(),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 12,
                  color: Color(0xFFDC2626),
                ),
                label: Text(
                  'Encerrar Outras Sessões',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dispositivos com acesso autorizado à sua conta no AVA e Portal do Aluno.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: controller.securitySessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('Falha ao carregar sessões: ${snapshot.error}');
              }
              final sessions = snapshot.data ?? const [];
              if (sessions.isEmpty) return const Text('Nenhuma sessão ativa.');
              return Column(
                children: sessions.map((session) {
                  final id = session['id']?.toString() ?? '';
                  final current = session['isCurrent'] == true;
                  final device =
                      session['device']?.toString() ?? 'Dispositivo';
                  final location = session['location']?.toString() ?? '';
                  final ip = session['ip']?.toString() ?? '';
                  final lastActive =
                      session['lastActive']?.toString() ??
                      session['lastSeenAt']?.toString() ??
                      '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.devices_outlined),
                    title: Text(current ? '$device · Esta sessão' : device),
                    subtitle: Text('$location · $ip · $lastActive'),
                    trailing: current
                        ? null
                        : IconButton(
                            tooltip: 'Revogar sessão',
                            onPressed: () => controller.disconnectSession(id),
                            icon: const Icon(Icons.logout),
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
