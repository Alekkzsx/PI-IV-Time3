// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção molecular de categorias e frequência de alertas e notificações.
class NotificationDigestSection extends StatelessWidget {
  final bool prazosPortal;
  final bool prazosEmail;
  final String antecedenciaPrazos;
  final ValueChanged<bool?> onPrazosPortalChanged;
  final ValueChanged<bool?> onPrazosEmailChanged;
  final ValueChanged<String?> onAntecedenciaChanged;

  final bool notasPortal;
  final bool notasEmail;
  final ValueChanged<bool?> onNotasPortalChanged;
  final ValueChanged<bool?> onNotasEmailChanged;

  final bool forunsPortal;
  final bool forunsEmail;
  final ValueChanged<bool?> onForunsPortalChanged;
  final ValueChanged<bool?> onForunsEmailChanged;

  final bool mensagensPortal;
  final bool mensagensEmail;
  final ValueChanged<bool?> onMensagensPortalChanged;
  final ValueChanged<bool?> onMensagensEmailChanged;

  final bool comunicadosPortal;
  final bool comunicadosEmail;
  final ValueChanged<bool?> onComunicadosPortalChanged;
  final ValueChanged<bool?> onComunicadosEmailChanged;

  const NotificationDigestSection({
    super.key,
    required this.prazosPortal,
    required this.prazosEmail,
    required this.antecedenciaPrazos,
    required this.onPrazosPortalChanged,
    required this.onPrazosEmailChanged,
    required this.onAntecedenciaChanged,
    required this.notasPortal,
    required this.notasEmail,
    required this.onNotasPortalChanged,
    required this.onNotasEmailChanged,
    required this.forunsPortal,
    required this.forunsEmail,
    required this.onForunsPortalChanged,
    required this.onForunsEmailChanged,
    required this.mensagensPortal,
    required this.mensagensEmail,
    required this.onMensagensPortalChanged,
    required this.onMensagensEmailChanged,
    required this.comunicadosPortal,
    required this.comunicadosEmail,
    required this.onComunicadosPortalChanged,
    required this.onComunicadosEmailChanged,
  });

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
            portalChecked: prazosPortal,
            emailChecked: prazosEmail,
            onPortalChanged: onPrazosPortalChanged,
            onEmailChanged: onPrazosEmailChanged,
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
                      value: antecedenciaPrazos,
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
                      onChanged: onAntecedenciaChanged,
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
            portalChecked: notasPortal,
            emailChecked: notasEmail,
            onPortalChanged: onNotasPortalChanged,
            onEmailChanged: onNotasEmailChanged,
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),

          // Item 3: Fóruns & Respostas
          _buildCategoryRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Fóruns & Respostas',
            description:
                'Quando alguém responder ou curtir uma mensagem em tópicos que você participa.',
            portalChecked: forunsPortal,
            emailChecked: forunsEmail,
            onPortalChanged: onForunsPortalChanged,
            onEmailChanged: onForunsEmailChanged,
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),

          // Item 4: Mensagens Diretas & Avisos de Tutores
          _buildCategoryRow(
            icon: Icons.forum_outlined,
            title: 'Mensagens Diretas & Avisos de Tutores',
            description:
                'Comunicações diretas individuais enviadas por coordenadores e tutores.',
            portalChecked: mensagensPortal,
            emailChecked: mensagensEmail,
            onPortalChanged: onMensagensPortalChanged,
            onEmailChanged: onMensagensEmailChanged,
          ),
          const Divider(height: 28, color: Color(0xFFF4F4F5)),

          // Item 5: Comunicados Institucionais & Rematrícula
          _buildCategoryRow(
            icon: Icons.campaign_outlined,
            title: 'Comunicados Institucionais & Rematrícula',
            description:
                'Avisos de feriados, períodos de rematrícula, eventos e manutenções do sistema.',
            portalChecked: comunicadosPortal,
            emailChecked: comunicadosEmail,
            onPortalChanged: onComunicadosPortalChanged,
            onEmailChanged: onComunicadosEmailChanged,
          ),
        ],
      ),
    );
  }
}
