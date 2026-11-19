// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../shared/controllers/admin_portal_controller.dart';

/// Aba de configuração para alertas operacionais da gestão administrativa.
class CampusAlertsTab extends StatefulWidget {
  const CampusAlertsTab({super.key});

  @override
  State<CampusAlertsTab> createState() => _CampusAlertsTabState();
}

class _CampusAlertsTabState extends State<CampusAlertsTab> {
  final AdminPortalController _portal = AdminPortalController.instance;

  bool _notifyPendingProtocols = true;
  bool _notifyGradeRectifications = true;
  bool _notifyRegimentalDeadlines = true;
  bool _emailUrgentEscalations = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrateFromSettings(_portal.institutionalSettings);
    _loadSettingsIfNeeded();
  }

  void _hydrateFromSettings(Map<String, dynamic> settings) {
    final raw = settings['campusAlerts'];
    if (raw is! Map) return;
    _notifyPendingProtocols = raw['notifyPendingProtocols'] != false;
    _notifyGradeRectifications = raw['notifyGradeRectifications'] != false;
    _notifyRegimentalDeadlines = raw['notifyRegimentalDeadlines'] != false;
    _emailUrgentEscalations = raw['emailUrgentEscalations'] == true;
  }

  Future<void> _loadSettingsIfNeeded() async {
    if (_portal.institutionalSettings.isNotEmpty ||
        AppUserSession.instance.accessToken == null) {
      return;
    }
    try {
      final settings = await _portal.remote.request('GET', '/settings') as Map;
      if (!mounted) return;
      setState(() {
        _portal.institutionalSettings = Map<String, dynamic>.from(settings);
        _hydrateFromSettings(_portal.institutionalSettings);
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'notifyPendingProtocols': _notifyPendingProtocols,
      'notifyGradeRectifications': _notifyGradeRectifications,
      'notifyRegimentalDeadlines': _notifyRegimentalDeadlines,
      'emailUrgentEscalations': _emailUrgentEscalations,
    };
    final ok = await _portal.updateSettings({'campusAlerts': payload});
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = ok ? null : _portal.remoteError;
    });
    if (ok) {
      _portal.institutionalSettings = {
        ..._portal.institutionalSettings,
        'campusAlerts': payload,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alertas do campus atualizados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: InstColors.dangerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: InstColors.danger.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _error!,
              style: jakarta(size: 13, color: InstColors.danger),
            ),
          ),

        // 1. Canais de Alerta da Gestão
        Container(
          decoration: BoxDecoration(
            color: InstColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: InstColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canais de Monitoramento Institucional',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Defina quais pendências operacionais disparam alertas no sino da gestão e escalonamento por e-mail.',
                style: jakarta(size: 12.5, color: InstColors.muted),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final portalCard = _buildChannelCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Central do Portal Gestão',
                    description:
                        'Sinalizações exibidas em tempo real no sino superior e no Painel Geral.',
                  );
                  final emailCard = _buildChannelCard(
                    icon: Icons.mail_outline_rounded,
                    title: 'Escalonamento para Secretaria',
                    description:
                        'Alertas críticos encaminhados por e-mail quando houver retenções ou pendências.',
                  );
                  return isNarrow
                      ? Column(
                          children: [
                            portalCard,
                            const SizedBox(height: 14),
                            emailCard,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: portalCard),
                            const SizedBox(width: 16),
                            Expanded(child: emailCard),
                          ],
                        );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Gatilhos Operacionais
        Container(
          decoration: BoxDecoration(
            color: InstColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: InstColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gatilhos Operacionais do Campus',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estas preferências controlam os alertas exibidos para a equipe administrativa.',
                style: jakarta(size: 12.5, color: InstColors.muted),
              ),
              const SizedBox(height: 20),
              _buildToggleRow(
                icon: Icons.inbox_outlined,
                title: 'Protocolos & Requerimentos Pendentes',
                description:
                    'Exibe alertas quando há solicitações discentes aguardando parecer na Secretaria.',
                value: _notifyPendingProtocols,
                onChanged: (val) =>
                    setState(() => _notifyPendingProtocols = val),
              ),
              const Divider(height: 28, color: InstColors.border),
              _buildToggleRow(
                icon: Icons.rule_folder_outlined,
                title: 'Solicitações de Retificação Pós-Trava',
                description:
                    'Sinaliza pedidos docentes de alteração de nota ou destravamento de pauta.',
                value: _notifyGradeRectifications,
                onChanged: (val) =>
                    setState(() => _notifyGradeRectifications = val),
              ),
              const Divider(height: 28, color: InstColors.border),
              _buildToggleRow(
                icon: Icons.event_available_outlined,
                title: 'Marcos e Prazos Regimentais',
                description:
                    'Destaca marcos do Calendário Acadêmico e janelas próximas de fechamento semestral.',
                value: _notifyRegimentalDeadlines,
                onChanged: (val) =>
                    setState(() => _notifyRegimentalDeadlines = val),
              ),
              const Divider(height: 28, color: InstColors.border),
              _buildToggleRow(
                icon: Icons.mark_email_unread_outlined,
                title: 'Escalonamento Crítico por E-mail',
                description:
                    'Envia resumo prioritário por e-mail em caso de acúmulo de retificações ou fechamento.',
                value: _emailUrgentEscalations,
                onChanged: (val) =>
                    setState(() => _emailUrgentEscalations = val),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InstColors.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Salvando...' : 'Salvar Alertas do Campus',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: InstColors.stone,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: InstColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: jakarta(
                    size: 11.5,
                    color: InstColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: InstColors.stoneActive,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: InstColors.ink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: jakarta(size: 11.5, color: InstColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeThumbColor: InstColors.ink,
          activeTrackColor: InstColors.stoneActive,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
