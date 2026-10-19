// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';

/// Aba de configuração de Alertas do Campus e Canais de Comunicação.
///
/// Permite definir regras de disparo de notificações push no portal, e-mails institucionais,
/// prazos de tarefas e avisos de tutores/professores.
class CampusAlertsTab extends StatefulWidget {
  const CampusAlertsTab({super.key});

  @override
  State<CampusAlertsTab> createState() => _CampusAlertsTabState();
}

class _CampusAlertsTabState extends State<CampusAlertsTab> {
  String _selectedLeadTime = '24 horas antes (1 dia)';
  bool _portalTasks = true;
  bool _emailTasks = true;

  bool _portalGrades = true;
  bool _emailGrades = true;

  bool _portalForums = true;
  bool _emailForums = false;

  bool _portalMessages = true;
  bool _emailMessages = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Canais de Comunicação
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Canais de Comunicação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Escolha onde deseja ser avisado sobre eventos acadêmicos, prazos e notas.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  return isNarrow
                      ? Column(
                          children: [
                            _buildChannelCard(
                              icon: Icons.notifications_active_rounded,
                              title: 'Alertas no Portal (AVA)',
                              description: 'Notificações instantâneas exibidas no sino superior do seu painel de estudos.',
                            ),
                            const SizedBox(height: 14),
                            _buildChannelCard(
                              icon: Icons.mail_rounded,
                              title: 'Notificações por E-mail',
                              description: 'Mensagens enviadas para o seu e-mail institucional e alternativo.',
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildChannelCard(
                                icon: Icons.notifications_active_rounded,
                                title: 'Alertas no Portal (AVA)',
                                description:
                                    'Notificações instantâneas exibidas no sino superior do seu painel de estudos.',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildChannelCard(
                                icon: Icons.mail_rounded,
                                title: 'Notificações por E-mail',
                                description:
                                    'Mensagens enviadas para o seu e-mail institucional e alternativo.',
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Categorias & Frequência de Alertas
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categorias & Frequência de Alertas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              // Item 1: Prazos de Tarefas & Trabalhos
              _buildAlertRow(
                icon: Icons.near_me_outlined,
                title: 'Prazos de Tarefas & Trabalhos',
                description: 'Lembretes automáticos antes do encerramento do prazo de submissão.',
                customLeadTime: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Lembrar-me com antecedência de:',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLeadTime,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '24 horas antes (1 dia)',
                              child: Text('24 horas antes (1 dia)'),
                            ),
                            DropdownMenuItem(
                              value: '48 horas antes (2 dias)',
                              child: Text('48 horas antes (2 dias)'),
                            ),
                            DropdownMenuItem(
                              value: '6 horas antes',
                              child: Text('6 horas antes'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLeadTime = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                portalVal: _portalTasks,
                emailVal: _emailTasks,
                onPortalChanged: (val) => setState(() => _portalTasks = val ?? false),
                onEmailChanged: (val) => setState(() => _emailTasks = val ?? false),
              ),

              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Item 2: Notas & Correções de Professores
              _buildAlertRow(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Notas & Correções de Professores',
                description: 'Aviso imediato assim que uma nota de prova ou trabalho for publicada.',
                portalVal: _portalGrades,
                emailVal: _emailGrades,
                onPortalChanged: (val) => setState(() => _portalGrades = val ?? false),
                onEmailChanged: (val) => setState(() => _emailGrades = val ?? false),
              ),

              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Item 3: Fóruns & Respostas
              _buildAlertRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Fóruns & Respostas',
                description: 'Quando alguém responder ou curtir uma mensagem em tópicos que você participa.',
                portalVal: _portalForums,
                emailVal: _emailForums,
                onPortalChanged: (val) => setState(() => _portalForums = val ?? false),
                onEmailChanged: (val) => setState(() => _emailForums = val ?? false),
              ),

              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Item 4: Mensagens Diretas & Avisos de Tutores
              _buildAlertRow(
                icon: Icons.message_outlined,
                title: 'Mensagens Diretas & Avisos de Tutores',
                description: 'Comunicações diretas individuais enviadas por coordenadores e tutores.',
                portalVal: _portalMessages,
                emailVal: _emailMessages,
                onPortalChanged: (val) => setState(() => _portalMessages = val ?? false),
                onEmailChanged: (val) => setState(() => _emailMessages = val ?? false),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow({
    required IconData icon,
    required String title,
    required String description,
    Widget? customLeadTime,
    required bool portalVal,
    required bool emailVal,
    required ValueChanged<bool?> onPortalChanged,
    required ValueChanged<bool?> onEmailChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              if (customLeadTime != null) ...[
                const SizedBox(height: 8),
                customLeadTime,
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: portalVal,
              activeColor: const Color(0xFF0F172A),
              onChanged: onPortalChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const Text(
              'No Portal',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
            ),
            const SizedBox(width: 16),
            Checkbox(
              value: emailVal,
              activeColor: const Color(0xFF0F172A),
              onChanged: onEmailChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const Text(
              'Por E-mail',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
            ),
          ],
        ),
      ],
    );
  }
}
