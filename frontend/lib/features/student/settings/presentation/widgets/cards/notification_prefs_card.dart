// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/settings_common_widgets.dart';

/// [NotificationPrefsCard]
///
/// Componente de gestão granular de preferências de notificação acadêmica.
/// Permite ao discente habilitar ou desabilitar alertas por canais (Portal, E-mail)
/// para notas homologadas, prazos de entrega com antecedência configurável, fóruns e comunicados urgentes.
class NotificationPrefsCard extends StatefulWidget {
  /// Controlador reativo com o estado centralizado do portal.
  final StudentPortalController controller;

  /// Cria uma nova instância de [NotificationPrefsCard].
  const NotificationPrefsCard({super.key, required this.controller});

  @override
  State<NotificationPrefsCard> createState() =>
      _StudentNotificationPrefsCardState();
}

class _StudentNotificationPrefsCardState
    extends State<NotificationPrefsCard> {
  // Notificações - Categorias específicas
  bool _notasPortal = true;
  bool _notasEmail = true;

  bool _prazosPortal = true;
  bool _prazosEmail = true;
  String _antecedenciaPrazos = '48 horas antes (2 dias)';

  bool _forumPortal = true;
  bool _forumEmail = false;

  bool _secretariaPortal = true;
  bool _secretariaEmail = true;

  bool _avisosUrgentes = true;
  final AuthProfileRemoteDataSource _remote = AuthProfileRemoteDataSource();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final saved = AppUserSession.instance.preferences['notifications'];
    if (saved is Map) {
      _notasPortal = saved['notasPortal'] == true;
      _notasEmail = saved['notasEmail'] == true;
      _prazosPortal = saved['prazosPortal'] == true;
      _prazosEmail = saved['prazosEmail'] == true;
      _antecedenciaPrazos =
          saved['antecedenciaPrazos']?.toString() ?? _antecedenciaPrazos;
      _forumPortal = saved['forumPortal'] == true;
      _forumEmail = saved['forumEmail'] == true;
      _secretariaPortal = saved['secretariaPortal'] == true;
      _secretariaEmail = saved['secretariaEmail'] == true;
      _avisosUrgentes = saved['avisosUrgentes'] == true;
    } else {
      _notasPortal = false;
      _notasEmail = false;
      _prazosPortal = false;
      _prazosEmail = false;
      _forumPortal = false;
      _forumEmail = false;
      _secretariaPortal = false;
      _secretariaEmail = false;
      _avisosUrgentes = false;
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final preferences =
        Map<String, dynamic>.from(AppUserSession.instance.preferences)
          ..['notifications'] = {
            'notasPortal': _notasPortal,
            'notasEmail': _notasEmail,
            'prazosPortal': _prazosPortal,
            'prazosEmail': _prazosEmail,
            'antecedenciaPrazos': _antecedenciaPrazos,
            'forumPortal': _forumPortal,
            'forumEmail': _forumEmail,
            'secretariaPortal': _secretariaPortal,
            'secretariaEmail': _secretariaEmail,
            'avisosUrgentes': _avisosUrgentes,
          };
    try {
      await _remote.updateProfile({'preferences': preferences});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências de notificação salvas.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Canais de Comunicação
        SettingsSectionCard(
          icon: Icons.notifications_active_outlined,
          title: 'Canais de Comunicação Principais',
          subtitle:
              'Escolha por onde deseja ser avisado sobre prazos de entrega, notas lançadas e requerimentos.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final portalCard = _buildChannelTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'Alertas no Portal (AVA)',
                    subtitle: 'Sino superior e popups no painel.',
                    value: widget.controller.pushNotifications,
                    onChanged: (val) => setState(
                      () => widget.controller.pushNotifications = val,
                    ),
                  );
                  final emailCard = _buildChannelTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'E-mail Institucional',
                    subtitle: 'Envio no @aluno.universidade.edu.br.',
                    value: widget.controller.emailNotifications,
                    onChanged: (val) => setState(
                      () => widget.controller.emailNotifications = val,
                    ),
                  );

                  if (constraints.maxWidth < 620) {
                    return Column(
                      children: [
                        portalCard,
                        const SizedBox(height: 12),
                        emailCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: portalCard),
                      const SizedBox(width: 14),
                      Expanded(child: emailCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _buildChannelTile(
                icon: Icons.sms_outlined,
                title: 'Alertas Críticos via SMS',
                subtitle:
                    'Avisos de alterações emergenciais de sala ou suspensões de aula no seu celular cadastrado.',
                value: widget.controller.smsNotifications,
                onChanged: (val) =>
                    setState(() => widget.controller.smsNotifications = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Notificações por Categoria Acadêmica
        SettingsSectionCard(
          icon: Icons.tune_rounded,
          title: 'Categorias de Eventos Acadêmicos',
          subtitle:
              'Personalize o comportamento de cada tipo de alerta gerado pelos docentes e pela secretaria.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Categoria 1: Notas e Faltas Lançadas
              _buildCategoryRow(
                icon: Icons.grade_outlined,
                title: 'Lançamento de Notas e Faltas',
                description:
                    'Receber aviso instantâneo quando o professor publicar avaliações (P1, P2, Sub) ou frequência.',
                portalVal: _notasPortal,
                emailVal: _notasEmail,
                onPortalChanged: (v) => setState(() => _notasPortal = v),
                onEmailChanged: (v) => setState(() => _notasEmail = v),
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Categoria 2: Prazos e Entregas de Atividades
              _buildCategoryRow(
                icon: Icons.assignment_outlined,
                title: 'Prazos de Entregas & Trabalhos',
                description:
                    'Avisos preventivos sobre trabalhos, relatórios de laboratório e projetos com data limite próxima.',
                portalVal: _prazosPortal,
                emailVal: _prazosEmail,
                onPortalChanged: (v) => setState(() => _prazosPortal = v),
                onEmailChanged: (v) => setState(() => _prazosEmail = v),
                extraWidget: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Antecedência do lembrete: ',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _antecedenciaPrazos,
                        isDense: true,
                        underline: const SizedBox(),
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '12 horas antes',
                            child: Text('12 horas antes'),
                          ),
                          DropdownMenuItem(
                            value: '24 horas antes (1 dia)',
                            child: Text('24 horas antes (1 dia)'),
                          ),
                          DropdownMenuItem(
                            value: '48 horas antes (2 dias)',
                            child: Text('48 horas antes (2 dias)'),
                          ),
                          DropdownMenuItem(
                            value: '72 horas antes (3 dias)',
                            child: Text('72 horas antes (3 dias)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _antecedenciaPrazos = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Categoria 3: Fóruns e Monitoria
              _buildCategoryRow(
                icon: Icons.forum_outlined,
                title: 'Respostas em Fóruns & Dúvidas',
                description:
                    'Avisar quando seu professor ou monitor responder a um tópico aberto por você no AVA.',
                portalVal: _forumPortal,
                emailVal: _forumEmail,
                onPortalChanged: (v) => setState(() => _forumPortal = v),
                onEmailChanged: (v) => setState(() => _forumEmail = v),
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Categoria 4: Secretaria Geral & Protocolos
              _buildCategoryRow(
                icon: Icons.account_balance_outlined,
                title: 'Despachos da Secretaria Geral',
                description:
                    'Tramitação de requerimentos, parecer de dispensa de disciplina e declarações de matrícula prontas.',
                portalVal: _secretariaPortal,
                emailVal: _secretariaEmail,
                onPortalChanged: (v) => setState(() => _secretariaPortal = v),
                onEmailChanged: (v) => setState(() => _secretariaEmail = v),
              ),
              const Divider(height: 32, color: Color(0xFFF4F4F5)),

              // Categoria 5: Avisos da Reitoria
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      size: 18,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comunicados Oficiais da Reitoria / DTI',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manutenções programadas de sistema e avisos institucionais de alta relevância.',
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _avisosUrgentes,
                    onChanged: (v) => setState(() => _avisosUrgentes = v),
                    activeTrackColor: const Color(0xFF16A34A),
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botão de Salvar Preferências
              SettingsSaveButton(
                label: 'Salvar Preferências de Notificação',
                onPressed: _isSaving ? null : _savePreferences,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: jakarta(
                    size: 10.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF16A34A),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required String title,
    required String description,
    required bool portalVal,
    required bool emailVal,
    required ValueChanged<bool> onPortalChanged,
    required ValueChanged<bool> onEmailChanged,
    Widget? extraWidget,
  }) {
    final switches = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            Text(
              'Portal',
              style: jakarta(
                size: 10,
                weight: FontWeight.w500,
                color: const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 2),
            Switch(
              value: portalVal,
              onChanged: onPortalChanged,
              activeTrackColor: const Color(0xFF16A34A),
              activeThumbColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(
              'E-mail',
              style: jakarta(
                size: 10,
                weight: FontWeight.w500,
                color: const Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 2),
            Switch(
              value: emailVal,
              onChanged: onEmailChanged,
              activeTrackColor: const Color(0xFF16A34A),
              activeThumbColor: Colors.white,
            ),
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        final headerRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF18181B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: jakarta(size: 11, color: const Color(0xFF71717A)),
                  ),
                  if (extraWidget != null) extraWidget,
                ],
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 16),
              switches,
            ],
          ],
        );

        if (!isNarrow) return headerRow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerRow,
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: switches),
          ],
        );
      },
    );
  }
}


typedef StudentNotificationPrefsCard = NotificationPrefsCard;
