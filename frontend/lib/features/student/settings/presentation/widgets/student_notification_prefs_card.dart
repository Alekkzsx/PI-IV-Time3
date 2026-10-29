// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Card para gerenciamento de preferências de canais e categorias de notificações discentes.
class StudentNotificationPrefsCard extends StatefulWidget {
  final StudentPortalController controller;

  const StudentNotificationPrefsCard({super.key, required this.controller});

  @override
  State<StudentNotificationPrefsCard> createState() =>
      _StudentNotificationPrefsCardState();
}

class _StudentNotificationPrefsCardState
    extends State<StudentNotificationPrefsCard> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Canais de Comunicação
        Container(
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
              Text(
                'Canais de Comunicação Principais',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha por onde deseja ser avisado sobre prazos de entrega, notas lançadas e requerimentos.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alertas no Portal (AVA)',
                                  style: jakarta(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sino superior e popups no painel.',
                                  style: jakarta(
                                    size: 10.5,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: widget.controller.pushNotifications,
                            onChanged: (val) => setState(
                              () => widget.controller.pushNotifications = val,
                            ),
                            activeTrackColor: const Color(0xFF16A34A),
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
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
                            child: const Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'E-mail Institucional',
                                  style: jakarta(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Envio no @aluno.universidade.edu.br.',
                                  style: jakarta(
                                    size: 10.5,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: widget.controller.emailNotifications,
                            onChanged: (val) => setState(
                              () => widget.controller.emailNotifications = val,
                            ),
                            activeTrackColor: const Color(0xFF16A34A),
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
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
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alertas Críticos via SMS',
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Avisos de alterações emergenciais de sala ou suspensões de aula no seu celular cadastrado.',
                            style: jakarta(
                              size: 10.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.controller.smsNotifications,
                      onChanged: (val) => setState(
                        () => widget.controller.smsNotifications = val,
                      ),
                      activeTrackColor: const Color(0xFF16A34A),
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Notificações por Categoria Acadêmica
        Container(
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
              Text(
                'Categorias de Eventos Acadêmicos',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize o comportamento de cada tipo de alerta gerado pelos docentes e pela secretaria.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const SizedBox(height: 20),

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
                  child: Row(
                    children: [
                      Text(
                        'Antecedência do lembrete: ',
                        style: jakarta(
                          size: 11,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 8),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Preferências de notificação salvas com sucesso!',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Salvar Preferências de Notificação',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    return Row(
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
        const SizedBox(width: 16),
        Row(
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
        ),
      ],
    );
  }
}
