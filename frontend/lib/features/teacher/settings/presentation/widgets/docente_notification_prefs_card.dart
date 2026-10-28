// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card para gerenciamento de preferências de canais e categorias de notificações institucionais.
class DocenteNotificationPrefsCard extends StatefulWidget {
  const DocenteNotificationPrefsCard({super.key});

  @override
  State<DocenteNotificationPrefsCard> createState() =>
      _DocenteNotificationPrefsCardState();
}

class _DocenteNotificationPrefsCardState
    extends State<DocenteNotificationPrefsCard> {
  // Notificações - Canais e Categorias
  bool _prazosPortal = true;
  bool _prazosEmail = true;
  String _antecedenciaPrazos = '24 horas antes (1 dia)';

  bool _notasPortal = true;
  bool _notasEmail = true;

  bool _forunsPortal = true;
  bool _forunsEmail = false;

  bool _mensagensPortal = true;
  bool _mensagensEmail = true;

  bool _comunicadosPortal = true;
  bool _comunicadosEmail = true;

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
                'Canais de Comunicação',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escolha onde deseja ser avisado sobre eventos acadêmicos, prazos e notas.',
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
                                  'Notificações instantâneas exibidas no sino superior do seu painel de estudos.',
                                  style: jakarta(
                                    size: 10.5,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
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
                                  'Notificações por E-mail',
                                  style: jakarta(
                                    size: 12.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mensagens enviadas para o seu e-mail institucional e alternativo.',
                                  style: jakarta(
                                    size: 10.5,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Categorias & Frequência de Alertas
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
                'Categorias & Frequência de Alertas',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 18),

              // Item 1: Prazos de Tarefas & Trabalhos
              _buildCategoryRow(
                icon: Icons.send_rounded,
                title: 'Prazos de Tarefas & Trabalhos',
                description:
                    'Lembretes automáticos antes do encerramento do prazo de submissão.',
                portalChecked: _prazosPortal,
                emailChecked: _prazosEmail,
                onPortalChanged: (v) =>
                    setState(() => _prazosPortal = v ?? false),
                onEmailChanged: (v) =>
                    setState(() => _prazosEmail = v ?? false),
                extraWidget: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lembrar-me com antecedência de: ',
                      style: jakarta(size: 11, color: const Color(0xFF71717A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _antecedenciaPrazos,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFF71717A),
                          ),
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w500,
                            color: const Color(0xFF18181B),
                          ),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _antecedenciaPrazos = v);
                            }
                          },
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 28, color: Color(0xFFF4F4F5)),

              // Item 2: Notas & Correções de Professores
              _buildCategoryRow(
                icon: Icons.receipt_long_rounded,
                title: 'Notas & Correções de Professores',
                description:
                    'Aviso imediato assim que uma nota de prova ou trabalho for publicada.',
                portalChecked: _notasPortal,
                emailChecked: _notasEmail,
                onPortalChanged: (v) =>
                    setState(() => _notasPortal = v ?? false),
                onEmailChanged: (v) => setState(() => _notasEmail = v ?? false),
              ),
              const Divider(height: 28, color: Color(0xFFF4F4F5)),

              // Item 3: Fóruns & Respostas
              _buildCategoryRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Fóruns & Respostas',
                description:
                    'Quando alguém responder ou curtir uma mensagem em tópicos que você participa.',
                portalChecked: _forunsPortal,
                emailChecked: _forunsEmail,
                onPortalChanged: (v) =>
                    setState(() => _forunsPortal = v ?? false),
                onEmailChanged: (v) =>
                    setState(() => _forunsEmail = v ?? false),
              ),
              const Divider(height: 28, color: Color(0xFFF4F4F5)),

              // Item 4: Mensagens Diretas & Avisos de Tutores
              _buildCategoryRow(
                icon: Icons.forum_outlined,
                title: 'Mensagens Diretas & Avisos de Tutores',
                description:
                    'Comunicações diretas individuais enviadas por coordenadores e tutores.',
                portalChecked: _mensagensPortal,
                emailChecked: _mensagensEmail,
                onPortalChanged: (v) =>
                    setState(() => _mensagensPortal = v ?? false),
                onEmailChanged: (v) =>
                    setState(() => _mensagensEmail = v ?? false),
              ),
              const Divider(height: 28, color: Color(0xFFF4F4F5)),

              // Item 5: Comunicados Institucionais & Rematrícula
              _buildCategoryRow(
                icon: Icons.campaign_outlined,
                title: 'Comunicados Institucionais & Rematrícula',
                description:
                    'Avisos de feriados, períodos de rematrícula, eventos e manutenções do sistema.',
                portalChecked: _comunicadosPortal,
                emailChecked: _comunicadosEmail,
                onPortalChanged: (v) =>
                    setState(() => _comunicadosPortal = v ?? false),
                onEmailChanged: (v) =>
                    setState(() => _comunicadosEmail = v ?? false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ação de Salvar Preferências
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Preferências de notificação salvas com sucesso!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.check_rounded,
              size: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required String title,
    required String description,
    required bool portalChecked,
    required bool emailChecked,
    required ValueChanged<bool?> onPortalChanged,
    required ValueChanged<bool?> onEmailChanged,
    Widget? extraWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF71717A)),
        const SizedBox(width: 12),
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
              if (extraWidget != null) ...[
                const SizedBox(height: 10),
                extraWidget,
              ],
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: portalChecked,
                    onChanged: onPortalChanged,
                    activeColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'No Portal',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: emailChecked,
                    onChanged: onEmailChanged,
                    activeColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Por E-mail',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
