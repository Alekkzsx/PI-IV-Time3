// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Card de configurações de 2FA, gerenciamento de sessões ativas e histórico de auditoria.
class DocenteSecuritySessionsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteSecuritySessionsCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;

    return Column(
      children: [
        // 2FA Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (profile.twoFactorEnabled
                          ? DocenteColors.emerald
                          : DocenteColors.crimson)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  profile.twoFactorEnabled
                      ? Icons.security_rounded
                      : Icons.gpp_maybe_rounded,
                  color: profile.twoFactorEnabled
                      ? DocenteColors.emerald
                      : DocenteColors.crimson,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Autenticação em Dois Fatores (2FA)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DocenteColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (profile.twoFactorEnabled
                                    ? DocenteColors.emerald
                                    : DocenteColors.crimson)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            profile.twoFactorEnabled
                                ? 'Ativo (App Autenticador)'
                                : 'Desativado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: profile.twoFactorEnabled
                                  ? DocenteColors.emerald
                                  : DocenteColors.crimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A autenticação em dois fatores protege seu lançamento de notas oficiais e dados sensíveis dos discentes exigindo um código TOTP a cada login.',
                      style: TextStyle(
                        fontSize: 13,
                        color: DocenteColors.slate,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  controller.toggleTwoFactor();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.profile.twoFactorEnabled
                            ? 'Autenticação 2FA ativada com sucesso!'
                            : 'Autenticação 2FA desativada temporariamente.',
                      ),
                      backgroundColor: DocenteColors.charcoal,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.charcoal,
                  side: const BorderSide(color: DocenteColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  profile.twoFactorEnabled ? 'Desativar 2FA' : 'Configurar 2FA',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active Sessions Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sessões Ativas Conectadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dispositivos atualmente autenticados no Portal do Docente',
                style: TextStyle(fontSize: 13, color: DocenteColors.slate),
              ),
              const SizedBox(height: 16),
              ...profile.activeSessions.map((session) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DocenteColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DocenteColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        session.device.toLowerCase().contains('phone')
                            ? Icons.phone_iphone
                            : Icons.laptop_mac,
                        color: DocenteColors.charcoal,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  session.device,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (session.isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DocenteColors.emerald
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Esta Sessão (Atual)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: DocenteColors.emerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'IP: ${session.ip} • ${session.location} • ${session.lastActive}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: DocenteColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!session.isCurrent)
                        TextButton(
                          onPressed: () {
                            controller.disconnectSession(session.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sessão encerrada com sucesso.'),
                                backgroundColor: DocenteColors.charcoal,
                              ),
                            );
                          },
                          child: const Text(
                            'Desconectar',
                            style: TextStyle(
                              color: DocenteColors.crimson,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audit Trail Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DocenteColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Histórico de Auditoria & Logins Recentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Registro auditável de tentativas de autenticação para conformidade institucional',
                style: TextStyle(fontSize: 13, color: DocenteColors.slate),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(DocenteColors.offWhite),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Data / Hora',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Dispositivo / Navegador',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Endereço IP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Localização',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    rows: profile.loginAudits.map((audit) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              audit.timestamp,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              audit.device,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              audit.ip,
                              style: const TextStyle(
                                fontSize: 12,
                                color: DocenteColors.slate,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              audit.location,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (audit.success
                                        ? DocenteColors.emerald
                                        : DocenteColors.crimson)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                audit.success ? 'Sucesso' : 'Bloqueado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: audit.success
                                      ? DocenteColors.emerald
                                      : DocenteColors.crimson,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

