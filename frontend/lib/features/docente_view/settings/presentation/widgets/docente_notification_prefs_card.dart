// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Card para gerenciamento de preferências de notificação, visualização e conformidade LGPD.
class DocenteNotificationPrefsCard extends StatefulWidget {
  final String activeSubtab;

  const DocenteNotificationPrefsCard({
    super.key,
    required this.activeSubtab,
  });

  @override
  State<DocenteNotificationPrefsCard> createState() =>
      _DocenteNotificationPrefsCardState();
}

class _DocenteNotificationPrefsCardState
    extends State<DocenteNotificationPrefsCard> {
  bool _notifySubmissions = true;
  bool _notifyMecDeadlines = true;
  bool _notifyAttendanceRisk = true;
  bool _notifyPush = false;

  @override
  Widget build(BuildContext context) {
    switch (widget.activeSubtab) {
      case 'notificacoes':
        return _buildNotificationsTab();
      case 'preferencias':
        return _buildPreferencesTab();
      case 'privacidade':
        return _buildPrivacyTab();
      default:
        return _buildNotificationsTab();
    }
  }

  Widget _buildNotificationsTab() {
    return Container(
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
            'Preferências de Comunicação & Notificações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DocenteColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Notificações de Novas Entregas de Alunos por E-mail',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Receba um aviso assim que um aluno enviar uma atividade ou projeto no AVA',
              style: TextStyle(fontSize: 12, color: DocenteColors.slate),
            ),
            value: _notifySubmissions,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifySubmissions = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text(
              'Avisos de Prazo de Homologação de Diário MEC',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Lembretes automáticos 48h antes do encerramento quinzenal do lançamento de faltas',
              style: TextStyle(fontSize: 12, color: DocenteColors.slate),
            ),
            value: _notifyMecDeadlines,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyMecDeadlines = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text(
              'Alertas de Discentes em Risco de Frequência (< 75%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Alerta imediato quando um estudante atinge 20% de faltas acumuladas na disciplina',
              style: TextStyle(fontSize: 12, color: DocenteColors.slate),
            ),
            value: _notifyAttendanceRisk,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyAttendanceRisk = v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text(
              'Notificações Push no Dispositivo Móvel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Alertas instantâneos de mensagens urgentes da coordenação do curso',
              style: TextStyle(fontSize: 12, color: DocenteColors.slate),
            ),
            value: _notifyPush,
            activeColor: DocenteColors.emerald,
            onChanged: (v) => setState(() => _notifyPush = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Container(
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
            'Preferências do Sistema & Interface',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DocenteColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            'Densidade Visual das Tabelas',
            'Confortável (Padrão Institucional)',
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Fuso Horário', 'Horário de Brasília (GMT-3)'),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            'Sincronização de Calendário Padrão',
            'Google Workspace for Education',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return Container(
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
            'Privacidade & Conformidade LGPD (Lei nº 13.709/2018)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DocenteColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Os dados pessoais coletados neste portal são utilizados exclusivamente para cumprimento de obrigações legais perante o Ministério da Educação (MEC) e gestão acadêmica da instituição. O tratamento de dados sensíveis e registros de presença segue rigorosamente as diretrizes da LGPD.',
            style: TextStyle(
              fontSize: 13,
              color: DocenteColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Relatório LGPD dos seus dados pessoais exportado com sucesso.',
                  ),
                  backgroundColor: DocenteColors.charcoal,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Exportar Meus Dados Pessoais (LGPD)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.charcoal,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DocenteColors.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: DocenteColors.slate),
          ),
        ),
      ],
    );
  }
}

