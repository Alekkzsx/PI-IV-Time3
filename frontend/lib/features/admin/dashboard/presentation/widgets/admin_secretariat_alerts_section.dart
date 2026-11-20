// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Seção que exibe os alertas urgentes da Secretaria e avisos de fechamento de período.
class AdminSecretariatAlertsSection extends StatelessWidget {
  const AdminSecretariatAlertsSection({super.key});

  static const _monthsUpper = [
    'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
    'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
  ];

  String _todayLabel() {
    final now = DateTime.now();
    return 'HOJE, ${now.day.toString().padLeft(2, '0')} ${_monthsUpper[now.month - 1]}';
  }

  String _closingStatusText(AdminPortalController portal) {
    if (portal.isRegimentalLockActive) {
      return 'Trava regimental global ativa: pautas docentes em modo leitura.';
    }
    final now = DateTime.now();
    final upcomingClosing = portal.calendarEvents
        .map((e) => MapEntry(e, DateTime.tryParse(e.startsAt)))
        .where((entry) =>
            entry.value != null &&
            !entry.value!.isBefore(DateTime(now.year, now.month, now.day)) &&
            (entry.key.type == 'closing' || entry.key.type == 'deadline'))
        .toList()
      ..sort((a, b) => a.value!.compareTo(b.value!));

    if (upcomingClosing.isEmpty) {
      return 'Sem trava regimental ativa • ${portal.academicThresholds.currentWeekLabel}';
    }
    final next = upcomingClosing.first;
    final days = next.value!.difference(DateTime(now.year, now.month, now.day)).inDays;
    final whenText = days == 0
        ? 'vence hoje'
        : days == 1
            ? 'em 1 dia'
            : 'em $days dias';
    return '${next.key.title} ($whenText)';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminPortalController.instance,
      builder: (context, _) {
        final portal = AdminPortalController.instance;
        final pendingProtocols =
            (portal.dashboard['pendingProtocols'] as num?)?.toInt() ??
            portal.protocols
                .where(
                  (p) =>
                      AdminPortalController.normalizeProtocolStatus(p.status) ==
                      'Aguardando Parecer',
                )
                .length;
        final pendingRectifications =
            (portal.dashboard['pendingRectifications'] as num?)?.toInt() ??
            portal.pendingRectifications.length;
        final pendingTotal = pendingProtocols + pendingRectifications;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Alertas da Secretaria',
              style: jakarta(
                size: 24,
                weight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              _todayLabel(),
              style: jakarta(
                size: 12,
                weight: FontWeight.w700,
                color: const Color(0xFF737373),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: const Color(0xFF1A1A1A)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 22,
                        right: 22,
                        bottom: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE4E4E7),
                                  ),
                                ),
                                child: Text(
                                  'Mesa de Análise',
                                  style: jakarta(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4E4E7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  pendingTotal > 0
                                      ? '• $pendingTotal PENDENTE${pendingTotal == 1 ? '' : 'S'}'
                                      : '• EM DIA',
                                  style: jakarta(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Requerimentos Discentes',
                            style: jakarta(
                              size: 18,
                              weight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.article_outlined,
                                size: 16,
                                color: Color(0xFFA3A3A3),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Atestados médicos, 2ª chamada e horas',
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 13.5,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF737373),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 22,
                      color: Color(0xFF737373),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fechamento do Período',
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _closingStatusText(portal),
                      textAlign: TextAlign.center,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF737373),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
      },
    );
  }
}
