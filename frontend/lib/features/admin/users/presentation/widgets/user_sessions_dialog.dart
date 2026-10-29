// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Diálogo para inspeção e encerramento forçado de sessões ativas do usuário.
class UserSessionsDialog extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTerminateAll;

  const UserSessionsDialog({
    super.key,
    required this.user,
    required this.onTerminateAll,
  });

  static Future<void> show({
    required BuildContext context,
    required AdminUserModel user,
    required VoidCallback onTerminateAll,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) =>
          UserSessionsDialog(user: user, onTerminateAll: onTerminateAll),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSessions = user.activeSessionsCount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessões Ativas & Acesso Remoto',
                        style: jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gerenciamento de dispositivos autenticados de ${user.name}',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de Dispositivos Conectados
            if (hasSessions) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDeviceRow(
                      icon: Icons.computer_rounded,
                      device: 'Navegador Web (Chrome / Linux x86_64)',
                      ip: '177.136.24.10 (São Paulo - SP)',
                      lastActive: 'Sessão ativa agora',
                      isCurrent: true,
                    ),
                    if (user.activeSessionsCount > 1) ...[
                      const Divider(height: 18, color: Color(0xFFE2E8F0)),
                      _buildDeviceRow(
                        icon: Icons.phone_android_rounded,
                        device: 'AVA Mobile App (Android 14)',
                        ip: '189.40.112.5 (Rede Móvel 5G)',
                        lastActive: 'Última sincronização há 42 min',
                        isCurrent: false,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O encerramento forçado invalida tokens JWT e cookies de sessão imediatamente.',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 36,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma sessão ativa no momento',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Todos os dispositivos foram deslogados com sucesso.',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF71717A),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Fechar',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                ),
                if (hasSessions) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onTerminateAll();
                    },
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 16,
                    ),
                    label: Text(
                      'Encerrar Todas as Sessões',
                      style: jakarta(size: 13, weight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow({
    required IconData icon,
    required String device,
    required String ip,
    required String lastActive,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF334155)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    device,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEF7EC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Atual',
                        style: jakarta(
                          size: 10,
                          weight: FontWeight.w700,
                          color: const Color(0xFF03543F),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'IP: $ip • $lastActive',
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
